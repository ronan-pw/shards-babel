local words = {}
local dictionary = require "dictionary"

--- Returns whether or not a string is a word.
-- @param str A string.
function words.is_word(str)
  local head, tail = str:find("%a")
  return head == 1
end

--- Returns the skill required to translate a word, from 0 to 100.
-- @param word A word (non-empty string without spaces or punctuation)
function words.skill_required(word)
  if word == "" or type(word) ~= "string" then
    return nil
  end

  local len = string.len(word)

  if len > 20 then
    return 100
  elseif len < 1 then
    return nil
  else
    return len * 5
  end
end

--- Returns whether or not a given language skill indicates that a given word is understood.
-- @param word The word in question.
-- @param skill A creature's language skill, from 0 to 100.
-- @param spoken A boolean indicating if the text was spoken (false for written)
function words.understands(word, skill, spoken)
  local req = words.skill_required(word)
  return req ~= nil and skill >= req
end

words.ooc = "%/[^/]+/?"
words.emote = "%[[^%]]+%]?"

function words.to_strings(text)
  local result = {}
  local count = 0
  local index = 1

  function range(pattern)
    local r = {}
    r.start = 0
    r.stop = 0

    function r.take()
      if index > r.start then
        r.start, r.stop = text:find(pattern, index)
        r.start = r.start or math.huge
        r.stop = r.stop or math.huge
      end

      if index == r.start then
        result[count] = text:sub(r.start, r.stop)
        index = r.stop + 1
        return true
      end
      return false
    end

    return r
  end

  local ooc = range(words.ooc)
  local emote = range(words.emote)
  local letter = range("%a+")

  while index <= #text do
    count = count + 1

    if ooc.take() then
    elseif emote.take() then
    elseif letter.take() then
    else
      local symbol_start, symbol_stop = text:find("%A+", index)
      symbol_stop = math.min(symbol_stop, ooc.start - 1, emote.start - 1)
      result[count] = text:sub(symbol_start, symbol_stop)
      index = symbol_stop + 1
    end

  end
  return result
end

return words