local language = { index = {} }
local dictionary = require "dictionary"
local words = require "parse"
local text = require "text"

local count = 0

--- The default means to translate a word. Generally used as a fallback.
-- @param word The word to be translated.
function language.default_obfuscate(word)
  local res = ""
  for i = 1, #word do
    res = res .. "*"
  end
  return res
end

language.emote_chars = { start = {}, stop = {} }
language.emote_chars.start["["] = true
language.emote_chars.stop["]"] = true
language.emote_chars.start["*"] = true
language.emote_chars.stop["*"] = true

language.default = nil

--- Adds a language to the system.
-- @param lang A table containing keys:
-- dictionary, a table used to translate whole words. If words are not found, the obfuscation function is called.
-- obfuscate, a function which obfuscates a word. Defaults to a function replacing all letters with asterisks.
-- abbrev, the abbreviation for this language. Defaults to the first four letters of the language's name.
-- name, the name of the language.
-- color, the default display color as a number. Defaults to grey.
function language.new(lang_conf)
  count = count + 1
  local new_lang = {
    dictionary = lang_conf.dictionary,
    obfuscate = lang_conf.obfuscate or language.default_obfuscate,
    abbrev = lang_conf.abbrev or lang_conf.name:sub(1,4)
  }

  setmetatable(new_lang, { __index = language.index })

  language.default = language.default or new_lang  

  return new_lang
end

--- Returns a string who's case roughly matches the original word's.
-- @param original The original string, before it was translated.
-- @param translated The translated word, assumed to be lower case.
function language.match_case(original, translated)
  local first = original:sub(1,1)  
  if original == original:upper() then
    return translated:upper()
  elseif first:upper() == first then
    return translated:sub(1,1):upper() .. translated:sub(2,#translated)
  else
    return translated
  end
end

--- A function which translates a string based on a dictionary. Used to obfuscate unknown language.
-- @param dict The dictionary used.
-- @param original The string to translate.
function language.index:translate(original)
  if self.dictionary == nil then
    return language.default_obfuscate(original)
  end
  
  local longest = self.dictionary.longest
  if longest == nil then
    return language.default_obfuscate(original)
  end

  local result = ""
  local remaining = original
  local shortest = self.dictionary.shortest

  function translated(length, to)
    result = result .. to
    remaining = remaining:sub(1 + length, #remaining)
  end

  while remaining ~= "" do    
    local max_match_length
    max_match_length = math.min(longest, #remaining)

    local lookup, len = self.dictionary:lookup_partial(remaining)
    if lookup ~= nil then
      result = result .. language.match_case(remaining:sub(1, len), lookup)
      remaining = remaining:sub(1 + len, #remaining)
    else
      result = result .. remaining:sub(1,1)
      remaining = remaining:sub(2,#remaining)
    end
  end

  return result
end

function language.try_express(content, skill, can_express)
  local strings = words.to_strings(content, language.emote_chars)
  local problems = {}
  local problem_count = 0
  for i = 1, #strings do
    local str = strings[i]
    if words.is_word(str) and not can_express(str, skill) then
      problem_count = problem_count + 1
      problems[problem_count] = str      
    end
  end

  return strings, problems
end

--- Attempts to speak a language.
--- Returns the spoken content and an array of problem words which cannot be spoken with the given skill level.
-- @param language The language table spoken.
-- @param content The spoken content.
-- @param skill The skill of the speaker.
function language.index:speak(content, skill)
  return self:write(content, skill)
end

--- Attempts to speak a language.
--- Returns the written content, or an array of words which cannot be written with the given skill level.
-- @param language The language table written.
-- @param content The written content.
-- @param skill The skill of the writer.
function language.index:write(content, skill)
  local strings, problems = language.try_express(content, skill, words.can_write)

  if #problems > 0 then
    return problems
  end
  return text.new(self, strings, skill)
end

return language