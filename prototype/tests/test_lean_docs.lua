local function main()
  local parser=require('sf_docs.lean_parser')
  local source={
    '-- /-! not documentation -/',
    'def s := "escaped \\" /-- still a string -/"',
    'def raw := r##"/-! not a comment -/"##',
    'def «/-! identifier -/» := 1',
    '/- ordinary /-! nested documentation -/ comment -/',
    '/-! # A heading',
    '',
    'Text with "quotes" and /- nested -/ content.',
    '-/',
    '/-- A declaration with `Nat`. -/',
    'def answer := 42',
    'def inline := /-! inline prose -/ 3',
    '/-! unfinished',
  }
  local blocks=parser.scan(source)
  assert(#blocks==3,vim.inspect(blocks))
  assert(blocks[1].first==6 and blocks[1].last==9 and blocks[1].standalone)
  assert(blocks[2].first==10 and blocks[2].standalone)
  assert(not blocks[3].standalone)
  local chars=parser.scan({[[def quote : Char := '"']], [[def unicode : Char := 'λ']], '/-! Still prose -/'})
  assert(#chars==1 and chars[1].first==3, vim.inspect(chars))
  local buf=vim.api.nvim_create_buf(true,false)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf,0,-1,false,source)
  vim.bo.filetype='lean'
  local docs=require('sf_docs')
  local state=docs.states[buf]
  assert(state and state.language=='lean' and #state.blocks==3)
  assert(vim.fn.foldclosed(7)~=-1,'documentation must start folded without graphics')
  vim.api.nvim_win_set_cursor(0,{6,0})
  docs.toggle('open')
  assert(state.blocks[1].open)
  vim.api.nvim_buf_set_lines(buf,7,8,false,{'Updated **explanation**.'})
  docs.rebuild(buf)
  assert(docs.states[buf].blocks[1].source:find('Updated',1,true))
  docs.toggle('close')
  local expected=vim.deepcopy(source);expected[8]='Updated **explanation**.'
  assert(vim.deep_equal(expected,vim.api.nvim_buf_get_lines(buf,0,-1,false)))
  print('Lean docs: lexical parsing, source preservation, folding and edits passed')
end
local ok,err=xpcall(main,debug.traceback)
if not ok then io.stderr:write(err..'\n');vim.cmd('cquit 1') else vim.cmd('qa!') end
