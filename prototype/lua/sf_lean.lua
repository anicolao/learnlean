local M = {}

function M.setup()
  local upstream = vim.lsp.config.leanls
  local project_cmd, project_root = upstream.cmd, upstream.root_dir
  vim.lsp.config('leanls', {
    root_dir = function(bufnr, on_dir)
      project_root(bufnr, function(root)
        on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
      end)
    end,
    cmd = function(dispatchers, config)
      local root = config.root_dir
      if root and (vim.uv.fs_stat(root .. '/lakefile.toml')
          or vim.uv.fs_stat(root .. '/lakefile.lean')) then
        return project_cmd(dispatchers, config)
      end
      return vim.lsp.rpc.start({ 'lean', '--server' }, dispatchers, {
        cwd = config.cmd_cwd or root,
        env = config.cmd_env,
        detached = config.detached,
      })
    end,
  })
end

return M
