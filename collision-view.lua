-- name: Collision Display
-- description: Collision based vision. By Isaac0-dev

-- local references of most used functions are more performant
local math_sqrt, sins, coss, atan2s, djui_hud_set_rotation, djui_hud_render_rect, djui_hud_set_color, djui_hud_set_resolution, djui_hud_get_screen_width, collision_find_surface_on_ray, pairs =
      math.sqrt, sins, coss, atan2s, djui_hud_set_rotation, djui_hud_render_rect, djui_hud_set_color, djui_hud_set_resolution, djui_hud_get_screen_width, collision_find_surface_on_ray, pairs

local m0 = gMarioStates[0]
local np0 = gNetworkPlayers[0]

local RAY_CAST_DIR_HEIGHT = gLevelValues.floorLowerLimit - gLevelValues.cellHeightLimit

local sCollisionMap = {}
local sSurfObjects = {}
local sLoadingSurface = {}

local function add_col_to_list(surf)
    if surf and not sCollisionMap[surf._pointer] then

        -- Optimization: Dynamic surfaces (surfaces owned by an object) cannot be recognized, as they are constantly refreshing
        -- this can result in detecting an overload of dynamic surfaces, tolling performance
        -- just cut off all incoming surfaces from the parent object, even if they're new
        if surf.object then
            if sSurfObjects[surf.object._pointer] and sSurfObjects[surf.object._pointer] > 5 then return end
            sSurfObjects[surf.object._pointer] = (sSurfObjects[surf.object._pointer] or 0) + 1
        end

        -- Fetch vertex positions from coop's _get_field() only once
        local vertex1X, vertex1Y, vertex1Z = surf.vertex1.x, surf.vertex1.y, surf.vertex1.z
        local vertex2X, vertex2Y, vertex2Z = surf.vertex2.x, surf.vertex2.y, surf.vertex2.z
        local vertex3X, vertex3Y, vertex3Z = surf.vertex3.x, surf.vertex3.y, surf.vertex3.z

        -- Add surface to map
        sCollisionMap[surf._pointer] = {
            vertex1X = vertex1X, vertex1Y = vertex1Y, vertex1Z = vertex1Z,
            vertex2X = vertex2X, vertex2Y = vertex2Y, vertex2Z = vertex2Z,
            vertex3X = vertex3X, vertex3Y = vertex3Y, vertex3Z = vertex3Z,
        }

        -- Search (in a circle) around each vertex for another surface
        local sins, coss, collision_find_surface_on_ray = sins, coss, collision_find_surface_on_ray -- Avoid upvalues in the loop
        for i = 1, 3 do
            local posX, posY, posZ = vertex3X, vertex3Y, vertex3Z
            if i == 1 then posX, posY, posZ = vertex1X, vertex1Y, vertex1Z end
            if i == 2 then posX, posY, posZ = vertex2X, vertex2Y, vertex2Z end
            for angle = 0, 180 do
                local s16Angle = angle * (0x10000 / 180)
                local rii = collision_find_surface_on_ray(posX + sins(s16Angle), posY + 200, posZ + coss(s16Angle), 0, RAY_CAST_DIR_HEIGHT, 0)
                if rii then
                    local surface = rii.surface
                    if surface and not sCollisionMap[surface._pointer] then

                        -- Store the found surface to be processed
                        -- by this same function later. This avoids the game hanging.
                        sLoadingSurface[#sLoadingSurface+1] = surface
                    end
                end
            end
        end
    end
end

local currArea  = 0
local currLevel = 0
local function reset_map()
    if currLevel ~= np0.currLevelNum or currArea ~= np0.currAreaIndex then
        currArea  = np0.currAreaIndex
        currLevel = np0.currLevelNum
        sCollisionMap = {}
        sSurfObjects = {}
        sLoadingSurface = {}

        -- Update in case a romhack modifies these
        RAY_CAST_DIR_HEIGHT = gLevelValues.floorLowerLimit - gLevelValues.cellHeightLimit
    end
end

hook_event(HOOK_ON_WARP, reset_map)
hook_event(HOOK_ON_LEVEL_INIT, reset_map)

hook_event(HOOK_ON_HUD_RENDER_BEHIND, function ()
    local cam = m0.area.camera
    if not cam then return end
    local mtx = cam.mtx

    djui_hud_set_resolution(RESOLUTION_DJUI)

    local screen_w = djui_hud_get_screen_width()
    local screen_h = djui_hud_get_screen_height()

    -- Generate map
    add_col_to_list(m0.floor)
    local loadedCount = 0
    for k, surf in pairs(sLoadingSurface) do
        add_col_to_list(surf)
        sLoadingSurface[k] = nil
        if loadedCount > 200 then break end
        loadedCount = loadedCount + 1
    end

    local hsw = screen_w / 2
    local hsh = screen_h / 2

    local a = mtx.a
    local b = mtx.b
    local c = mtx.c

    local e = mtx.e
    local f = mtx.f
    local g = mtx.g

    local i = mtx.i
    local j = mtx.j
    local k = mtx.k

    local m = mtx.m
    local n = mtx.n
    local o = mtx.o

    local function get_on_screen_position(px, py, pz)
        local ox, oy, oz = a * px + e * py + i * pz + m,
                           b * px + f * py + j * pz + n,
                           c * px + g * py + k * pz + o
        if oz >= 0 then return end
        return (ox * (0x51E / -oz)) + hsw, (oy * (0x51E / oz)) + hsh
    end

    -- Draw map
    djui_hud_set_color(0xFF, 0xFF, 0xFF, 0xFF)
    for _, surf in pairs(sCollisionMap) do
        for i = 1, 3 do
            local pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z = surf.vertex1X, surf.vertex1Y, surf.vertex1Z, surf.vertex2X, surf.vertex2Y, surf.vertex2Z
            if i == 2 then pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z = pos2X, pos2Y, pos2Z, surf.vertex3X, surf.vertex3Y, surf.vertex3Z end
            if i == 3 then pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z = surf.vertex3X, surf.vertex3Y, surf.vertex3Z, pos1X, pos1Y, pos1Z end

            local s1x, s1y = get_on_screen_position(pos1X, pos1Y, pos1Z)
            local s2x, s2y = get_on_screen_position(pos2X, pos2Y, pos2Z)
            if s1x and s2x then
                local angle = atan2s(s2y - s1y, s2x - s1x) - 0x4000 -- magic value because of atan2s (-90 degrees)
                local hDist = math_sqrt((s2x - s1x)^2 + (s2y - s1y)^2)
                djui_hud_set_rotation(angle, 0, 0.5)
                djui_hud_render_rect(s1x, s1y, hDist, 1)
            end
        end
    end
end)
