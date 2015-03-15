local language = { index = {} }
local dictionary = require "dictionary"
local words = require "words"
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

  local result = self.dictionary:lookup(original)
  if result ~= nil then
    return language.match_case(original, result)
  end
  
  local longest = self.dictionary.partial.longest
  if longest == nil then
    return language.default_obfuscate(original)
  end

  result = ""
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

--- Attempts to express a language.
--- Returns the spoken content or an array of problem words which are unknown to the speaker.
-- @param language The language table spoken.
-- @param content The spoken content.
-- @param skill The skill of the speaker.
-- @param spoken True if the expression is spoken, false if written.
function language.index.express(language, content, skill, spoken)
  local strings = words.to_strings(content, language.emote_chars)
  local problems = {}
  local problem_count = 0
  for i = 1, #strings do
    local str = strings[i]
    if words.is_word(str) and not words.understands(str, skill, spoken) then
      problem_count = problem_count + 1
      problems[problem_count] = str
    end
  end

  if #problems > 0 then
    return problems
  else
    return text.new(language, strings, skill, spoken)
  end
end

return language