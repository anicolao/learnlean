-- Lean documentation is /-! module prose -/ or /-- declaration prose -/.
-- Ordinary comments, line comments, strings and escaped identifiers are skipped.
local M = {}
function M.scan(lines)
  local text = table.concat(lines, '\n')
  local blocks, i, row, col, depth, start = {}, 1, 1, 0, 0, nil
  local quoted, raw_end
  local code = {}
  local function advance(n, is_code)
    for _ = 1, n do
      if is_code and not text:sub(i,i):match('%s') then
        code[row] = code[row] or { first = col, last = col }
        code[row].last = col
      end
      if text:sub(i,i) == '\n' then row, col = row + 1, 0 else col = col + 1 end
      i = i + 1
    end
  end
  while i <= #text do
    local pair, char = text:sub(i,i+1), text:sub(i,i)
    local literal
    if depth == 0 and not quoted and not raw_end and char == "'" then
      local rest = text:sub(i)
      literal = rest:match("^'\\u%b{}'") or rest:match("^'\\.'")
      if not literal then
        local candidate = rest:match("^'[^'\n]+'");
        if candidate and vim.fn.strchars(candidate) == 3 then literal = candidate end
      end
    end
    if depth > 0 then
      if pair == '/-' then depth = depth + 1; advance(2)
      elseif pair == '-/' then
        depth = depth - 1; advance(2)
        if depth == 0 and start.doc then
          local source = text:sub(start.offset,i-1)
          blocks[#blocks+1] = {
            first=start.row, last=row, source=source, directive=false,
            standalone=lines[start.row]:sub(1,start.col):match('^%s*$') ~= nil
              and lines[row]:sub(col+1):match('^%s*$') ~= nil,
            title=source:sub(4,-3):gsub('%s+',' '):sub(1,100),
          }
        end
      else advance(1) end
    elseif raw_end then
      if text:sub(i,i+#raw_end-1) == raw_end then advance(#raw_end, true); raw_end=nil
      else advance(1, true) end
    elseif quoted then
      if quoted == '"' and char == '\\' then advance(math.min(2,#text-i+1), true)
      elseif text:sub(i,i+#quoted-1) == quoted then advance(#quoted, true); quoted=nil
      else advance(1, true) end
    elseif literal then advance(#literal, true)
    elseif pair == '--' then
      while i <= #text and text:sub(i,i) ~= '\n' do advance(1) end
    elseif pair == '/-' then
      start={offset=i,row=row,col=col,doc=text:sub(i+2,i+2):match('[-!]') ~= nil}
      depth=1; advance(2)
    elseif char == 'r' and text:sub(i):match('^r#*"') then
      local opener=text:sub(i):match('^r#*"')
      raw_end='"' .. opener:sub(2,-2); advance(#opener, true)
    elseif char == '"' then quoted='"'; advance(1, true)
    elseif text:sub(i,i+1) == '«' then quoted='»'; advance(2, true)
    else advance(1, true) end
  end
  return blocks, {}, code
end
return M
