"""Exercise the packaged renderer as a long-running worker, without a GUI."""
import json
from pathlib import Path
import subprocess

from PIL import Image


def main():
    worker = subprocess.Popen(['sf-doc-render'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    def render(**request):
        worker.stdin.write(json.dumps(request) + '\n')
        worker.stdin.flush()
        return json.loads(worker.stdout.readline())
    try:
        a = render(id=1, source='(** * A heading\n\nText with _emphasis_ and [nat].\n\n- one\n- two\n*)', width=640)
        assert 'error' not in a, a
        assert '<h1' in a['html'] and '<i>emphasis</i>' in a['html'], a['html']
        assert 'nat' in a['html']
        assert '<div class="code">' not in a['html'], 'empty code regions add blank panels'
        with Image.open(a['path']) as image:
            assert image.width == 640 and 50 < image.height < 1500
            assert len(image.getcolors(image.width * image.height)) > 10
            assert image.mode == 'RGBA', 'preview must preserve transparency'
            assert image.getpixel((0, 0))[3] == 0, 'page background must be transparent'
            assert image.getchannel('A').getextrema() == (0, 255), 'text must remain visible'
        b = render(id=2, source='(** * A heading\n\nText with _emphasis_ and [nat].\n\n- one\n- two\n*)', width=640)
        assert b['cached'] and b['path'] == a['path']
        c = render(id=3, source='(** * Edited heading\n\nUpdated without saving. *)', width=400)
        assert 'error' not in c and c['path'] != a['path'], c
        assert c['width'] == 400 and 'Edited heading' in c['html']
        dark = render(id=6, source='(** * Edited heading\n\nUpdated without saving. *)', width=400, theme='dark')
        assert 'error' not in dark and dark['path'] != c['path'], dark
        with Image.open(c['path']) as light_image, Image.open(dark['path']) as dark_image:
            assert light_image.size == dark_image.size
            assert light_image.getchannel('A').tobytes() == dark_image.getchannel('A').tobytes()
            assert light_image.tobytes() != dark_image.tobytes(), 'theme changes must recolor text'
        bad = render(id=4, width='invalid', source='(** x *)')
        assert bad.get('error')
        good = render(id=5, source='(** Still works. *)')
        assert 'error' not in good, good
        path = Path(a['path'])
        worker.stdin.close()
        assert worker.wait(timeout=10) == 0
        assert not path.exists(), 'worker must clean its disposable render cache'
    finally:
        if worker.poll() is None:
            worker.terminate()
            worker.wait(timeout=10)
    print('Renderer: coqdoc formatting, pixels, unsaved updates, resize, errors, cache cleanup passed')


if __name__ == '__main__':
    main()
