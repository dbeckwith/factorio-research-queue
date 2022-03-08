local queue = require "scripts.queue"
local rqtech = require "scripts.rqtech"
local actions = require "scripts.gui.actions"

remote.add_interface(
    "sonaxaton-research-queue", {
        get_queued_names = function(force)
            local result = {}
            for technology in queue.iter(force) do --
                table.insert(result, technology.tech.name)
            end
            return result
        end,

        enqueue = function(force, name)
            local technology = rqtech.new(force.technologies[name])
            queue.enqueue(force, technology)
            queue.update(force)
            for _, player in pairs(force.players) do
                local player_data = global.players[player.index]
                if player_data ~= nil then
                    local gui_data = player_data.gui
                    if gui_data.window.valid and gui_data.window.visible then
                        actions.update_queue(player, technology)
                    end
                end
            end

        end,
    }
)
