local function main()
  vim.env.SF_DOC_TEST = nil
  vim.env.KITTY_WINDOW_ID = 'test'
  vim.api.nvim_list_uis = function() return {{}} end
  -- Even an old environment override must not restore the overlay renderer.
  vim.env.SF_DOC_GRAPHICS = 'overlay'
  package.preload['image'] = function() error('Legacy renderer must not load') end
  local setups = 0
  package.loaded['sf_docs.placeholders'] = {
    mode = 'placeholders', setup = function() setups = setups + 1 end,
  }
  for _, tmux in ipairs({false, '/tmp/test-tmux,1,0'}) do
    vim.env.TMUX = tmux or nil
    package.loaded['sf_docs'] = nil
    local docs = require('sf_docs')
    docs.refresh()
    local notify = vim.notify
    vim.notify = function() end
    local health = docs.health()
    vim.notify = notify
    assert(health.graphics and health.mode == 'placeholders', vim.inspect(health))
  end
  assert(setups == 2)
  print('Renderer selection: placeholders only, inside/outside tmux, ignoring legacy overrides')
end
local ok, err = xpcall(main, debug.traceback)
if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') else vim.cmd('qa!') end
