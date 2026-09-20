-- Exercise actual pinned backend code with terminal writes recorded in order.
local function main()
  local writes = {}
  local original_open = io.open
  io.open = function(path, mode)
    assert(path == '/dev/fd/1' or path == '/dev/test-pane', path)
    local pending = ''
    return {
      write = function(self, data) pending = pending .. data; return self end,
      flush = function(self) writes[#writes + 1] = pending; pending = ''; return true end,
      close = function() assert(pending == '', 'terminal writes must flush before close') end,
    }
  end
  local function escape(s) return '\27Ptmux;' .. s:gsub('\27', '\27\27') .. '\27\\' end
  package.loaded['image/utils'] = {
    tmux = { is_tmux = true, has_passthrough = true, escape = escape,
      get_pane_tty = function() return '/dev/test-pane' end },
    term = { get_tty = function() return '/dev/tty' end,
      get_size = function() return {cell_width=8,cell_height=16} end },
  }
  package.loaded['image/utils/logger'] = { within = function() return {debug=function() end} end }
  local helpers = require('image/backends/kitty/helpers')
  helpers.write_graphics({action='p',image_id=11})
  helpers.write_graphics({action='d',display_delete='I',image_id=11,tty='/dev/test-pane'})
  assert(#writes == 2, 'both commands must reach terminal synchronously')
  assert(writes[1]:find('a=p',1,true) and writes[2]:find('a=d',1,true), 'delete overtook draw')
  assert(writes[1]:sub(1,7) == '\27Ptmux;' and writes[2]:sub(1,7) == '\27Ptmux;')
  -- Track hidden images too: shallow hide retains data; final exit frees it by ID.
  local backend = require('image/backends/kitty')
  local state = {images={}, options={kitty_method='normal'}}
  backend.setup(state)
  local img = {id='owned',internal_id=123,cropped_path='/tmp/example.png',resize_hash='x',
    bounds={top=0,bottom=99,left=0,right=99}}
  backend.render(img,0,0,5,5)
  backend.clear(img.id,true)
  assert(not img.is_rendered)
  local before = #writes
  backend.clear()
  assert(#writes > before and writes[#writes]:find('i=123',1,true)
    and writes[#writes]:find('d=I',1,true), 'exit must free hidden owned image data')
  io.open = original_open
  print('Kitty: synchronous tmux draw/delete ordering and hidden-image exit cleanup passed')
end
local ok, err = xpcall(main, debug.traceback)
if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') else vim.cmd('qa!') end
