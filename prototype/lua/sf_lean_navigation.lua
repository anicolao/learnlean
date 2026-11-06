-- Lean checks asynchronously. This marks the inspected source position, not a
-- successfully checked prefix. Navigation deliberately operates on code lines.
local M = { ns = vim.api.nvim_create_namespace('sf_lean_position') }
local api = vim.api
local cache = {}
local function code(buf)
  local tick = api.nvim_buf_get_changedtick(buf)
  if not cache[buf] or cache[buf].tick ~= tick then
    local _, _, rows = require('sf_docs.lean_parser').scan(api.nvim_buf_get_lines(buf, 0, -1, false))
    cache[buf] = { tick = tick, rows = rows }
  end
  return cache[buf].rows
end

function M.mark()
  local buf = api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= 'lean' or vim.bo[buf].buftype ~= '' then return end
  api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then return end
  local row = api.nvim_win_get_cursor(0)[1]
  if code(buf)[row] then
    api.nvim_buf_set_extmark(buf, M.ns, row - 1, 0, {
      line_hl_group = 'SFLeanPosition', sign_text = '▶',
      sign_hl_group = 'SFLeanPosition', priority = 90,
    })
  end
end

function M.step(direction, count)
  local buf = api.nvim_get_current_buf()
  local rows = code(buf)
  local pos = api.nvim_win_get_cursor(0)
  for _ = 1, count or vim.v.count1 do
    local target
    if direction > 0 and rows[pos[1]] and pos[2] < rows[pos[1]].last + 1 then
      target = pos[1]
    else
      local row = pos[1] + direction
      while row >= 1 and row <= api.nvim_buf_line_count(buf) do
        if rows[row] then target = row; break end
        row = row + direction
      end
    end
    if not target then break end
    pos = { target, rows[target].last + 1 }
  end
  -- One-past-EOL is significant: it asks Lean for goals AFTER the tactic.
  if not vim.wo.virtualedit:find('all', 1, true) and not vim.wo.virtualedit:find('onemore', 1, true) then
    vim.wo.virtualedit = vim.wo.virtualedit == '' and 'onemore' or vim.wo.virtualedit .. ',onemore'
  end
  api.nvim_win_set_cursor(0, pos)
  if vim.fn.foldclosed(pos[1]) ~= -1 then vim.cmd('normal! zv') end
  local infoview = require('lean.infoview')
  infoview.open()
  local view = infoview.get_current_infoview()
  if view then view.info.pin:unpause() end
  -- Also refresh when already at the boundary, where CursorMoved won't fire.
  api.nvim_exec_autocmds('CursorMoved', { buffer = buf })
  M.mark()
end

function M.setup()
  local function colors()
    api.nvim_set_hl(0, 'SFLeanPosition', { default = true, link = 'DiffAdd' })
  end
  colors()
  local group = api.nvim_create_augroup('SFLeanNavigation', { clear = true })
  api.nvim_create_autocmd('ColorScheme', { group = group, callback = colors })
  api.nvim_create_autocmd('FileType', { group = group, pattern = 'lean', callback = function(a)
    for key, direction in pairs({ ['<M-Down>'] = 1, ['<M-Up>'] = -1,
        ['<leader>cj'] = 1, ['<leader>ck'] = -1 }) do
      vim.keymap.set('n', key, function() M.step(direction) end,
        { buffer = a.buf, desc = direction > 0 and 'Inspect after next Lean code line' or 'Inspect after previous Lean code line' })
    end
  end })
  api.nvim_create_autocmd({ 'CursorMoved', 'BufEnter', 'InsertLeave', 'TextChanged' },
    { group = group, callback = M.mark })
  api.nvim_create_autocmd('InsertEnter', { group = group, callback = function(a)
    api.nvim_buf_clear_namespace(a.buf, M.ns, 0, -1)
  end })
  api.nvim_create_autocmd('BufWipeout', { group = group, callback = function(a) cache[a.buf] = nil end })
end

return M
