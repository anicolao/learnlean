local M = { sessions = {} }
local api = vim.api
local serial = 0
local function notify(text, level) vim.notify('Tutor: ' .. text, level) end
local function text(buf) return table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), '\n') .. '\n' end
local function disk_text(path)
  local file = io.open(path, 'rb')
  if not file then return nil end
  local content = file:read('*a'); file:close(); return content
end
local function save(buf)
  local ok, err = pcall(api.nvim_buf_call, buf, function() vim.cmd('silent update') end)
  if not ok then
    -- BufWritePost can fail after a successful disk write. Verify content before
    -- reporting failure or acknowledging a tutor reply as the next diff baseline.
    local read_ok, disk_lines = pcall(vim.fn.readfile, api.nvim_buf_get_name(buf))
    if read_ok and not vim.bo[buf].modified
        and vim.deep_equal(disk_lines, api.nvim_buf_get_lines(buf, 0, -1, false)) then
      return true, err
    end
  end
  return ok, err
end
function M.reset(buf)
  buf = buf or api.nvim_get_current_buf()
  local s = M.sessions[buf]
  M.sessions[buf] = nil
  if s and s.job then vim.fn.jobstop(s.job) end
end
local function response(buf, s, result)
  if M.sessions[buf] ~= s or not s.pending or result.id ~= s.pending.id then return end
  local pending = s.pending
  s.pending = nil
  if result.error then notify(result.error, vim.log.levels.ERROR); return end
  if not api.nvim_buf_is_valid(buf) or api.nvim_buf_get_changedtick(buf) ~= pending.tick
      or api.nvim_buf_get_name(buf) ~= pending.path then
    M.reset(buf)
    notify('File changed while thinking; reply discarded. Send again to use your current work.', vim.log.levels.WARN)
    return
  end
  if type(result.source) ~= 'string' then M.reset(buf); notify('Invalid reply', vim.log.levels.ERROR); return end
  if disk_text(pending.path) ~= pending.disk then
    M.reset(buf); notify('File changed on disk; reply discarded.', vim.log.levels.WARN); return
  end
  local lines = vim.split(result.source, '\n', { plain = true })
  if lines[#lines] == '' then table.remove(lines) end
  -- One buffer change means the whole tutor response is undoable with u.
  local ok, err = pcall(api.nvim_buf_set_lines, buf, 0, -1, false, lines)
  if not ok then M.reset(buf); notify(tostring(err), vim.log.levels.ERROR); return end
  local saved, save_error = save(buf)
  if not saved then
    M.reset(buf); notify('Reply is in the buffer but could not be saved: ' .. tostring(save_error), vim.log.levels.ERROR)
    return
  end
  vim.fn.chansend(s.job, vim.json.encode({ op = 'commit', id = result.id }) .. '\n')
  if save_error then
    notify('Course saved, but a post-save hook failed: ' .. tostring(save_error), vim.log.levels.WARN)
  else
    notify('Updated and saved the course. Use u to undo, then :write to save the undo.')
  end
end
local function session(buf)
  if M.sessions[buf] then return M.sessions[buf] end
  local s = { tail = '', stderr = '' }
  M.sessions[buf] = s
  s.job = vim.fn.jobstart({ 'sf-tutor' }, {
    on_stdout = function(_, data)
      local chunks = vim.split(s.tail .. table.concat(data, '\n'), '\n', { plain = true })
      s.tail = table.remove(chunks) or ''
      for _, line in ipairs(chunks) do
        if line ~= '' then
          local ok, result = pcall(vim.json.decode, line)
          if ok then response(buf, s, result)
          else M.reset(buf); notify('Invalid worker output', vim.log.levels.ERROR) end
        end
      end
    end,
    on_stderr = function(_, data) s.stderr = (s.stderr .. table.concat(data, '\n')):sub(-2000) end,
    on_exit = function(_, code)
      if M.sessions[buf] == s then
        M.sessions[buf] = nil
        if s.pending then notify('Worker exited (' .. code .. '): ' .. s.stderr, vim.log.levels.ERROR) end
      end
    end,
  })
  if s.job <= 0 then M.sessions[buf] = nil; error('Unable to start sf-tutor') end
  return s
end
function M.ask(prompt)
  if not prompt or vim.trim(prompt) == '' then return end
  local buf = api.nvim_get_current_buf()
  local path = api.nvim_buf_get_name(buf)
  local ext = vim.fn.fnamemodify(path, ':e')
  if path == '' or (ext ~= 'v' and ext ~= 'lean') or vim.bo[buf].buftype ~= '' then
    notify('Open a named .v or .lean course file first.', vim.log.levels.ERROR); return
  end
  if vim.bo[buf].readonly or not vim.bo[buf].modifiable then
    notify('The course file must be writable.', vim.log.levels.ERROR); return
  end
  local old = M.sessions[buf]
  if old and old.pending then notify('Still thinking. Use :TutorCancel to stop.'); return end
  local cursor = api.nvim_win_get_cursor(0)[1]
  -- Persist the learner's question as readable course content, not sidecar metadata.
  local question = prompt:gsub('%(%*', '( *'):gsub('%*%)', '* )'):gsub('/%-', '/ -'):gsub('%-/', '- /')
  local note = ext == 'v' and ('\n(** ** Learner question\n\n' .. question .. '\n*)')
    or ('\n/-! ## Learner question\n\n' .. question .. '\n-/')
  api.nvim_buf_set_lines(buf, -1, -1, false, vim.split(note, '\n', { plain = true }))
  local saved, err = save(buf)
  if not saved then notify('Could not save the question: ' .. tostring(err), vim.log.levels.ERROR); return end
  local s = session(buf)
  serial = serial + 1
  s.pending = { id = serial, tick = api.nvim_buf_get_changedtick(buf), path = path, disk = disk_text(path) }
  local example
  if vim.g.sf_tutor_example then
    local ok, content = pcall(vim.fn.readfile, vim.fn.expand(vim.g.sf_tutor_example))
    if not ok then M.reset(buf); notify('Cannot read the example file', vim.log.levels.ERROR); return end
    example = table.concat(content, '\n')
  end
  vim.fn.chansend(s.job, vim.json.encode({ id = serial, path = path, source = text(buf),
    language = ext == 'v' and 'Rocq' or 'Lean 4', prompt = prompt, cursor = cursor, example = example }) .. '\n')
  notify('Thinking… You can keep reading; editing cancels application of this reply.')
end
function M.setup()
  api.nvim_create_user_command('TutorAsk', function(args)
    if args.args ~= '' then M.ask(args.args)
    else vim.ui.input({ prompt = 'Ask the tutor: ' }, M.ask) end
  end, { nargs = '*' })
  api.nvim_create_user_command('TutorCancel', function() M.reset(); notify('Cancelled.') end, {})
  api.nvim_create_user_command('TutorReset', function() M.reset(); notify('Next question will send the full current file.') end, {})
  api.nvim_create_autocmd('BufWipeout', { callback = function(a) M.reset(a.buf) end })
  api.nvim_create_autocmd('VimLeavePre', { callback = function()
    for buf in pairs(M.sessions) do M.reset(buf) end
  end })
  api.nvim_create_autocmd('FileType', { pattern = { 'coq', 'lean' }, callback = function(a)
    vim.keymap.set('n', '<leader>ta', '<cmd>TutorAsk<cr>', { buffer = a.buf, desc = 'Ask the course tutor' })
  end })
end
return M
