local hud_id = nil

local protected_zones = {
    {name = "Zone1", pos = {x = 0, y = 0, z = 0}, pos2 = {x = 10, y = 10, z = 10}},
    {name = "Zone2", pos = {x = 50, y = 0, z = 50}, pos2 = {x = 15, y = 15, z = 15}},
}

local function isInProtectedZone(player_pos)
    for _, zone in ipairs(protected_zones) do
        local within_x = player_pos.x >= zone.pos.x and player_pos.x <= zone.pos.x + zone.pos2.x
        local within_y = player_pos.y >= zone.pos.y and player_pos.y <= zone.pos.y + zone.pos2.y
        local within_z = player_pos.z >= zone.pos.z and player_pos.z <= zone.pos.z + zone.pos2.z

        if within_x and within_y and within_z then
            return zone.name
        end
    end
    return nil
end

local function updateHUD(player)
    local player_pos = player:getpos()
    local zone_name = isInProtectedZone(player_pos)

    if zone_name then
        player:hud_change(hud_id, "text", "Zone anti-PvP : " .. zone_name)
    else
        player:hud_change(hud_id, "text", "")
    end
end

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        updateHUD(player)
    end
end)

minetest.register_on_joinplayer(function(player)
    hud_id = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.95, y = 0.98},
        text = "",
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 15},
        number = 0xFFFFFF,
    })

    updateHUD(player)
end)
