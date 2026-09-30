local function main()
  local sent = {}
  package.loaded['image/backends/kitty/helpers'] = {write_graphics=function(fields, path)
    sent[#sent+1] = {fields=fields,path=path}
  end}
  local p = require('sf_docs.placeholders')
  vim.o.termguicolors = true
  p.setup()
  assert(not vim.o.termguicolors, 'placeholders must use the palette')
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  local source = {'(** Unicode: ∀ n, n = n. *)', 'Check nat.'}
  vim.api.nvim_buf_set_lines(buf,0,-1,false,source)
  local img = p.from_file('/tmp/example.png',{buffer=buf,y=0,width=20,pixel_height=1200})
  img.sf_docs_replace_line=true
  img.sf_docs_prefetch_height=310 -- exercise more rows than the diacritic table
  img:render()
  local ns=vim.api.nvim_create_namespace('sf_docs_placeholders')
  local marks=vim.api.nvim_buf_get_extmarks(buf,ns,0,-1,{details=true})
  assert(#marks==1)
  assert(#marks[1][4].virt_lines==309 and marks[1][4].virt_text)
  assert(#sent==2, 'long previews must be tiled')
  for _,command in ipairs(sent) do
    assert(command.fields.display_virtual_placeholder==1, 'must never create a physical placement')
    local id=command.fields.image_id
    assert(id>0 and id % 16777216 >= 16 and id % 16777216 <= 255)
    local hl=vim.api.nvim_get_hl(0,{name='SFDocImage'..id,link=false})
    assert(hl.ctermfg==id % 256 and not hl.fg, 'must use exact palette index, never RGB')
  end
  -- Every cell must reconstruct the transmitted ID from its palette index and
  -- high-byte diacritic, including the second tile of a long comment.
  local codes=require('image/backends/kitty/codes')
  local rows={marks[1][4].virt_text}
  vim.list_extend(rows,marks[1][4].virt_lines)
  for row, chunks in ipairs(rows) do
    local tile=sent[math.floor((row-1)/#codes.diacritics)+1].fields
    local hl=vim.api.nvim_get_hl(0,{name=chunks[1][2],link=false})
    local high=math.floor(tile.image_id / 16777216)
    assert(hl.ctermfg + high * 16777216 == tile.image_id)
    assert(chunks[1][1]:find(codes.diacritics[high+1],1,true))
  end
  assert(vim.deep_equal(source,vim.api.nvim_buf_get_lines(buf,0,-1,false)))
  img:clear(true)
  assert(#sent==2 and #vim.api.nvim_buf_get_extmarks(buf,ns,0,-1,{})==1)
  img.sf_docs_paused=true; img.sf_docs_stale=true; img:render()
  assert(#sent==2, 'editing must not redraw')
  img.sf_docs_paused=false; img:render()
  assert(#sent==4 and #vim.api.nvim_buf_get_extmarks(buf,ns,0,-1,{})==0)
  assert(sent[3].fields.display_delete=='I' and sent[4].fields.display_delete=='I')
  -- More live images than foreground slots: high-byte diacritics must prevent
  -- aliasing when palette indices wrap, without overwriting another live image.
  local live, seen = {}, {}
  for _=1,300 do
    local item=p.from_file('/tmp/example.png',{buffer=buf,y=0,width=1,pixel_height=1})
    item.sf_docs_prefetch_height=1
    item:render()
    local id=sent[#sent].fields.image_id
    assert(not seen[id], 'palette wrap reused a live image ID')
    seen[id]=true
    live[#live+1]=item
  end
  for _,item in ipairs(live) do item:clear() end
  print('Placeholders: virtual text, tall image tiling, source preservation, editing freeze, cleanup passed')
end
local ok,err=xpcall(main,debug.traceback)
if not ok then io.stderr:write(err..'\n');vim.cmd('cquit 1') else vim.cmd('qa!') end
