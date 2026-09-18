-- A lexical scan, not a regex over lines: nested comments and quoted strings matter.
local M = {}
function M.scan(lines)
  local text = table.concat(lines, '\n')
  local blocks, level, quote, start, row, col = {}, 0, false, nil, 1, 0
  local separators = {}
  local i = 1
  local function advance(n)
    for _ = 1, n do
      if text:sub(i, i) == '\n' then row, col = row + 1, 0 else col = col + 1 end
      i = i + 1
    end
  end
  while i <= #text do
    local pair, char = text:sub(i, i + 1), text:sub(i, i)
    if quote then
      if pair == '""' then advance(2)
      elseif char == '"' then quote = false; advance(1)
      else advance(1) end
    elseif pair == '(*' then
      if level == 0 then
        local doc = text:sub(i, i + 2) == '(**' and text:sub(i + 3, i + 3):match('[%s)]') ~= nil
        start = { first = row, col = col, offset = i, doc = doc }
      end
      level = level + 1; advance(2)
    elseif pair == '*)' and level > 0 then
      level = level - 1
      advance(2)
      if level == 0 and start then
        local source = text:sub(start.offset, i - 1)
        local standalone = (lines[start.first]:sub(1, start.col):match('^%s*$') ~= nil)
          and (lines[row]:sub(col + 1):match('^%s*$') ~= nil)
        local decoration = source:sub(3, -3):gsub('%s', '')
        if not start.doc and standalone and #decoration >= 4 and decoration:match('^[#=*-]+$') then
          separators[#separators + 1] = { first = start.first, last = row }
        end
        if start.doc then blocks[#blocks + 1] = {
          first = start.first, last = row, source = source, standalone = standalone,
          title = source:gsub('^%(%*%*%s*', ''):gsub('%*%)$', ''):gsub('%s+', ' '):sub(1, 100),
          directive = source:match('^%(%*%*%s+printing%s') ~= nil,
        } end
      end
    elseif char == '"' then quote = true; advance(1)
    else advance(1) end
  end
  return blocks, separators
end
return M
