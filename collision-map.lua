-- name: Collision Minimap
-- description: Creates a collision based minimap on the top right corner of your screen. By Isaac0-dev

-- local references of most used functions are more performant
local math_abs, math_sqrt, sins, coss, atan2s, djui_hud_set_rotation, djui_hud_render_rect, djui_hud_set_color, djui_hud_set_resolution, djui_hud_get_screen_width, collision_find_surface_on_ray, pairs =
      math.abs, math.sqrt, sins, coss, atan2s, djui_hud_set_rotation, djui_hud_render_rect, djui_hud_set_color, djui_hud_set_resolution, djui_hud_get_screen_width, collision_find_surface_on_ray, pairs
local obj_get_first_with_behavior_id, obj_get_next_with_same_behavior_id, is_player_active = obj_get_first_with_behavior_id, obj_get_next_with_same_behavior_id, is_player_active

local m0 = gMarioStates[0]
local np0 = gNetworkPlayers[0]
local ls = gLakituState

local RAY_CAST_DIR_HEIGHT = gLevelValues.floorLowerLimit - gLevelValues.cellHeightLimit

local sCollisionMap = {}
local sSurfObjects = {}
local sLoadingSurface = {}

local sFrameTop = 0
local sFrameBottom = 0
local sFrameLeft = 0
local sFrameRight = 0

local mapMiddleY = 0
local sBounds = 400 -- The size of the map frame
local sHalfBounds = sBounds / 2

local size = 0
local range = 0

-- Generate a number based on where the point is around the map frame
local function compute_code(x, y)
    local code = 0
    if x < sFrameLeft then
        code = code + 1  -- to the left of the frame
    elseif x > sFrameRight then
        code = code + 2  -- to the right of the frame
    end
    if y < sFrameTop then
        code = code + 4  -- below the frame
    elseif y > sFrameBottom then
        code = code + 8  -- above the frame
    end
    return code
end

-- Clips a line to the given frame edges
-- Returns nil if the line is completely outside frame
local function clip_line(x1, y1, x2, y2)
    local code1, code2 = compute_code(x1, y1), compute_code(x2, y2)

    -- Are both points outside the frame?
    if code1 ~= 0 and code2 ~= 0 then
        return
    end

    -- Check if the line is partially inside the frame
    local x, y = 0, 0
    while code1 ~= 0 or code2 ~= 0 do
        if (code1 & code2) ~= 0 then
            return
        else
            local codeOut = code2
            if code1 ~= 0 then
                codeOut = code1
            end

            -- Calculate intersection position
            if codeOut & 8 ~= 0 then
                x = x1 + (x2 - x1) * (sFrameBottom - y1) / (y2 - y1)
                y = sFrameBottom
            elseif codeOut & 4 ~= 0 then
                x = x1 + (x2 - x1) * (sFrameTop - y1) / (y2 - y1)
                y = sFrameTop
            elseif codeOut & 2 ~= 0 then
                y = y1 + (y2 - y1) * (sFrameRight - x1) / (x2 - x1)
                x = sFrameRight
            elseif codeOut & 1 ~= 0 then
                y = y1 + (y2 - y1) * (sFrameLeft - x1) / (x2 - x1)
                x = sFrameLeft
            end

            if codeOut == code1 then
                x1, y1, code1 = x, y, compute_code(x, y)
            else
                x2, y2, code2 = x, y, compute_code(x, y)
            end
        end
    end
    return x1, y1, x2, y2
end

local function degrees_to_sm64(x)
    return x * 0x10000 / 360
end

local function active_player(m, np)
    if not np.connected or
        np.currCourseNum ~= np0.currCourseNum or
        np.currActNum ~= np0.currActNum or
        np.currLevelNum ~= np0.currLevelNum or
        np.currAreaIndex ~= np0.currAreaIndex then
        return false
    end
    return is_player_active(m)
end

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
        local vertex3X, vertex3Y, vertex3Z = surf.vertex3.x, surf.vertex3.x, surf.vertex3.z

        -- Add surface to map
        sCollisionMap[surf._pointer] = {
            vertex1X = vertex1X, vertex1Z = vertex1Z,
            vertex2X = vertex2X, vertex2Z = vertex2Z,
            vertex3X = vertex3X, vertex3Z = vertex3Z,
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

local y = 90

local currArea  = 0
local currLevel = 0
local function reset_map()
    if currLevel ~= np0.currLevelNum or currArea ~= np0.currAreaIndex then
        currArea  = np0.currAreaIndex
        currLevel = np0.currLevelNum
        sCollisionMap = {}
        sSurfObjects = {}
        sLoadingSurface = {}

        mapMiddleY = y + sHalfBounds
        size = sBounds / 0x2000
        range = sHalfBounds / size
        sFrameTop = y
        sFrameBottom = y + sBounds

        -- Update in case a romhack modifies these
        RAY_CAST_DIR_HEIGHT = gLevelValues.floorLowerLimit - gLevelValues.cellHeightLimit
    end
end

hook_event(HOOK_ON_WARP, reset_map)
hook_event(HOOK_ON_LEVEL_INIT, reset_map)

hook_event(HOOK_ON_HUD_RENDER_BEHIND, function ()
    djui_hud_set_resolution(RESOLUTION_DJUI)

    -- Move the map on the X axis dynamically
    local x = ((djui_hud_get_screen_width() / 4) * 3) - sHalfBounds
    local mapMiddleX = x + sHalfBounds
    local mapMiddleY = mapMiddleY
    local size = size
    sFrameLeft = x
    sFrameRight = x + sBounds

    -- Generate map
    add_col_to_list(m0.floor)
    local loadedCount = 0
    for k, surf in pairs(sLoadingSurface) do
        add_col_to_list(surf)
        sLoadingSurface[k] = nil
        if loadedCount > 200 then break end
        loadedCount = loadedCount + 1
    end

    -- Map background
    djui_hud_set_rotation(0, 0, 0)
    djui_hud_set_color(0, 0, 0, 0x80)
    djui_hud_render_rect(x, y, sBounds, sBounds)

    -- Precalculate some values
    local lsPos = ls.pos
    local lsFocus = ls.focus
    local camYaw = atan2s(lsPos.z - lsFocus.z, lsPos.x - lsFocus.x) - 0x8000
    local camSins = sins(camYaw)
    local camCoss = coss(camYaw)
    local mPosX = m0.pos.x
    local mPosZ = m0.pos.z
    local math_abs = math_abs -- No upvalues for abs, as it's used 4 times in the loop

    -- Draw map
    local rect = 0
    djui_hud_set_color(0xFF, 0xFF, 0xFF, 0xFF)
    for _, surf in pairs(sCollisionMap) do

        -- Attempt to prevent djui from corrupting other on screen elements
        -- not really sure how else to avoid this
        if rect > 800 then break end
        for i = 1, 3 do
            local pos1X, pos1Z, pos2X, pos2Z = surf.vertex1X, surf.vertex1Z, surf.vertex2X, surf.vertex2Z
            if i == 2 then pos1X, pos1Z, pos2X, pos2Z = pos2X, pos2Z, surf.vertex3X, surf.vertex3Z end
            if i == 3 then pos1X, pos1Z, pos2X, pos2Z = surf.vertex3X, surf.vertex3Z, pos1X, pos1Z end

            local pos1DistX = mPosX - pos1X
            local pos1DistZ = mPosZ - pos1Z
            local pos2DistX = mPosX - pos2X
            local pos2DistZ = mPosZ - pos2Z
            if ((math_abs(pos1DistX) < range) or (math_abs(pos1DistZ) < range)) or
                ((math_abs(pos2DistX) < range) or (math_abs(pos2DistZ) < range)) then

                -- Transform positions
                local tPos1X = pos1DistX * size
                local tPos1Y = pos1DistZ * size
                local tPos2X = pos2DistX * size
                local tPos2Y = pos2DistZ * size

                -- Rotate each point around the middle of the frame using the camera yaw
                -- Then clip the line on the map frame edges
                -- Will return nil if the line is outside the frame
                local calcPos1X, calcPos1Z, calcPos2X, calcPos2Z = clip_line(
                    camCoss * tPos1X - camSins * tPos1Y + mapMiddleX,
                    camSins * tPos1X + camCoss * tPos1Y + mapMiddleY,
                    camCoss * tPos2X - camSins * tPos2Y + mapMiddleX,
                    camSins * tPos2X + camCoss * tPos2Y + mapMiddleY
                )

                -- Render the line if in view
                if calcPos1X then
                    local angle = atan2s(pos2Z - pos1Z, pos2X - pos1X) + 0x4000 -- magic value because of atan2s (+90 degrees)
                    local hDist = math_sqrt((calcPos2X - calcPos1X)^2 + (calcPos2Z - calcPos1Z)^2)
                    djui_hud_set_rotation(angle - camYaw, 0, 0.5)
                    djui_hud_render_rect(calcPos1X, calcPos1Z, hDist, 1)
                end
            end
        end
        rect = rect + 1
    end

    -- Camera gradient
    djui_hud_set_rotation(0x8000, 0.5, 0.5)
    for i = 0, 30 do
        local camX = mapMiddleX
        local camY = mapMiddleY - i
        djui_hud_set_color(0xFF, 0xFF, 0xFF, 150 - i*3)
        djui_hud_render_rect(camX - i, camY, i*2, 1)
    end
    djui_hud_set_color(0xFF, 0xFF, 0xFF, 0xFF)

    -- Render each Cappy as a small square
    if bhvOmmCappy then
        local cappy = obj_get_first_with_behavior_id(bhvOmmCappy)
        while cappy ~= nil do
            if cappy.oSubAction ~= 0 then
                local s = 8
                local hs = s/2
                local cappyX = camCoss * ((mPosX - cappy.oPosX) * size) - camSins * ((mPosZ - cappy.oPosZ) * size) + mapMiddleX - hs
                local cappyY = camSins * ((mPosX - cappy.oPosX) * size) + camCoss * ((mPosZ - cappy.oPosZ) * size) + mapMiddleY - hs
                if (cappyX > x and cappyX < sFrameRight) and (cappyY > y and cappyY < sFrameBottom) then
                    djui_hud_set_rotation(0, 0, 0)
                    djui_hud_render_rect(cappyX, cappyY, s, s)
                end
            end
            cappy = obj_get_next_with_same_behavior_id(cappy)
        end
    end

    -- Arrow to show each Mario's facing yaw and position
    do
        local s = 3 -- Line size
        local baseLen = 10 -- Base line length, controls whole triangle size
        local angle = 70 -- Left side angle (in degrees)
        local rightSideAngle = 180 - (angle * 2) -- Right side angle (in degrees)
        local sideLen = baseLen * (angle / rightSideAngle)
        local triHeight = math_sqrt((sideLen^2) - ((baseLen / 2)^2))
        angle = degrees_to_sm64(angle)
        rightSideAngle = degrees_to_sm64(rightSideAngle)

        local halfTriHeight = triHeight / 4
        local halfBaseLenAngle = (baseLen / 2) * 0x10000

        local triOffsetAngle = camYaw + 0x6900 -- offset to fix problems with the triangle
        local faceYaw = m0.faceAngle.y - triOffsetAngle

        -- Right side
        djui_hud_set_rotation(faceYaw + rightSideAngle, 0, 0.5)
        djui_hud_render_rect(
            mapMiddleX + (halfTriHeight * sins(faceYaw + halfBaseLenAngle)),
            mapMiddleY + (halfTriHeight * coss(faceYaw + halfBaseLenAngle)),
            sideLen, s
        )

        -- Left side
        djui_hud_set_rotation(faceYaw + angle, 0, 0.5)
        djui_hud_render_rect(
            mapMiddleX + (halfTriHeight * sins(faceYaw - halfBaseLenAngle)),
            mapMiddleY + (halfTriHeight * coss(faceYaw - halfBaseLenAngle)),
            sideLen, s
        )

        -- Other players
        local mStates = gMarioStates
        local nPlayers = gNetworkPlayers
        for i = 1, MAX_PLAYERS - 1 do
            local m = mStates[i]
            if active_player(m, nPlayers[i]) then
                local mx = (mPosX - m.pos.x) * size
                local mz = (mPosZ - m.pos.z) * size
                local playerX = camCoss * mx - camSins * mz + mapMiddleX
                local playerY = camSins * mx + camCoss * mz + mapMiddleY
                if (playerX > x and playerX < sFrameRight) and (playerY > y and playerY < sFrameBottom) then
                    faceYaw = m.faceAngle.y - triOffsetAngle

                    -- Right side
                    djui_hud_set_rotation(faceYaw + rightSideAngle, 0, 0.5)
                    djui_hud_render_rect(
                        playerX + (halfTriHeight * sins(faceYaw + halfBaseLenAngle)),
                        playerY + (halfTriHeight * coss(faceYaw + halfBaseLenAngle)),
                        sideLen, s
                    )

                    -- Left side
                    djui_hud_set_rotation(faceYaw + angle, 0, 0.5)
                    djui_hud_render_rect(
                        playerX + (halfTriHeight * sins(faceYaw - halfBaseLenAngle)),
                        playerY + (halfTriHeight * coss(faceYaw - halfBaseLenAngle)),
                        sideLen, s
                    )
                end
            end
        end
    end
end)
