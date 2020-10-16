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

function util.compare(v1, v2)
  if v1 == nil then
    if v2 == nil then
      return 0
    else
      return -1
    end
  elseif v2 == nil then
    return 1
  end
  local t = type(v1)
  assert(t == type(v2), 'cannot compare values of different types')
  if t == 'table' then
    for i = 1,math.max(#v1, #v2) do
      local c = util.compare(v1[i], v2[i])
      if c ~= 0 then return c end
    end
    return 0
  elseif t == 'boolean' then
    return (v1 and 1 or 0) - (v2 and 1 or 0)
  else
    if v1 == v2 then
      return 0
    elseif v1 < v2 then
      return -1
    else
      return 1
    end
  end
end

function util.sort_by_key(list, key)
  local keys = {}
  table.sort(list, function(a, b)
    if keys[a] == nil then
      keys[a] = key(a)
    end
    if keys[b] == nil then
      keys[b] = key(b)
    end
    return util.compare(keys[a], keys[b]) < 0
  end)
end

function util.format_duration(t)
  local neg = t < 0
  if neg then t = -t end
  s = math.floor(t % 60)
  m = math.floor((t / 60) % 60)
  h = math.floor(t / 60 / 60)
  return
    (neg and '-' or '') ..
    (h > 0 and tostring(h)..'h' or '') ..
    (m > 0 and tostring(m)..'m' or '') ..
    (tostring(s)..'s')
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
  -- unfortunately %w doesn't seem to work in some locales (ru)
  for w in string.gmatch(s, '([^%c%z%s%p]+)') do
    table.insert(terms, string.lower(w))
  end
  return terms
end

function util.fuzzy_search(text, terms)
  if next(terms) == nil then
    return true
  end
  local text_terms = util.prepare_search_terms(text)
  if next(text_terms) == nil then
    return false
  end
  local text_terms_joined = util.join_strings(text_terms)
  for _, term in pairs(terms) do
    if not util.contains_substring(text_terms_joined, term) then
      return false
    end
  end
  return true
end

function is_rocket_silo_available(player)
  -- find all rocket silo entities
  for _, entity in pairs(game.get_filtered_entity_prototypes{
    {filter='type', type='rocket-silo'},
  }) do
    -- get all items that create the rocket silo
    for _, item in pairs(entity.items_to_place_this) do
      -- check if the item is a product of an enabled recipe
      for _, recipe in pairs(player.force.recipes) do
        if recipe.enabled then
          for _, product in pairs(recipe.products) do
            if product.type == 'item' and product.name == item.name then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function util.is_item_available(player, item_name)
  -- is it a product of any enabled recipe?
  for _, recipe in pairs(player.force.recipes) do
    if recipe.enabled then
      for _, product in pairs(recipe.products) do
        if product.type == 'item' and product.name == item_name then
          return true
        end
      end
    end
  end

  -- is it a mineable product of any resource?
  for _, entity in pairs(game.get_filtered_entity_prototypes{
    {mod='and', filter='type', type='resource'},
    {mod='and', filter='autoplace'},
    {mod='and', filter='minable'},
  }) do
    if entity.mineable_properties.products ~= nil then
      for _, product in pairs(entity.mineable_properties.products) do
        if product.type == 'item' and product.name == item_name then
          return true
        end
      end
    end
  end

  if is_rocket_silo_available(player) then
    -- is it a rocket launch product of any item?
    for _, item in pairs(game.item_prototypes) do
      for _, product in pairs(item.rocket_launch_products) do
        if product.type == 'item' and product.name == item_name then
          -- is that item available?
          if util.is_item_available(player, item.name) then
            return true
          end
        end
      end
    end
  end

  return false
end

return util
