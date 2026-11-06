local function main()
  local api = vim.api
  local docs = require('sf_docs')
  local buf = api.nvim_create_buf(true, false)
  api.nvim_set_current_buf(buf)
  local lines = { 'example : True := by', '/-! explanation', 'hidden', '-/',
    '  trivial -- trailing comment', '', '/- ordinary', ' /- nested -/', '-/',
    'def s := "-- not a comment"', '/-! final', 'hidden', '-/' }
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo.filetype = 'lean'
  local state = docs.states[buf]
  -- Exercise the actual concealment-mode cursor path without requiring Kitty.
  state.compact = true
  vim.wo.foldenable = false
  api.nvim_win_set_cursor(0, {1, 0})
  vim.cmd('normal j')
  assert(api.nvim_win_get_cursor(0)[1] == 2, 'Preview anchor must be reachable')
  vim.cmd('normal j')
  assert(api.nvim_win_get_cursor(0)[1] == 5, 'j entered hidden comment source')
  vim.cmd('normal k')
  assert(api.nvim_win_get_cursor(0)[1] == 2, 'k entered hidden comment source')
  docs.toggle('open')
  vim.cmd('normal j')
  assert(api.nvim_win_get_cursor(0)[1] == 3, 'Opened prose must be traversable')
  docs.toggle('close')
  api.nvim_win_set_cursor(0, {1, 0})
  vim.cmd('normal 2j')
  assert(api.nvim_win_get_cursor(0)[1] == 5, 'Count should count visible lines')
  api.nvim_win_set_cursor(0, {11, 0})
  vim.cmd('normal j')
  assert(api.nvim_win_get_cursor(0)[1] == 11, 'EOF must not enter hidden prose')
  local nav = require('sf_lean_navigation')
  api.nvim_win_set_cursor(0, {2, 0})
  nav.step(1, 1)
  assert(vim.deep_equal(api.nvim_win_get_cursor(0), {5, 9}), 'Step should stop after code, before trailing comment')
  nav.step(1, 1)
  assert(api.nvim_win_get_cursor(0)[1] == 10, 'Skip blank and nested ordinary comments')
  nav.step(1, 1)
  assert(api.nvim_win_get_cursor(0)[1] == 10, 'No code after final comment')
  nav.step(-1, 2)
  assert(api.nvim_win_get_cursor(0)[1] == 1, 'Backward counted navigation')
  assert(vim.deep_equal(lines, api.nvim_buf_get_lines(buf, 0, -1, false)), 'Navigation changed source')
  print('Lean navigation: concealed docs, counts, open comments, EOF, code positions and source preservation passed')
end
local ok, err = xpcall(main, debug.traceback)
if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') else vim.cmd('qa!') end
