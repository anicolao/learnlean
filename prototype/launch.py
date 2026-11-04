"""Select the pinned editor from startup filenames, preserving Neovim arguments."""
import os
from pathlib import Path
import sys

# Options whose next argument is not a filename to open.
VALUE_OPTIONS = {'-c', '--cmd', '-u', '-U', '-i', '-s', '-w', '-W', '-T', '-t',
                 '--listen', '--server', '--startuptime', '--log', '--remote-expr',
                 '--remote-send'}


def select_environment(args):
    languages = set()
    skip = False
    files_only = False
    for arg in args:
        if skip:
            skip = False
            continue
        if not files_only:
            if arg == '--':
                files_only = True
                continue
            if arg in VALUE_OPTIONS:
                skip = True
                continue
            if arg.startswith(('-', '+')):
                continue
        suffix = Path(arg).suffix
        if suffix == '.lean':
            languages.add('lean')
        elif suffix == '.v':
            languages.add('rocq')
    if len(languages) > 1:
        raise ValueError('Open .lean and .v files in separate editor sessions.')
    return next(iter(languages), 'rocq')


def main():
    try:
        language = select_environment(sys.argv[1:])
    except ValueError as exc:
        print(f'learnlean: {exc}', file=sys.stderr)
        return 2
    executable = {'lean': '@lean@', 'rocq': '@rocq@'}[language]
    os.execv(executable, [executable, *sys.argv[1:]])


if __name__ == '__main__':
    sys.exit(main())
