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
