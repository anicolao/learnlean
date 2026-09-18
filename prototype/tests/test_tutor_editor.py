"""Exercise the real editor/worker boundary offline with a deterministic tutor."""
import json
import os
from pathlib import Path
import sys
import tempfile
import time

import pynvim


def wait(predicate):
    for _ in range(150):
        if predicate():
            return
        time.sleep(.02)
    raise AssertionError('editor/worker timed out')


def main():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        worker = root / 'sf-tutor'
        worker.write_text(f'#!{sys.executable}\n' + '''import sys,json,time,os
for line in sys.stdin:
 r=json.loads(line)
 with open(os.environ['TUTOR_TEST_LOG'],'a') as f: f.write(line)
 if r.get('op')=='commit': continue
 time.sleep(.3)
 print(json.dumps({'id':r['id'],'source':r['source']+'\\n(** Tutor: Unicode α exercise. *)\\n'}),flush=True)
''')
        worker.chmod(0o755)
        file = root / 'course.v'
        file.write_text('Check nat.\n')
        os.environ['SF_DOC_TEST'] = '1'
        n = pynvim.attach('child', argv=['nvim', '--embed', '--headless', str(file)])
        try:
            n.exec_lua('vim.notify=function() end; vim.env.PATH=... .. ":" .. vim.env.PATH', str(root))
            n.exec_lua('vim.env.TUTOR_TEST_LOG=...', str(root / 'requests'))
            n.command('TutorAsk Teach me about α')
            wait(lambda: 'Tutor: Unicode' in file.read_text())
            wait(lambda: n.exec_lua('return require("sf_tutor").sessions[vim.api.nvim_get_current_buf()].pending == nil'))
            wait(lambda: '"commit"' in (root / 'requests').read_text())
            assert 'Learner question' in file.read_text() and 'Teach me about α' in file.read_text()
            assert file.read_text().startswith('Check nat.')
            n.command('undo')
            assert 'Tutor: Unicode' not in '\n'.join(n.current.buffer[:])
            assert 'Teach me about α' in '\n'.join(n.current.buffer[:]), 'reply must be one distinct undo change'
            n.command('write')
            n.command('TutorAsk Wait while I edit')
            n.current.buffer.append('Check bool.')
            time.sleep(.6)
            assert n.exec_lua('return require("sf_tutor").sessions[vim.api.nvim_get_current_buf()] == nil')
            assert n.current.buffer[-1] == 'Check bool.'
            assert 'Tutor: Unicode' not in '\n'.join(n.current.buffer[:])
            n.command('write')
            n.command('TutorAsk External change')
            file.write_text('(* external edit *)\n')
            time.sleep(.6)
            assert file.read_text() == '(* external edit *)\n'
            assert n.exec_lua('return require("sf_tutor").sessions[vim.api.nvim_get_current_buf()] == nil')
            n.command('edit!')
            n.command('TutorAsk Cancel this')
            n.command('TutorCancel')
            time.sleep(.4)
            assert 'Tutor: Unicode' not in file.read_text()
            # Lean uses native Lean comments, with no extra course files.
            lean = root / 'course.lean'
            n.command('edit ' + str(lean))
            n.command('TutorAsk Explain natural numbers')
            wait(lambda: lean.exists() and 'Tutor: Unicode' in lean.read_text())
            assert '/-! ## Learner question' in lean.read_text()
            requests = [json.loads(line) for line in (root / 'requests').read_text().splitlines()]
            assert any(r.get('language') == 'Lean 4' for r in requests)
        finally:
            try:
                n.command('qa!')
            except EOFError:
                pass
    print('Tutor editor: save, Unicode, undo, concurrent edits, disk conflicts, cancel, Lean routing passed')


if __name__ == '__main__':
    main()
