local function toggle_gui(player)
  player.print('TODO: open research queue GUI')
end

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == 'sonaxaton-research-queue' then
    local player = game.players[event.player_index]
    if player ~= nil then
      toggle_gui(player)
    end
  end
end)

script.on_event('sonaxaton-research-queue', function(event)
  local player = game.players[event.player_index]
  if player ~= nil then
    toggle_gui(player)
  end
end)
