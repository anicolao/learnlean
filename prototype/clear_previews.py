"""Explicit recovery for orphaned Kitty images, including tmux passthrough."""
import os


def clear_sequence(tmux):
    command = '\x1b_Ga=d,d=A,q=2\x1b\\'
    if tmux:
        command = '\x1bPtmux;' + command.replace('\x1b', '\x1b\x1b') + '\x1b\\'
    return command.encode('ascii')


if __name__ == '__main__':
    # /dev/tty targets the invoking terminal even if stdout is redirected.
    with open('/dev/tty', 'wb', buffering=0) as tty:
        tty.write(clear_sequence(bool(os.environ.get('TMUX'))))
