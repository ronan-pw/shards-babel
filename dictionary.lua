local dictionary = { index = {} }

--- Creates a dictionary based on a table of strings, words and their translations.
-- @param partials A table who's keys are strings and their values are translations. Usually used to substitute letters in a larger word.
-- @param words Whole-words and their translations.
function dictionary.new(partials, wholes)
  local dict = { partial = {}, wholes = wholes or {} }
  partials = partials or {}
  local shortest
  local longest

  function init(length)
    if dict.partial[length] == nil then
      dict.partial[length] = {}
    end
  end

  -- Build the dictionary by word length.
  for k,v in pairs(partials) do
    local length = #k
    init(length)
    dict.partial[length][k:lower()] = v:lower()
    if longest == nil or length > longest then
      longest = length
    end
    if shortest == nil or length < shortest then
      shortest = length
    end
  end

  -- Pad unused lengths.
  if shortest and longest then
    for i = shortest, longest do
      init(i)
    end
  end

  dict.partial.shortest = shortest
  dict.partial.longest = longest
  setmetatable(dict, { __index = dictionary.index })

  return dict
end

--- Looks up a whole word in a dictionary.
-- @param dict The dictionary used.
-- @param string The string to look up.
function dictionary.index:lookup(word)
  return self.wholes[word:lower()]
end

--- Attempts to find a complete or partial match for a given string.
-- @param string The string to look up.
function dictionary.index:lookup_partial(string)
  local shortest = self.partial.shortest
  if shortest == nil or self.partial.longest == nil then
    return nil
  end

  local max_match_length = math.min(self.partial.longest, #string)

  for len = max_match_length, shortest, -1 do
    local sub = string:sub(1, len)

    local sub_dict = self.partial[len]    
    if sub_dict ~= nil then
      lookup = sub_dict[sub:lower()]
    else
      lookup = nil
    end

    if lookup ~= nil then
      -- Translation found.
      return lookup, len
    end
  end

  return nil, 0

end

return dictionary