local dictionary = { index = {} }

--- Creates a dictionary based on a table of words and their translations.
-- @param words_table A table who's keys are words and their values are translations.
function dictionary.new(words_table)
  local dict = {}
  local shortest
  local longest

  function init(length)
    if dict[length] == nil then
      dict[length] = {}
    end
  end

  -- Build the dictionary by word length.
  for k,v in pairs(words_table) do
    local length = #k
    init(length)
    dict[length][k:lower()] = v:lower()
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

  dict.shortest = shortest
  dict.longest = longest
  setmetatable(dict, { __index = dictionary.index })

  return dict
end

--- Looks up a string in a dictionary.
-- @param dict The dictionary used.
-- @param string The string to look up.
function dictionary.index:lookup(string)
  local sub_dict = self[#string]
  if sub_dict ~= nil then
    return sub_dict[string:lower()]
  end
  return nil
end

--- Attempts to find a complete or partial match for a given string.
-- @param string The string to look up.
function dictionary.index:lookup_partial(string)
  local shortest = self.shortest
  if shortest == nil or self.longest == nil then
    return nil
  end

  local max_match_length = math.min(self.longest, #string)

  for len = max_match_length, shortest, -1 do
    local sub = string:sub(1, len)
    local lookup = self:lookup(sub)
    if lookup ~= nil then
      -- Translation found.
      return lookup, len
    end
  end

  return nil, 0

end

return dictionary