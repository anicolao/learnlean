-- Kitty owns image data; Neovim and tmux own every visible image cell.
-- Never emit cursor-positioned graphics or text outside Neovim's redraw loop.
local M = { mode = 'placeholders' }
local api = vim.api
local ns = api.nvim_create_namespace('sf_docs_placeholders')
local codes = require('image/backends/kitty/codes')
local images = {}
-- Indexed foregrounds carry only the low byte; the third combining character
-- carries bits 24..31. Bits 8..23 must be zero, not a quantized RGB value.
-- Skip ANSI slots 0..15 so bold/bright-color remapping cannot change the ID.
local slots = 240 * 256
local serial = tonumber(vim.fn.sha256(tostring(vim.uv.hrtime()) .. ':' .. vim.fn.getpid()):sub(1, 8), 16) % slots
local allocated = {}
local function next_id()
  for _ = 1, slots do
    serial = (serial + 1) % slots
    local id = math.floor(serial / 240) * 16777216 + 16 + serial % 240
    if not allocated[id] then allocated[id] = true; return id end
  end
  error('Kitty palette preview IDs exhausted')
end
local function highlight(tile)
  api.nvim_set_hl(0, tile.hl, {ctermfg=tile.id % 256, nocombine=true})
end
local function send(fields, path)
  require('image/backends/kitty/helpers').write_graphics(fields, path)
end

function M.setup()
  -- Preserve the terminal palette used by the course's syntax/proof theme.
  vim.o.termguicolors = false
  api.nvim_create_autocmd('VimLeavePre', { callback = function()
    for img in pairs(images) do img:clear() end
  end })
end

function M.from_file(path, opts)
  local img = { buffer = opts.buffer, geometry = { y = opts.y }, tiles = {}, is_rendered = false }
  function img:clear(shallow)
    -- Offscreen text needs no cleanup: tmux/Neovim hide it themselves.
    if shallow then return end
    if self.mark and api.nvim_buf_is_valid(self.buffer) then
      api.nvim_buf_del_extmark(self.buffer, ns, self.mark)
    end
    self.mark = nil
    for _, tile in ipairs(self.tiles) do
      send({action='d', display_delete='I', image_id=tile.id, quiet=2})
      api.nvim_set_hl(0, tile.hl, {})
      allocated[tile.id] = nil
    end
    self.tiles = {}
    self.is_rendered = false
    images[self] = nil
  end
  function img:render()
    if self.sf_docs_paused then return end
    if self.sf_docs_stale or not api.nvim_buf_is_valid(self.buffer)
      or self.geometry.y >= api.nvim_buf_line_count(self.buffer) then self:clear(); return end
    if self.is_rendered then
      for _, tile in ipairs(self.tiles) do highlight(tile) end
      return
    end
    local height = self.sf_docs_prefetch_height
    local width = opts.width
    local rows = {}
    -- Tile tall comments so row/column diacritics never exceed the protocol table.
    local limit = #codes.diacritics
    assert(width <= limit, 'preview is wider than Kitty placeholder coordinate table')
    for start = 0, height - 1, limit do
      local count = math.min(limit, height - start)
      local id = next_id()
      local hl = 'SFDocImage' .. id
      local tile = { id=id, hl=hl }
      self.tiles[#self.tiles + 1] = tile
      images[self] = true
      highlight(tile)
      local top = math.floor(start * opts.pixel_height / height)
      local bottom = math.floor((start + count) * opts.pixel_height / height)
      send({action='T', transmit_format=100, transmit_medium='f', image_id=id,
        display_virtual_placeholder=1, display_columns=width, display_rows=count,
        display_y=top, display_height=bottom-top, display_cursor_policy=1, quiet=2}, path)
      local high = codes.diacritics[math.floor(id / 16777216) + 1]
      for row = 1, count do
        local cells = {}
        for col = 1, width do
          cells[col] = codes.placeholder .. codes.diacritics[row] .. codes.diacritics[col] .. high
        end
        rows[#rows + 1] = {{table.concat(cells), hl}}
      end
    end
    local first = self.sf_docs_replace_line and table.remove(rows, 1) or nil
    self.mark = api.nvim_buf_set_extmark(self.buffer, ns, self.geometry.y, 0, {
      virt_text=first, virt_text_pos='overlay', hl_mode='replace', priority=200,
      virt_lines=rows, right_gravity=false,
    })
    self.is_rendered = true
  end
  return img
end
return M
