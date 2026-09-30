local function main()
  local sent = {}
  package.loaded['image/backends/kitty/helpers'] = {write_graphics=function(fields, path)
    sent[#sent+1] = {fields=fields,path=path}
  end}
  local p = require('sf_docs.placeholders')
  p.setup()
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
    assert(command.fields.image_id>0)
  end
  assert(vim.deep_equal(source,vim.api.nvim_buf_get_lines(buf,0,-1,false)))
  img:clear(true)
  assert(#sent==2 and #vim.api.nvim_buf_get_extmarks(buf,ns,0,-1,{})==1)
  img.sf_docs_paused=true; img.sf_docs_stale=true; img:render()
  assert(#sent==2, 'editing must not redraw')
  img.sf_docs_paused=false; img:render()
  assert(#sent==4 and #vim.api.nvim_buf_get_extmarks(buf,ns,0,-1,{})==0)
  assert(sent[3].fields.display_delete=='I' and sent[4].fields.display_delete=='I')
  print('Placeholders: virtual text, tall image tiling, source preservation, editing freeze, cleanup passed')
end
local ok,err=xpcall(main,debug.traceback)
if not ok then io.stderr:write(err..'\n');vim.cmd('cquit 1') else vim.cmd('qa!') end
