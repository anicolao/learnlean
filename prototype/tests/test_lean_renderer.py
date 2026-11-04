"""Exercise Lean Markdown without relying on a coqdoc installation."""
import json
import subprocess
from PIL import Image

worker = subprocess.Popen(['sf-doc-render'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
def render(source, **opts):
    worker.stdin.write(json.dumps(dict(source=source, language='lean', width=600, **opts))+'\n')
    worker.stdin.flush()
    result=json.loads(worker.stdout.readline())
    assert 'error' not in result, result
    return result
try:
    source='/-! # A lesson\n\nUse **conjunction** and `Nat`.\n\n- First\n- Second\n\n```lean\n#check Nat\n```\n-/ '
    source=source.rstrip()
    a=render(source)
    for fragment in ['<h1>A lesson</h1>', '<strong>conjunction</strong>', '<code>Nat</code>', '<ul>', 'language-lean']:
        assert fragment in a['html'], a['html']
    with Image.open(a['path']) as image:
        assert image.width==600 and image.height>100
        assert image.mode=='RGBA' and image.getchannel('A').getextrema()==(0,255)
    assert render(source)['cached']
    edited=render(source.replace('A lesson','New lesson'))
    assert edited['path']!=a['path'] and 'New lesson' in edited['html']
    paragraph=render('/-- Ordinary first line with ÁÉ and ∀. -/')
    with Image.open(paragraph['path']) as image:
        box=image.getchannel('A').getbbox()
        assert box and box[1]>0 and box[3]<image.height
    dark=render(source,theme='dark')
    with Image.open(a['path']) as light, Image.open(dark['path']) as dim:
        assert light.getchannel('A').tobytes()==dim.getchannel('A').tobytes()
    print('Lean renderer: Markdown, PNG pixels, themes, cache and unsaved updates passed')
finally:
    worker.stdin.close()
    worker.wait(timeout=10)
