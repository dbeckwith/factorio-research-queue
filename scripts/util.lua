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

return util
