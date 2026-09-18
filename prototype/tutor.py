"""Ephemeral Codex app-server bridge. The proof file is the only course storage."""
import difflib
import json
import os
from pathlib import Path
import queue
import signal
import subprocess
import sys
import tempfile
import threading
import time

SCHEMA = {
    'type': 'object', 'additionalProperties': False, 'required': ['edits'],
    'properties': {'edits': {'type': 'array', 'items': {
        'type': 'object', 'additionalProperties': False, 'required': ['old', 'new'],
        'properties': {'old': {'type': 'string'}, 'new': {'type': 'string'}},
    }}},
}


def apply_edits(source, response):
    if not isinstance(response, dict) or not isinstance(response.get('edits'), list):
        raise ValueError('Codex did not return an edit list')
    result, appended = source, False
    for edit in response['edits']:
        old, new = edit['old'], edit['new']
        if not isinstance(old, str) or not isinstance(new, str) or '\0' in new:
            raise ValueError('Invalid text edit')
        if not old:
            if appended:
                raise ValueError('Only one append is allowed')
            result += new
            appended = True
        else:
            if result.count(old) != 1:
                raise ValueError('An edit does not match exactly one location; file left unchanged')
            result = result.replace(old, new, 1)
    if result == source:
        raise ValueError('Codex returned no file changes')
    return result if result.endswith('\n') else result + '\n'


def context(source, baseline, request):
    message = {'language': request['language'], 'filename': Path(request['path']).name,
               'cursor_line': request.get('cursor', 1), 'prompt': request['prompt']}
    if baseline is None:
        message['full_file'] = source
        if request.get('example'):
            message['reference_example'] = request['example']
    else:
        message['diff_since_accepted_edits'] = ''.join(difflib.unified_diff(
            baseline.splitlines(keepends=True), source.splitlines(keepends=True),
            fromfile='previous', tofile='current'))
    return json.dumps(message, ensure_ascii=False)


class Codex:
    def __init__(self, cwd):
        self.proc = subprocess.Popen([os.environ['SF_CODEX_BIN'], 'app-server'],
                                     cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                     stderr=subprocess.DEVNULL, text=True, encoding='utf-8')
        self.events = queue.Queue()
        self.serial = 0
        self.deferred = []
        def read():
            try:
                for line in self.proc.stdout:
                    self.events.put(json.loads(line))
            finally:
                self.events.put(None)
        threading.Thread(target=read, daemon=True).start()
        try:
            self.rpc('initialize', {'clientInfo': {'name': 'learnlean', 'version': '0.1.0'},
                                    'capabilities': {'experimentalApi': True}})
            self.send({'method': 'initialized', 'params': {}})
        except BaseException:
            self.close()
            raise

    def send(self, message):
        self.proc.stdin.write(json.dumps(message, ensure_ascii=False) + '\n')
        self.proc.stdin.flush()

    def event(self, deadline, defer=False):
        if self.deferred and not defer:
            return self.deferred.pop(0)
        try:
            event = self.events.get(timeout=max(0, deadline - time.monotonic()))
        except queue.Empty:
            raise TimeoutError('Codex timed out; try TutorReset and send again')
        if event is None:
            raise RuntimeError('Codex app-server exited; check codex login status and CLI version')
        if 'method' in event and 'id' in event:
            # Teaching is returned as edits, so this client exposes no tool approvals.
            self.send({'id': event['id'], 'error': {'code': -32601, 'message': 'No tools in tutor mode'}})
        return event

    def rpc(self, method, params):
        self.serial += 1
        ident = self.serial
        self.send({'id': ident, 'method': method, 'params': params})
        deadline = time.monotonic() + 60
        while True:
            event = self.event(deadline, defer=True)
            if event.get('id') == ident and 'method' not in event:
                if 'error' in event:
                    raise RuntimeError(event['error'].get('message', str(event['error'])))
                return event['result']
            self.deferred.append(event)

    def start(self, cwd):
        params = {'cwd': cwd, 'ephemeral': True, 'sandbox': 'read-only',
                  'approvalPolicy': 'never',
                  'baseInstructions': Path(__file__).with_name('prompts').joinpath('tutor.md').read_text(),
                  'config': {'project_doc_max_bytes': 0}}
        if os.environ.get('SF_TUTOR_MODEL'):
            params['model'] = os.environ['SF_TUTOR_MODEL']
        return self.rpc('thread/start', params)['thread']['id']

    def turn(self, thread, text):
        self.rpc('turn/start', {'threadId': thread, 'input': [{'type': 'text', 'text': text}],
                                'outputSchema': SCHEMA})
        deadline = time.monotonic() + 600
        answer = None
        while True:
            event = self.event(deadline)
            params = event.get('params', {})
            if params.get('threadId') != thread:
                continue
            if event.get('method') == 'item/completed':
                item = params['item']
                if item['type'] == 'agentMessage':
                    answer = item['text']
            if event.get('method') == 'turn/completed':
                turn = params['turn']
                if turn['status'] != 'completed':
                    raise RuntimeError(str(turn.get('error') or turn['status']))
                if answer is None:
                    raise ValueError('Codex completed without file edits')
                return json.loads(answer)

    def close(self):
        if self.proc.poll() is None:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.kill()
                self.proc.wait()


def main():
    client = None
    def stop(*_):
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, stop)
    try:
        with tempfile.TemporaryDirectory(prefix='sf-tutor-') as tmp:
            if '--check' in sys.argv[1:]:
                client = Codex(tmp)
                print(json.dumps({'ready': True, 'codex': os.environ['SF_CODEX_BIN']}), flush=True)
                return
            thread, baseline, pending = None, None, None
            for line in sys.stdin:
                request = {}
                try:
                    request = json.loads(line)
                    if request.get('op') == 'commit':
                        if pending and request['id'] == pending[0]:
                            baseline = pending[1]
                            pending = None
                        continue
                    if pending:
                        raise RuntimeError('Previous edits were not acknowledged; reset the tutor')
                    if client is None:
                        client = Codex(tmp)
                    if thread is None:
                        thread = client.start(tmp)
                    source = request['source']
                    response = client.turn(thread, context(source, baseline, request))
                    updated = apply_edits(source, response)
                    pending = (request['id'], updated)
                    print(json.dumps({'id': request['id'], 'source': updated}, ensure_ascii=False), flush=True)
                except Exception as exc:
                    # Failed/unapplied turns cannot be used as a baseline for future diffs.
                    thread, baseline, pending = None, None, None
                    if client:
                        client.close()
                        client = None
                    print(json.dumps({'id': request.get('id'), 'error': str(exc)}), flush=True)
    finally:
        if client:
            client.close()


if __name__ == '__main__':
    main()
