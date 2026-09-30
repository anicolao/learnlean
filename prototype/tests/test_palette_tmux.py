"""Opt-in terminal integration test; requires a graphical desktop and Kitty."""
import os,subprocess,time,pathlib,shutil,pynvim,re
# Run with: nix develop --command python prototype/tests/test_palette_tmux.py
# Opens and closes its own Kitty window and isolated tmux server.
import tempfile
nvim=os.environ.get('SF_TEST_NVIM') or shutil.which('nvim')
workdir=tempfile.TemporaryDirectory(prefix='sf-palette-')
base=workdir.name+'/live'
pathlib.Path(base+'.conf').write_text('set -g allow-passthrough all\nset -g focus-events off\nset -g default-terminal tmux-256color\nset -g terminal-features "xterm-256color:256"\nset -as terminal-overrides ",*:RGB@:Tc@:setrgbf@:setrgbb@"\n')
pathlib.Path(base+'.v').write_text(''.join(f'(** Ordinary paragraph {i} with tall letters ÁÉ\n\nSome [nat] explanation with _emphasis_.\n*)\nCheck nat.\n\n' for i in range(40)))
env=dict(os.environ)
for key in ['TMUX','TMUX_PANE','SF_DOC_TEST']:env.pop(key,None)
tmux=[shutil.which('tmux'),'-L','sf-palette-'+str(os.getpid())]
p=subprocess.Popen(['kitty','-o','initial_window_width=1100','-o','initial_window_height=800','--dump-bytes='+base+'.wire','env','TERM=xterm-256color',*tmux,'-f',base+'.conf','new-session','-s','test',nvim,'-n','--listen',base+'.sock',base+'.v'],env=env,stdout=open(base+'.out','w'),stderr=open(base+'.err','w'),start_new_session=True)
for _ in range(150):
 if pathlib.Path(base+'.sock').exists():break
 time.sleep(.1)
v=None
try:
 v=pynvim.attach('socket',path=base+'.sock')
 for _ in range(300):
  result=v.exec_lua("local m=require('sf_docs');local n=0;for _,s in pairs(m.states) do for _,b in ipairs(s.blocks) do if b.image and b.image.is_rendered then n=n+1 end end end;return n")
  if result:break
  time.sleep(.1)
 assert result,v.exec_lua("local n=vim.notify;vim.notify=function() end;local h=require('sf_docs').health();vim.notify=n;return h")
 assert not v.options['termguicolors']
 print('terminal features',subprocess.check_output([*tmux,'list-clients','-F','#{client_termfeatures}']).decode().strip())
 capabilities=subprocess.check_output([*tmux,'info']).decode()
 print('RGB capabilities', '\n'.join(line for line in capabilities.splitlines() if 'RGB:' in line or 'setrgb' in line))
 assert re.search(r'RGB:.*\[missing\]',capabilities)
 assert re.search(r'setrgbf:.*\[missing\]',capabilities)
 diacritics=v.exec_lua("return require('image/backends/kitty/codes').diacritics")
 print('previews',result)
 print(v.exec_lua("local notify=vim.notify;vim.notify=function() end;local h=require('sf_docs').health();vim.notify=notify;return h"))
 for row in [70,150,1]:v.command(f'normal! {row}Gzt');time.sleep(.6)
 subprocess.run([*tmux,'new-window','-n','other'],check=True)
 time.sleep(.4)
 subprocess.run([*tmux,'select-window','-t','test:0'],check=True)
 subprocess.run([*tmux,'split-window','-h'],check=True)
 time.sleep(.5)
 subprocess.run([*tmux,'last-pane'],check=True)
 v.command('normal! 1Gzt');time.sleep(1)
 # Actual pane text contains the placeholder characters; a separate window does not.
 for _ in range(100):
  cells=subprocess.check_output([*tmux,'capture-pane','-e','-p','-t','test:0.0'])
  if '\U0010eeee'.encode() in cells:break
  time.sleep(.1)
 assert '\U0010eeee'.encode() in cells
 # Row zero shares the source anchor with the header concealment. A blank
 # header overlay used to erase its leftmost cells and clip paragraph tops.
 first_rows=[]
 for line in cells.decode('utf-8').splitlines():
  found=re.findall('\U0010eeee(.)(.)',line)
  if found:first_rows.append([(diacritics.index(r),diacritics.index(c)) for r,c in found])
 assert first_rows[0][0]==(0,0), 'First image row starts cropped'
 assert first_rows[1][0]==(1,0)
 assert [c for _,c in first_rows[0]]==[c for _,c in first_rows[1]], 'Header erased row-zero cells'
 other=subprocess.check_output([*tmux,'capture-pane','-p','-t','test:1.0'])
 assert '\U0010eeee'.encode() not in other
 original=v.current.buffer[:]
 v.command('normal! 1G')
 v.command('SFDocsOpen')
 time.sleep(.3)
 v.input('iUpdated ')
 time.sleep(.3)
 assert v.exec_lua('return require("sf_docs").editing')
 v.input('\x1b')
 time.sleep(.8)
 assert not v.exec_lua('return require("sf_docs").editing')
 v.command('undo')
 assert v.current.buffer[:]==original
 print('Pane isolation and insert/escape/undo source preservation passed')
finally:
 try:
  if v:v.command('qa!')
 except Exception:pass
 subprocess.run([*tmux,'kill-server'])
 p.wait(timeout=10)
data=pathlib.Path(base+'.wire').read_bytes()
cmds=re.findall(rb'\x1b_G([^\x1b]*)\x1b\\',data)
placements=[c for c in cmds if b'a=T' in c or b'a=p' in c]
assert placements and all(b'U=1' in c for c in placements)
assert '\U0010eeee'.encode() in data
print('Live tmux: Unicode cells and virtual-only placements; scrolling, window switching, pane split, exit passed')

# Decode exactly what Kitty received. Indexed foreground + third diacritic must
# reconstruct an uploaded image ID; RGB approximation would fail this check.
ids=set()
for command in placements:
 fields=dict(pair.split(b'=',1) for pair in command.split(b';',1)[0].split(b',') if b'=' in pair)
 ids.add(int(fields[b'i']))
text=data.decode('utf-8',errors='replace') + cells.decode('utf-8')
# Strip the graphics commands before scanning SGR/placeholder cells.
text=re.sub(r'\x1b_G.*?\x1b\\','',text,flags=re.S)
fg=None
matched=0
pattern=r'\x1b\[([0-9;:]*)m|\U0010eeee(['+re.escape(''.join(diacritics))+r']{1,3})'
for token in re.finditer(pattern,text):
 if token.group(1) is not None:
  values=[int(p) if p else 0 for p in token.group(1).replace(':',';').split(';')]
  i=0
  while i<len(values):
   value=values[i]
   if value in (38,48,58) and i+2<len(values) and values[i+1]==5:
    if value==38:fg=values[i+2]
    i+=3;continue
   assert not(value in (38,48,58) and i+1<len(values) and values[i+1]==2), 'RGB SGR reached terminal'
   if value in (0,39):fg=None
   if 30<=value<=37:fg=value-30
   if 90<=value<=97:fg=value-90+8
   i+=1
 else:
  assert fg is not None,'Placeholder has no indexed foreground'
  combining=token.group(2)
  if len(combining)<3:
   # tmux may extend a cell with a combining mark by rewriting it with BS.
   continue
  image_id=fg+diacritics.index(combining[2])*16777216
  assert image_id in ids, (image_id,sorted(ids))
  matched+=1
snapshot=cells.decode('utf-8')
complete=r'\U0010eeee['+re.escape(''.join(diacritics))+r']{3}'
assert len(re.findall(complete,snapshot))==snapshot.count('\U0010eeee')>0
assert matched>100,matched
print(f'Validated {matched} actual Kitty cells against uploaded image IDs, with no RGB SGR')

workdir.cleanup()
