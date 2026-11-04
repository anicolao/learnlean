"""Opt-in live Kitty check. Set SF_TEST_LEAN to the built lean-try executable.
Run with the flake's test-python interpreter; pass --tmux to test passthrough.
"""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

import pynvim


def wait_for(check, message):
    deadline = time.monotonic() + 45
    while time.monotonic() < deadline:
        if check():
            return
        time.sleep(.1)
    raise AssertionError(message)


def main():
    trial = os.environ['SF_TEST_LEAN']
    use_tmux = '--tmux' in sys.argv
    root = Path(__file__).resolve().parents[2]
    with tempfile.TemporaryDirectory(prefix='lean-previews-') as tmp:
        folder = Path(tmp)
        original = (root / 'lean-trial/Main.lean').read_text()
        (folder / 'Main.lean').write_text(original)
        shutil.copy(root / 'lean-trial/lakefile.toml', folder)
        sock = str(folder / 'nvim.sock')
        wire = folder / 'wire.bin'
        env = {k:v for k,v in os.environ.items() if k not in ('TMUX','TMUX_PANE','SF_DOC_TEST')}
        command = [trial, '--listen', sock, str(folder / 'Main.lean')]
        tmux = ['tmux', '-L', 'lean-preview-test-'+str(os.getpid())]
        if use_tmux:
            config = folder / 'tmux.conf'
            config.write_text('set -g allow-passthrough all\nset -g focus-events off\n')
            command = tmux + ['-f', str(config), 'new-session', '-s', 'test'] + command
        with (folder / 'kitty.log').open('w') as log:
            proc = subprocess.Popen(['kitty', '--dump-bytes='+str(wire), '-o', 'initial_window_width=1100',
                                     '-o', 'initial_window_height=800'] + command,
                                    env=env, cwd=folder, stdout=log, stderr=log)
            editor = None
            try:
                wait_for(lambda: Path(sock).exists(), 'Neovim did not start')
                editor = pynvim.attach('socket', path=sock)
                buf = editor.current.buffer.number
                def state():
                    return editor.exec_lua('''
                      local s=require('sf_docs').states[...]
                      local b=s and s.blocks[1]
                      return {rendered=b and b.image and b.image.is_rendered or false,
                        key=b and b.key, editing=require('sf_docs').editing}
                    ''', buf)
                wait_for(lambda: state()['rendered'], 'No Lean documentation preview')
                before = state()['key']
                assert editor.exec_lua("return require('lean.infoview').get_current_infoview() ~= nil")
                assert editor.exec_lua("return #vim.lsp.get_clients({name='leanls'}) > 0")
                assert not editor.options['termguicolors']
                editor.current.buffer = editor.buffers[buf]
                editor.current.window.cursor = (1, 0)
                editor.command('SFDocsOpen')
                editor.current.window.cursor = (2, 0)
                editor.input('IUpdated ')
                wait_for(lambda: state()['editing'], 'Insert mode did not pause previews')
                editor.input('\x1b')
                wait_for(lambda: state()['rendered'] and state()['key'] != before, 'Unsaved preview did not update')
                editor.command('SFDocsClose')
                assert '\U0010eeee' not in '\n'.join(editor.buffers[buf][:])
                assert (folder / 'Main.lean').read_text() == original
                print('Lean previews: graphics, Infoview, open/edit/close and unsaved refresh passed')
            finally:
                if editor:
                    try:
                        editor.command('qa!')
                    except EOFError:
                        pass
                if use_tmux:
                    subprocess.run(tmux + ['kill-server'], stderr=subprocess.DEVNULL)
                try:
                    proc.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    proc.terminate()
                    proc.wait(timeout=5)
        data = wire.read_bytes()
        commands = re.findall(rb'\x1b_G([^\x1b]*)\x1b\\', data)
        placements = [c for c in commands if b'a=T' in c or b'a=p' in c]
        assert placements and all(b'U=1' in c for c in placements)
        assert '\U0010eeee'.encode() in data
        print('Kitty received text placeholders and virtual-only placements', 'via tmux' if use_tmux else 'directly')


if __name__ == '__main__':
    main()
