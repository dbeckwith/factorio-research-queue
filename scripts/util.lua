local util = {}

function util.iter_list(list)
  local f, s, var = ipairs(list)
  return function()
      local i, v = f(s, var)
      var = i
      return v
  end
end

function util.iter_values(t)
  local f, s, var = pairs(t)
  return function()
      local i, v = f(s, var)
      var = i
      return v
  end
end

function util.iter_filter(iter, f)
  return function()
    while true do
      local value = iter()
      if value == nil then
        break
      end
      if f(value) then
        return value
      end
    end
  end
end

function util.contains_substring(s, sub)
  return string.find(s, sub, 1, true)
end

function util.join_strings(strs)
  return table.concat(strs)
end

function util.prepare_search_terms(s)
  if s == nil or s == '' then
    return {}
  end
  local terms = {}
  for w in string.gmatch(s, '([%w]+)') do
    table.insert(terms, string.lower(w))
  end
  return terms
end

function util.fuzzy_search(s, terms)
  if next(terms) == nil then
    return true
  end
  local s_terms = util.prepare_search_terms(s)
  if next(s_terms) == nil then
    return false
  end
  local s_terms_joined = util.join_strings(s_terms)
  for _, term in pairs(terms) do
    if not util.contains_substring(s_terms_joined, term) then
      return false
    end
  end
  return true
end

return util
