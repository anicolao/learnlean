local M = { states = {} }
local api = vim.api
local parser = require('sf_docs.parser')
local ns = api.nvim_create_namespace('sf_docs_headers')
local anchors = api.nvim_create_namespace('sf_docs_anchors')
local image_api, worker, waiting, serial = nil, nil, nil, 0
local output_tail = ''
local cache = {}
local refresh_pending = false
local enabled = true
local image_error
local terminal_is_kitty

local function clear_image(block)
  if block.image then
    block.image.sf_docs_stale = true
    pcall(function() block.image:clear() end)
    block.image = nil
  end
end
local function clear_images(state)
  for _, b in ipairs(state.blocks) do clear_image(b) end
end
local function source_window(buf)
  local current = api.nvim_get_current_win()
  if api.nvim_win_get_buf(current) == buf then return current end
  local wins = vim.fn.win_findbuf(buf)
  return wins[1]
end

function M.foldexpr(line)
  local state = M.states[api.nvim_get_current_buf()]
  return state and state.folds[line] or 0
end
function M.foldtext()
  return ('  documentation source · %d lines'):format(vim.v.foldend - vim.v.foldstart + 1)
end

local function schedule_refresh()
  if refresh_pending then return end
  refresh_pending = true
  vim.defer_fn(function()
    refresh_pending = false
    if enabled then M.refresh() end
  end, 40)
end

local function start_worker()
  if worker then return end
  output_tail = ''
  worker = vim.fn.jobstart({ 'sf-doc-render' }, {
    on_stdout = function(_, data)
      if not data then return end
      local chunks = vim.split(output_tail .. table.concat(data, '\n'), '\n', { plain = true })
      output_tail = table.remove(chunks) or ''
      for _, line in ipairs(chunks) do
        if line ~= '' then
          local ok, response = pcall(vim.json.decode, line)
          if ok and waiting and response.id == waiting.id then
            local job = waiting; waiting = nil
            if response.error then
              image_error = response.error
              cache[job.key] = { error = response.error }
              vim.notify('Documentation preview: ' .. response.error, vim.log.levels.WARN)
            else
              cache[job.key] = response
            end
            schedule_refresh()
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then M.last_renderer_stderr = table.concat(data, '\n') end
    end,
    on_exit = function()
      worker, waiting = nil, nil
      -- Every image path belonged to this worker's temporary directory.
      cache = {}
      for _, state in pairs(M.states) do clear_images(state) end
    end,
  })
  if worker <= 0 then worker = nil; image_error = 'Unable to start sf-doc-render' end
end

local function graphics_ready()
  if image_api then return true end
  if #api.nvim_list_uis() == 0 or vim.env.SF_DOC_TEST == '1' then return false end
  if terminal_is_kitty == nil then
    terminal_is_kitty = vim.env.KITTY_WINDOW_ID ~= nil or vim.env.TERM == 'xterm-kitty'
      or vim.env.TERM_PROGRAM == 'kitty'
    -- Long-lived tmux servers may not retain Kitty's environment variables.
    if not terminal_is_kitty and vim.env.TMUX and vim.fn.executable('tmux') == 1 then
      local term = vim.fn.system({ 'tmux', 'display-message', '-p', '#{client_termname}' })
      terminal_is_kitty = vim.v.shell_error == 0 and vim.trim(term) == 'xterm-kitty'
    end
  end
  if not terminal_is_kitty then return false end
  local ok, result = pcall(function()
    local img = require('image')
    img.setup({
      backend = 'kitty', processor = 'magick_cli',
      integrations = { markdown = { enabled = false }, neorg = { enabled = false } },
      max_width = nil, max_height = nil,
      max_width_window_percentage = 100, max_height_window_percentage = 100000,
      window_overlap_clear_enabled = true,
      editor_only_render_when_focused = true,
      tmux_show_only_in_active_window = true,
    })
    return img
  end)
  if not ok then image_error = tostring(result); return false end
  image_api = result
  return true
end

local function snapshot_open(state, win)
  if not win or state.compact then return end
  api.nvim_win_call(win, function()
    for _, b in ipairs(state.blocks) do
      if b.standalone and b.last > b.first then
        b.open = vim.fn.foldclosed(b.first + 1) == -1
      end
    end
  end)
end

local function rebuild(buf)
  local state = M.states[buf]
  if not enabled or not state or not api.nvim_buf_is_valid(buf) then return end
  local old_at, old_source = {}, {}
  for _, b in ipairs(state.blocks) do
    local pos = b.anchor and api.nvim_buf_get_extmark_by_id(buf, anchors, b.anchor, {}) or {}
    if #pos > 0 then old_at[pos[1] + 1] = b end
    old_source[b.source] = b
  end
  clear_images(state)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  api.nvim_buf_clear_namespace(buf, anchors, 0, -1)
  state.compact = graphics_ready()
  state.blocks, state.separators = parser.scan(api.nvim_buf_get_lines(buf, 0, -1, false))
  state.folds, state.preamble = {}, ''
  for _, b in ipairs(state.blocks) do
    local old = old_at[b.first] or old_source[b.source]
    b.open = not b.standalone or (old and old.open) or false
    b.anchor = api.nvim_buf_set_extmark(buf, anchors, b.first - 1, 0, { right_gravity = false })
    if b.directive then state.preamble = state.preamble .. b.source .. '\n' end
    if b.standalone and b.last > b.first then
      for line = b.first + 1, b.last do state.folds[line] = 1 end
      state.folds[b.first + 1] = '>1'
    end
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    api.nvim_win_call(win, function()
      vim.wo.foldenable = not state.compact
      if state.compact then
        vim.wo.conceallevel = 2
        vim.wo.concealcursor = 'nvic'
      end
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'v:lua.SFDocsFoldExpr(v:lnum)'
      vim.wo.foldtext = 'v:lua.SFDocsFoldText()'
      vim.wo.foldminlines = 0
      vim.wo.foldlevel = 0
      -- Recompute without zx's implicit "open the cursor's fold".
      vim.cmd('silent! normal! zX')
      vim.wo.foldenable = not state.compact
      for _, b in ipairs(state.blocks) do
        if b.open and b.last > b.first and b.standalone and not state.compact then
          vim.cmd(('silent! %dfoldopen'):format(b.first + 1))
        end
      end
    end)
  end
  state.dirty = false
  state.tick = api.nvim_buf_get_changedtick(buf)
  schedule_refresh()
end

local function paint_headers(buf, state)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if state.compact and not state.show_separators then
    for _, separator in ipairs(state.separators or {}) do
      api.nvim_buf_set_extmark(buf, ns, separator.first - 1, 0, {
        end_row = separator.last - 1,
        end_col = #api.nvim_buf_get_lines(buf, separator.last - 1, separator.last, false)[1],
        conceal_lines = '',
      })
    end
  end
  for _, b in ipairs(state.blocks) do
    if not b.open and b.standalone then
      if state.compact and b.last > b.first then
        api.nvim_buf_set_extmark(buf, ns, b.first, 0, {
          end_row = b.last - 1, end_col = #api.nvim_buf_get_lines(buf, b.last - 1, b.last, false)[1],
          conceal_lines = '',
        })
      end
      local label = state.compact and b.image and '' or ('▸ ' .. b.title .. '  [zo: edit]')
      if not image_api then label = label .. '  [preview: Kitty required]' end
      local raw = api.nvim_buf_get_lines(buf, b.first - 1, b.first, false)[1] or ''
      label = label .. string.rep(' ', math.max(0, vim.fn.strdisplaywidth(raw) - vim.fn.strdisplaywidth(label)))
      api.nvim_buf_set_extmark(buf, ns, b.first - 1, 0, {
        virt_text = { { label, 'Title' } }, virt_text_pos = 'overlay', hl_mode = 'replace',
        sign_text = state.compact and '▸' or nil, sign_hl_group = 'Title',
        end_row = b.first - 1, end_col = #raw,
        conceal = state.compact and b.image and '' or nil,
      })
    elseif b.open and state.compact and b.standalone then
      api.nvim_buf_set_extmark(buf, ns, b.first - 1, 0, { sign_text = '▾', sign_hl_group = 'Title' })
    end
  end
end

-- Include complete comments beginning within ~1,000 source characters below view.
function M.lookahead_end(buf, bottom)
  local last = api.nvim_buf_line_count(buf)
  local row, remaining = math.min(bottom, last), 1000
  while row < last and remaining > 0 do
    local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    remaining = remaining - vim.fn.strchars(line) - 1
    row = row + 1
  end
  return row
end

function M.refresh()
  if not enabled then return end
  local graphical = graphics_ready()
  for buf, state in pairs(M.states) do
    local win = source_window(buf)
    if win and api.nvim_buf_is_valid(buf) and not state.dirty then
      snapshot_open(state, win)
      paint_headers(buf, state)
      if graphical then
        local info = vim.fn.getwininfo(win)[1]
        local size = require('image.utils.term').get_size()
        if size and size.cell_width > 0 and size.cell_height > 0 then
          local columns = math.max(1, math.floor(math.max(20, info.width - info.textoff - 2) * 0.9))
          local pixels = math.floor(columns * size.cell_width)
          local lookahead = M.lookahead_end(buf, info.botline)
          for _, b in ipairs(state.blocks) do
            local row = b.open and b.last or b.first
            local visible = not b.directive and row >= info.topline - 1 and row <= info.botline
            local nearby = not b.directive and b.first > info.botline and b.first <= lookahead
            if not visible and not nearby then
              -- Keep padding when scrolled away so the document does not jump.
              if b.image then b.image:clear(true) end
            else
              local key = vim.fn.sha256(vim.json.encode({b.source, pixels, size.cell_height, state.preamble, vim.o.background}))
              if b.key ~= key or b.win ~= win or b.row ~= row then
                clear_image(b); b.key, b.win, b.row = key, win, row
              end
              local result = cache[key]
              if result and not result.error then
                if not b.image then
                  local ok, img = pcall(image_api.from_file, result.path, {
                    id = ('sf-doc-%d-%d'):format(buf, b.anchor), window = win, buffer = buf,
                    x = 0, y = row - 1, width = columns,
                    with_virtual_padding = true, inline = true,
                  })
                  if ok then
                    img.sf_docs_replace_line = state.compact and not b.open and b.standalone
                    -- Allocate offscreen space before scrolling reaches this image.
                    img.sf_docs_prefetch_height = math.ceil(columns * size.cell_width * result.height / result.width / size.cell_height)
                    b.image = img
                  else image_error = tostring(img) end
                end
                if b.image then
                  local ok, err = pcall(function() b.image:render() end)
                  if not ok then image_error = tostring(err) end
                end
              elseif not result and not waiting then
                start_worker()
                if worker then
                  serial = serial + 1; waiting = { id = serial, key = key }
                  vim.fn.chansend(worker, vim.json.encode({
                    id = serial, source = b.source, width = pixels, theme = vim.o.background,
                    font_size = math.max(12, size.cell_height * 0.9),
                    base = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ':h'), preamble = state.preamble,
                  }) .. '\n')
                end
              end
            end
          end
        end
      end
      paint_headers(buf, state)
    else
      clear_images(state)
    end
  end
end

local function block_at_cursor()
  local buf = api.nvim_get_current_buf()
  local state = M.states[buf]
  if not state then return end
  local line = api.nvim_win_get_cursor(0)[1]
  for _, b in ipairs(state.blocks) do
    if line >= b.first and line <= b.last then return b, state, buf end
  end
end

function M.toggle(mode)
  local b, state, buf = block_at_cursor()
  if not b then
    vim.cmd('normal! ' .. (({ open = 'zo', close = 'zc' })[mode or ''] or 'za'))
    return
  end
  if not b.standalone then return end
  local open = mode == 'open' or (mode ~= 'close' and not b.open)
  clear_image(b)
  b.open = open
  if b.last > b.first and not state.compact then
    vim.cmd(('silent! %dfold%s'):format(b.first + 1, open and 'open' or 'close'))
  end
  paint_headers(buf, M.states[buf])
  schedule_refresh()
end

function M.all(open)
  local state = M.states[api.nvim_get_current_buf()]
  if not state then return end
  state.show_separators = open
  for _, b in ipairs(state.blocks) do clear_image(b); b.open = open or not b.standalone end
  if not state.compact then vim.cmd('silent! normal! ' .. (open and 'zR' or 'zM')) end
  schedule_refresh()
end

function M.attach(buf)
  if not enabled or M.states[buf] or vim.bo[buf].buftype ~= '' then return end
  local state = { blocks = {}, folds = {}, tick = 0 }
  M.states[buf] = state
  local timer = vim.uv.new_timer()
  state.timer = timer
  api.nvim_buf_attach(buf, false, {
    on_lines = function()
      state.dirty = true
      -- Invalidate synchronously: BufWritePost can render before scheduled cleanup.
      -- Only set flags here; on_lines runs with textlock held.
      for _, b in ipairs(state.blocks) do
        if b.image then b.image.sf_docs_stale = true end
      end
      timer:stop()
      timer:start(250, 0, vim.schedule_wrap(function() rebuild(buf) end))
      -- Do not let an old rendered image masquerade as current while typing.
      vim.schedule(function() clear_images(state) end)
    end,
    on_detach = function()
      timer:stop(); timer:close(); clear_images(state); M.states[buf] = nil
    end,
  })
  for lhs, mode in pairs({ za = 'toggle', zo = 'open', zc = 'close' }) do
    vim.keymap.set('n', lhs, function() M.toggle(mode) end, { buffer = buf, desc = 'Documentation: ' .. mode })
  end
  vim.keymap.set('n', 'zR', function() M.all(true) end, { buffer = buf })
  vim.keymap.set('n', 'zM', function() M.all(false) end, { buffer = buf })
  vim.keymap.set('n', '<LeftMouse>', function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid ~= 0 and api.nvim_win_get_buf(mouse.winid) == buf then
      local info = vim.fn.getwininfo(mouse.winid)[1]
      if mouse.wincol <= info.textoff then
        for _, b in ipairs(state.blocks) do
          if mouse.line == b.first then
            vim.schedule(function()
              api.nvim_set_current_win(mouse.winid)
              api.nvim_win_set_cursor(mouse.winid, { b.first, 0 })
              M.toggle()
            end)
            return ''
          end
        end
      end
    end
    return '<LeftMouse>'
  end, { buffer = buf, expr = true, desc = 'Toggle documentation from gutter' })
  rebuild(buf)
end

function M.health()
  local result = {
    graphics = image_api ~= nil, kitty = vim.env.KITTY_WINDOW_ID ~= nil,
    worker = worker, pending = waiting, error = image_error,
    renderer = vim.fn.exepath('sf-doc-render'),
  }
  vim.notify(vim.inspect(result))
  return result
end

function M.setup()
  _G.SFDocsFoldExpr = M.foldexpr
  _G.SFDocsFoldText = M.foldtext
  api.nvim_create_autocmd('FileType', { pattern = 'coq', callback = function(a) M.attach(a.buf) end })
  api.nvim_create_autocmd({ 'WinScrolled', 'WinResized', 'BufWinEnter', 'CursorMoved', 'InsertLeave' }, {
    callback = schedule_refresh,
  })
  api.nvim_create_autocmd('InsertEnter', { callback = function()
    local b, state = block_at_cursor()
    if b and state.compact and not b.open then M.toggle('open') end
  end })
  api.nvim_create_autocmd('OptionSet', { pattern = 'background', callback = schedule_refresh })
  api.nvim_create_autocmd('ColorScheme', { callback = schedule_refresh })
  api.nvim_create_autocmd('VimLeavePre', { callback = function()
    for _, s in pairs(M.states) do clear_images(s) end
    if worker then pcall(vim.fn.chanclose, worker, 'stdin') end
  end })
  api.nvim_create_user_command('SFDocsOpen', function() M.toggle('open') end, {})
  api.nvim_create_user_command('SFDocsClose', function() M.toggle('close') end, {})
  api.nvim_create_user_command('SFDocsToggle', function() M.toggle() end, {})
  api.nvim_create_user_command('SFDocsRefresh', function()
    image_error = nil
    for buf in pairs(M.states) do rebuild(buf) end
    cache = {}; schedule_refresh()
  end, {})
  api.nvim_create_user_command('SFDocsHealth', M.health, {})
  api.nvim_create_user_command('SFDocsEnable', function()
    enabled = true
    for buf in pairs(M.states) do
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do vim.wo[win].foldenable = true end
      rebuild(buf)
    end
  end, {})
  api.nvim_create_user_command('SFDocsDisable', function()
    enabled = false
    for buf, s in pairs(M.states) do
      clear_images(s); api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do vim.wo[win].foldenable = false end
    end
  end, {})
end
M.rebuild = rebuild
return M
