local function main()
  local parser = require('sf_docs.parser')
  local docs = require('sf_docs')
  local lines = {
    'Definition s := "(** not a comment *)".',
    '(* ordinary (* nested *) comment *)',
    '(** * Heading *)',
    '',
    '(** A paragraph with [nat].',
    '    A nested (* comment *) and a quoted "*)".',
    '    More prose. *)',
    'Definition answer := 42.',
    '(** one-line note *)',
    '(** Another paragraph.',
    '    Its second line. *)',
  }
  local parsed = parser.scan(lines)
  assert(#parsed == 4, vim.inspect(parsed))
  local _, separators = parser.scan({
    '(* #### *)', '(* ==== *)', '(* ---- *)',
    '(* #### important prose #### *)',
    'Check nat. (* #### *)', 'Definition s := "(* #### *)".',
    '(* outer (* #### *) comment *)',
  })
  assert(#separators == 3, 'only standalone decorative comments should disappear')
  assert(parsed[2].first == 5 and parsed[2].last == 7)
  assert(#parser.scan({'(** unfinished'}) == 0)
  assert(not parser.scan({'Check nat. (** inline *)'})[1].standalone)
  vim.cmd('enew!')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo.filetype = 'coq'
  assert(docs.states[buf])
  vim.cmd('redraw!')
  assert(vim.fn.foldclosed(6) == 6, 'doc body should start closed')
  assert(vim.fn.foldclosed(8) == -1, 'code must remain outside doc fold')
  assert(vim.fn.foldclosed(2) == -1, 'ordinary comments are not documentation')
  vim.api.nvim_win_set_cursor(0, {5, 0})
  docs.toggle('open')
  assert(vim.fn.foldclosed(6) == -1)
  vim.api.nvim_buf_set_lines(buf, 5, 6, false, {'    Changed without saving; _emphasis_.'})
  assert(vim.wait(2000, function() return docs.states[buf].tick == vim.api.nvim_buf_get_changedtick(buf) end, 20))
  assert(docs.states[buf].blocks[2].source:find('Changed without saving', 1, true))
  assert(docs.states[buf].blocks[2].open, 'editing should not reclose the source')
  docs.toggle('close')
  assert(vim.fn.foldclosed(6) == 6)
  docs.all(true)
  assert(vim.fn.foldclosed(11) == -1)
  docs.all(false)
  assert(vim.fn.foldclosed(11) == 11)
  -- A one-line documentation comment also has a source/preview toggle.
  vim.api.nvim_win_set_cursor(0, {3, 0})
  docs.toggle('open')
  assert(docs.states[buf].blocks[1].open)
  docs.toggle('close')
  assert(not docs.states[buf].blocks[1].open)
  local expected = vim.deepcopy(lines)
  expected[6] = '    Changed without saving; _emphasis_.'
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), expected), 'presentation modified source')
  -- Deleting a block must remove it after debounce without stale extmarks.
  vim.api.nvim_buf_set_lines(buf, 4, 7, false, {})
  assert(vim.wait(2000, function() return #docs.states[buf].blocks == 3 end, 20))
  -- Dirty previews must be invalidated before deferred cleanup or BufWritePost.
  local retired = { clear = function() end }
  docs.states[buf].blocks[1].image = retired
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, {'Check bool.'})
  assert(retired.sf_docs_stale, 'on_lines must retire image synchronously')
  -- Lookahead is bounded by source characters, not screen rows or whole files.
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {'visible', string.rep('é', 600), string.rep('x', 500), 'beyond'})
  assert(docs.lookahead_end(buf, 1) == 3, 'lookahead must include ~1k characters, including Unicode')
  assert(docs.lookahead_end(buf, 4) == 4, 'lookahead must stop at EOF')
  -- Compact graphical layout uses line concealment, with no native summary row.
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {'(** Heading', 'body', '*)', 'Check nat.'})
  docs.rebuild(buf)
  docs.states[buf].compact = true
  vim.wo.foldenable = false
  vim.wo.conceallevel = 2
  vim.wo.concealcursor = 'nvic'
  vim.api.nvim_win_set_cursor(0, {1, 0})
  docs.toggle('close')
  vim.cmd('redraw!')
  local win = vim.api.nvim_get_current_win()
  local header = vim.fn.screenpos(win, 1, 1).row
  assert(vim.fn.screenpos(win, 4, 1).row == header + 1, 'conceal must hide only the comment body, never following code')
  docs.toggle('open')
  vim.cmd('redraw!')
  assert(vim.fn.screenpos(win, 4, 1).row == header + 3, 'open must restore every source line')
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), {'(** Heading', 'body', '*)', 'Check nat.'}))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {'Check nat.', '(* #### *)', '(* ==== *)', 'Check bool.'})
  docs.rebuild(buf)
  docs.states[buf].compact = true
  vim.wo.foldenable = false
  docs.refresh()
  vim.cmd('normal! ggzt')
  vim.cmd('redraw!')
  assert(vim.fn.screenpos(win, 4, 1).row == vim.fn.screenpos(win, 1, 1).row + 1, 'separators must occupy no rows')
  docs.all(true)
  docs.refresh()
  vim.cmd('redraw!')
  assert(vim.fn.screenpos(win, 4, 1).row == vim.fn.screenpos(win, 1, 1).row + 3, 'zR must expose separator source')
  assert(vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1] == '(* #### *)')
  print('Plugin: lexical parsing, default folding, open/edit/close, one-line docs, and source preservation passed')
end
local ok, err = xpcall(main, debug.traceback)
if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') else vim.cmd('qa!') end
