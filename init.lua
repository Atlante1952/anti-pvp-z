local mod_storage = minetest.get_mod_storage()
local protected_zones = minetest.deserialize(mod_storage:get_string("protected_zones")) or {}
local next_zone_id = #protected_zones + 1

local hud_ids = {}

local function isInProtectedZone(player_pos)
    for _, zone in ipairs(protected_zones) do
        local within_x = player_pos.x >= zone.pos1.x and player_pos.x <= zone.pos2.x
        local within_y = player_pos.y >= zone.pos1.y and player_pos.y <= zone.pos2.y
        local within_z = player_pos.z >= zone.pos1.z and player_pos.z <= zone.pos2.z

        if within_x and within_y and within_z then
            return zone.name
        end
    end
    return nil
end

local function updateHUD(player)
    local player_pos = player:get_pos()
    local zone_name = isInProtectedZone(player_pos)

    if zone_name then
        player:hud_change(hud_ids[player:get_player_name()], "text", "Zone anti-PvP : " .. zone_name)
    else
        player:hud_change(hud_ids[player:get_player_name()], "text", "")
    end
end

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        updateHUD(player)
    end
end)

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    hud_ids[player_name] = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.95, y = 0.98},
        text = "",
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 15},
        number = 0xFFFFFF,
    })

    updateHUD(player)
end)

minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    hud_ids[player_name] = nil
end)

minetest.register_chatcommand("anti_pvp_zone", {
    params = "<x1> <y1> <z1> <x2> <y2> <z2>",
    description = "Create an anti-PvP zone",
    privs = {server = true},
    func = function(name, param)
        local x1, y1, z1, x2, y2, z2 = param:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)$")
        if not x1 or not y1 or not z1 or not x2 or not y2 or not z2 then
            return false, "Invalid parameters. Use: /anti_pvp_zone <x1> <y1> <z1> <x2> <y2> <z2>"
        end

        local pos1 = {x = tonumber(x1), y = tonumber(y1), z = tonumber(z1)}
        local pos2 = {x = tonumber(x2), y = tonumber(y2), z = tonumber(z2)}
        if not pos1 or not pos2 then
            return false, "Invalid positions."
        end

        local zone_name = "Zone" .. next_zone_id
        table.insert(protected_zones, {
            id = next_zone_id,
            name = zone_name,
            pos1 = pos1,
            pos2 = pos2,
        })
        mod_storage:set_string("protected_zones", minetest.serialize(protected_zones))
        next_zone_id = next_zone_id + 1

        return true, "Anti-PvP zone " .. zone_name .. " created."
    end
})

minetest.register_chatcommand("delete_anti_pvp_zone", {
    params = "<zone_id>",
    description = "Delete an anti-PvP zone",
    privs = {server = true},
    func = function(name, param)
        local zone_id = tonumber(param)
        if not zone_id then
            return false, "Invalid zone ID."
        end

        for i, zone in ipairs(protected_zones) do
            if zone.id == zone_id then
                table.remove(protected_zones, i)
                mod_storage:set_string("protected_zones", minetest.serialize(protected_zones))
                return true, "Anti-PvP zone " .. zone.name .. " deleted."
            end
        end

        return false, "Zone ID not found."
    end
})

minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    local pos1 = player:get_pos()
    local is_protected = false

    for _, zone in ipairs(protected_zones) do
        local within_x = pos1.x >= zone.pos1.x and pos1.x <= zone.pos2.x
        local within_y = pos1.y >= zone.pos1.y and pos1.y <= zone.pos2.y
        local within_z = pos1.z >= zone.pos1.z and pos1.z <= zone.pos2.z

        if within_x and within_y and within_z then
            is_protected = true
            break
        end
    end

    if hitter and hitter:is_player() and hitter:get_player_name() ~= player:get_player_name() and not is_protected then
        return true
    end

    return false
end)
