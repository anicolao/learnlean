"""Persistent JSON-lines coqdoc -> HTML -> PDF -> PNG renderer.

Only disposable files are written, beneath one process-owned temporary directory.
The source is the *unsaved* documentation comment sent by Neovim.
"""
from __future__ import annotations

import hashlib
import json
import math
import re
from pathlib import Path
import subprocess
import sys
import tempfile

from PIL import Image
from weasyprint import HTML, CSS


CSS_BASE = """
html { background: transparent; }
body { margin: 0; padding: 14px 18px; font-family: 'DejaVu Sans', sans-serif;
       line-height: 1.5; overflow-wrap: anywhere; }
h1, h2, h3, h4 { line-height: 1.25; margin: .3em 0 .65em; }
h1 { font-size: 1.4em; } h2 { font-size: 1.25em; } h3, h4 { font-size: 1.1em; }
p { margin: .3em 0 .8em; }
a { text-decoration: none; }
pre, code, .inlinecode, .code { font-family: 'DejaVu Sans Mono', monospace; }

.code { white-space: pre-wrap; padding: 8px; }
ul, ol { padding-left: 1.7em; }
li { margin-bottom: .35em; }
img { max-width: 100%; }
.libtitle { display: none; }
"""


PALETTES = {
    'light': ('#202124', '#17675d', '#174ea6', '#754300'),
    'dark': ('#e4e9ef', '#83d5c5', '#a3c9ff', '#f1cc8f'),
}


class Renderer:
    def __init__(self, root: Path):
        self.root = root
        self.cache: dict[str, dict] = {}

    def render(self, request: dict) -> dict:
        source = request['source']
        width = max(160, min(4096, int(request.get('width', 800))))
        font_size = max(10, min(48, float(request.get('font_size', 18))))
        theme = request.get('theme', 'light')
        if theme not in PALETTES:
            raise ValueError('theme must be light or dark')
        base = str(Path(request.get('base', '.')).resolve())
        # Include the current file's printing directives, which coqdoc uses for symbols.
        preamble = request.get('preamble', '')
        key = hashlib.sha256(json.dumps([source, width, font_size, base, preamble, theme]).encode()).hexdigest()
        if key in self.cache:
            return dict(self.cache[key], cached=True)
        folder = self.root / key
        folder.mkdir()
        vfile = folder / 'Documentation.v'
        vfile.write_text(preamble + '\n' + source + '\n', encoding='utf-8')
        result = subprocess.run(
            ['coqdoc', '--html', '--body-only', '--no-index', '--no-glob', '--utf8', '--stdout', str(vfile)],
            capture_output=True, text=True, timeout=20, cwd=folder,
        )
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or 'coqdoc failed')
        # coqdoc surrounds comments with empty code regions, including <br/>.
        markup = re.sub(r'<div class="code">(?:\s|<br\s*/?>)*</div>', '', result.stdout)
        foreground, heading, link, code = PALETTES[theme]
        css = CSS_BASE + f'''
body {{ font-size: {font_size}px; color: {foreground}; }}
h1, h2, h3, h4 {{ color: {heading}; }}
a {{ color: {link}; }}
.inlinecode, .code {{ color: {code}; }}
'''
        # First lay out on a tall page; then trim the page to the content height.
        doc = HTML(string=markup, base_url=base)
        measure_css = CSS(string=css + f'\n@page {{ size: {width}px 30000px; margin: 0; }}')
        layout = doc.render(stylesheets=[measure_css])
        if len(layout.pages) != 1:
            raise ValueError('Documentation block is too tall to render; split it into smaller comments.')
        page = layout.pages[0]
        # WeasyPrint's layout boxes are intentionally isolated here and pinned by Nix.
        body = next((b for b in page._page_box.descendants() if b.element_tag == 'body'), None)
        height = max(36, math.ceil(body.position_y + body.margin_height()) if body else 36)
        css += f'\n@page {{ size: {width}px {height}px; margin: 0; }}'
        pdf = folder / 'preview.pdf'
        doc.write_pdf(pdf, stylesheets=[CSS(string=css)])
        prefix = folder / 'preview'
        subprocess.run(
            ['pdftocairo', '-png', '-transp', '-singlefile', '-r', '96', str(pdf), str(prefix)],
            check=True, capture_output=True, timeout=20,
        )
        png = prefix.with_suffix('.png')
        with Image.open(png) as image:
            pixel_width, pixel_height = image.size
        # The HTML is useful to regression-test that we use coqdoc's formatting.
        response = dict(path=str(png), width=pixel_width, height=pixel_height, html=markup, cached=False)
        self.cache[key] = response
        return response


def main():
    with tempfile.TemporaryDirectory(prefix='sf-docs-') as tmp:
        renderer = Renderer(Path(tmp))
        for line in sys.stdin:
            request = {}
            try:
                request = json.loads(line)
                response = renderer.render(request)
                response['id'] = request.get('id')
            except Exception as exc:
                response = dict(id=request.get('id'), error=str(exc))
            print(json.dumps(response), flush=True)


if __name__ == '__main__':
    main()
