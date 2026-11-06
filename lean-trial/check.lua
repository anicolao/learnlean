local function main()
  assert(vim.bo.filetype == 'lean')
  assert(vim.fn.exists(':TutorAsk') == 2, 'Lean tutor command missing')
  assert(vim.fn.maparg(' ta', 'n'):find('TutorAsk', 1, true), 'Space t a must open the tutor')
  assert(vim.fn.executable('sf-tutor') == 1, 'Packaged tutor missing')
  local prompt
  vim.ui.input = function(opts) prompt = opts.prompt end
  vim.cmd('TutorAsk')
  assert(prompt == 'Ask the tutor: ', 'Tutor dialog did not open')
  local client
  assert(vim.wait(30000, function()
    client = vim.lsp.get_clients({ name = 'leanls', bufnr = 0 })[1]
    return client and client.initialized
  end, 100), 'Lean language server did not initialize')
  -- Check the selected process too: Lake's fallback would otherwise make the
  -- standalone goals/diagnostics checks pass despite the startup warning.
  local start, command = vim.lsp.rpc.start
  vim.lsp.rpc.start = function(cmd) command = cmd end
  local started, err = pcall(client.config.cmd, {}, client.config)
  vim.lsp.rpc.start = start
  assert(started, err)
  local root = client.config.root_dir
  local is_project = vim.uv.fs_stat(root .. '/lakefile.toml')
    or vim.uv.fs_stat(root .. '/lakefile.lean')
  assert(command[1] == (is_project and 'lake' or 'lean'), vim.inspect(command))
  assert(vim.wait(30000, function()
    return #vim.diagnostic.get(0) > 0
  end, 100), 'Expected #check/#eval messages')
  local view = require('lean.infoview').get_current_infoview()
  assert(view and #vim.api.nvim_list_wins() >= 2, 'Default Infoview did not open')
  local buf = vim.api.nvim_get_current_buf()
  local proof_line
  for i,line in ipairs(vim.api.nvim_buf_get_lines(buf,0,-1,false)) do
    if line:find('· exact hP',1,true) then proof_line=i-1;break end
  end
  assert(proof_line)
  assert(require('sf_docs').states[buf], 'Documentation plugin not attached')
  local response = client:request_sync('$/lean/plainGoal', {
    textDocument = {uri=vim.uri_from_bufnr(buf)}, position={line=proof_line,character=4},
  }, 30000, buf)
  assert(response and not response.err and response.result, vim.inspect(response))
  assert(vim.inspect(response.result):find('P',1,true), 'Expected a live proof goal')
  local nav = require('sf_lean_navigation')
  assert(vim.fn.maparg('<M-Down>', 'n') ~= '', 'Option-Down mapping missing')
  vim.api.nvim_win_set_cursor(0, { proof_line, 0 }) -- constructor
  nav.step(1, 1)
  local position = vim.lsp.util.make_position_params(0, client.offset_encoding)
  assert(position.position.line == proof_line - 1, vim.inspect(position))
  local after = client:request_sync('$/lean/plainGoal', position, 30000, buf)
  assert(after and after.result and vim.inspect(after.result):find('Q', 1, true), vim.inspect(after))
  assert(#vim.api.nvim_buf_get_extmarks(buf, nav.ns, 0, -1, {}) == 1, 'Inspection marker missing')
  assert(view.info.pin.__position_params.position.line == position.position.line, 'Infoview did not follow stepping')
  nav.step(1, 1)
  assert(vim.api.nvim_win_get_cursor(0)[1] == proof_line + 1, 'Next tactic line not reached')
  nav.step(-1, 1)
  assert(vim.api.nvim_win_get_cursor(0)[1] == proof_line, 'Previous tactic line not reached')
  vim.api.nvim_buf_set_lines(buf,proof_line,proof_line+1,false,{'  · exact hQ'})
  assert(vim.wait(30000, function()
    return #vim.diagnostic.get(buf,{severity=vim.diagnostic.severity.ERROR})>0
  end,100), 'Unsaved invalid proof did not produce an error')
  print('Lean trial: ' .. command[1] .. ', LSP, live goals, default Infoview, messages and unsaved diagnostics passed')
end
local ok,err=xpcall(main,debug.traceback)
if not ok then io.stderr:write(err..'\n');vim.cmd('cquit 1') else vim.cmd('qa!') end
