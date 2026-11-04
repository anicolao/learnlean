local function main()
  assert(vim.bo.filetype == 'lean')
  assert(vim.fn.exists(':TutorAsk') == 0, 'trial must be independent of tutor setup')
  local client
  assert(vim.wait(30000, function()
    client = vim.lsp.get_clients({ name = 'leanls', bufnr = 0 })[1]
    return client and client.initialized
  end, 100), 'Lean language server did not initialize')
  assert(vim.wait(30000, function()
    return #vim.diagnostic.get(0) > 0
  end, 100), 'Expected #check/#eval messages')
  local view = require('lean.infoview').get_current_infoview()
  assert(view and #vim.api.nvim_list_wins() >= 2, 'Default Infoview did not open')
  local buf = vim.api.nvim_get_current_buf()
  local response = client:request_sync('$/lean/plainGoal', {
    textDocument = {uri=vim.uri_from_bufnr(buf)}, position={line=7,character=4},
  }, 30000, buf)
  assert(response and not response.err and response.result, vim.inspect(response))
  assert(vim.inspect(response.result):find('P',1,true), 'Expected a live proof goal')
  vim.api.nvim_buf_set_lines(buf,7,8,false,{'  · exact hQ'})
  assert(vim.wait(30000, function()
    return #vim.diagnostic.get(buf,{severity=vim.diagnostic.severity.ERROR})>0
  end,100), 'Unsaved invalid proof did not produce an error')
  print('Lean trial: LSP, live goals, default Infoview, messages and unsaved diagnostics passed')
end
local ok,err=xpcall(main,debug.traceback)
if not ok then io.stderr:write(err..'\n');vim.cmd('cquit 1') else vim.cmd('qa!') end
