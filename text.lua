local text = { index = {} }
local parse = require "parse"

--- Attempts to translate the text given a certain language skill level.
-- @param skill The skill level of the translator.
function text.index:translate(skill)
  if skill >= 100 then
    -- Language mastery, save cycles and return the original.
    return self.original()
  else
    -- Possible incomplete translation
    if skill >= self.max_skill() then
      -- Complete translation, save cycles and return the origal.
      return self.original()
    elseif skill < self.min_skill() then
      -- Translation impossible, save cycles and return the obfuscated text.
      return self.obfuscated()
    else
      -- Partial translation.
      return obfuscate(skill)
    end
  end
end

--- Creates and returns a new text which can be obfuscated.
-- @param original The original text in a RL language.
-- @param language The IG language of the text.
function text.new(language, strings, expresser_skill)
  local new_text = {}
  new_text.language = language
  new_text.strings = strings
  new_text.skill = expresser_skill

  local obfuscated, min_skill, max_skill

  function obfuscate(skill)
    local result = ""
    local strs = strings
    for i = 1, #strs do
      local str = strs[i]
      if parse.is_word(str) and not parse.can_translate(str, skill) then
        result = result .. language:translate(str)
      else
        result = result .. str
      end
    end
    return result
  end

  local original
  function new_text.original()
    if not original then
      original = ""
      for i = 1, #strings do
        original = original .. strings[i]
      end
    end
    return original
  end

  --- The obfuscated text.
  function new_text.obfuscated()
    if not obfuscated then
      obfuscated = obfuscate(0)
    end    
    return obfuscated
  end

  local skills = {}
  function skills_required()
    if not skills then
      compute_skills()
    end
    return skills
  end

  function compute_skills()
    min_skill = 100
    max_skill = 0
    local strs = strings
    for i = 1, #strs do
      local str = strs[i]
      if parse.is_word(str) then
        local skill = parse.skill_required(str)
        skills[i] = skill
        if skill > max_skill then
          max_skill = skill
        end
        if skill < min_skill then
          min_skill = skill
        end
      end
    end
  end

  --- The minimum skill needed to translate any part of the text.
  function new_text.min_skill()
    if not min_skill then
      compute_skills()
    end
    return min_skill
  end

  --- The skill needed to translate all of the text.
  function new_text.max_skill()
    if not max_skill then
      compute_skills()
    end
    return max_skill
  end

  --- Returns the language if a given skill level can identify it. Returns nil on failure, and may identify the wrong language.
  -- @param skill The skill level of the translator.
  function new_text.id_language(skill)
    if skill >= (new_text.min_skill() / 2) then
      return language
    else return nil
    end
  end

  setmetatable(new_text, { __index = text.index })

  return new_text
end

return text