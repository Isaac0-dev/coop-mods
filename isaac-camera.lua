-- name: Isaac0-dev's Camera
-- description: Some people asked for it, so here it is.\nShoutouts to OMM.

local math_min, math_max, math_abs, math_sqrt, coss, sins, atan2s, vec3f_copy, vec3f_normalize, vec3f_mul, math_floor =
    math.min, math.max, math.abs, math.sqrt, coss, sins, atan2s, vec3f_copy, vec3f_normalize, vec3f_mul, math.floor
local is_game_paused, approach_s32, find_floor_height, vec3f_set_dist_and_angle, collision_find_surface_on_ray, vec3f_project, vec3f_sub, camera_config_is_free_cam_enabled =
    is_game_paused, approach_s32, find_floor_height, vec3f_set_dist_and_angle, collision_find_surface_on_ray,
    vec3f_project, vec3f_sub, camera_config_is_free_cam_enabled

local m0 = gMarioStates[0]
local ls = gLakituState

local bool_to_number = { [true] = 1, [false] = 0 }

-- TODO
-- Camera offset look underneath
-- change to mario cam is too slow... make it optional?

local sOverrideCameraModes = {
    [CAMERA_MODE_BEHIND_MARIO]      = true,
    [CAMERA_MODE_WATER_SURFACE]     = true,
    [CAMERA_MODE_RADIAL]            = true,
    [CAMERA_MODE_OUTWARD_RADIAL]    = true,
    [CAMERA_MODE_CLOSE]             = true,
    [CAMERA_MODE_SLIDE_HOOT]        = true,
    [CAMERA_MODE_PARALLEL_TRACKING] = true,
    [CAMERA_MODE_FIXED]             = true,
    [CAMERA_MODE_FREE_ROAM]         = true,
    [CAMERA_MODE_SPIRAL_STAIRS]     = true,
    [CAMERA_MODE_ROM_HACK]          = true,
    [CAMERA_MODE_8_DIRECTIONS]      = true,
}

local CAM_DELTA_ANGLE = 0x2000
local sCamDistMode = 2
local sCamPitch = 0x0C00
local sCamYaw = 0
local sCamYawTarget = 0
local RTriggerCounter = 0
local RTriggerCounter2 = 0
local keepCliffCam = false

local camSpeedTable = {
    [0.5] = "SLOWEST",
    [1] = "SLOW",
    [1.5] = "MEDIUM",
    [2] = "FAST",
    [3.5] = "FASTEST",
}
local camSpeedSelection = 1.5

local sCameraDistances = {
    [0] = 400,
    [1] = 800,
    [2] = 1200,
    [3] = 1600,
    [4] = 2000,
    [5] = 3000,
}

local sCamDistance = sCameraDistances[sCamDistMode]

local function degrees(x)
    return (x) * 0x10000 / 360
end

local function s16(x)
    x = (math.floor(x) & 0xFFFF)
    if x >= 32768 then return x - 65536 end
    return x
end

local function approach(number, target, inc)
    return target - approach_s32(s16(target - number), 0, inc, inc)
end

local function get_nearest_dir_angle(val)
    local va = val + 0x10000
    local da = CAM_DELTA_ANGLE
    local a0 = (((va / da) + 0) * da)
    local a1 = (((va / da) + 1) * da)
    local d0 = math_abs(va - a0)
    local d1 = math_abs(va - a1)
    return d0 == math_min(d0, d1) and s16(a0) or s16(a1)
end

local function vec3f_get_dist_and_angle(from, to)
    local x = to.x - from.x
    local y = to.y - from.y
    local z = to.z - from.z
    return math_sqrt(x * x + y * y + z * z), atan2s(math_sqrt(x * x + z * z), y), atan2s(z, x)
end

local function vec3f_rotate_zxy(v, pitch, yaw, roll)
    local sx = sins(pitch)
    local cx = coss(pitch)
    local sy = sins(yaw)
    local cy = coss(yaw)
    local sz = sins(roll)
    local cz = coss(roll)
    local sysz = (sy * sz)
    local cycz = (cy * cz)
    local cysz = (cy * sz)
    local sycz = (sy * cz)
    local mtx00 = ((sysz * sx) + cycz)
    local mtx01 = (cx * sz)
    local mtx02 = ((cysz * sx) - sycz)
    local mtx10 = ((sycz * sx) - cysz)
    local mtx11 = (cx * cz)
    local mtx12 = ((cycz * sx) + sysz)
    local mtx20 = (cx * sy)
    local mtx21 = -sx
    local mtx22 = (cx * cy)
    local w = {
        x = v.x * mtx00 + v.y * mtx10 + v.z * mtx20,
        y = v.x * mtx01 + v.y * mtx11 + v.z * mtx21,
        z = v.x * mtx02 + v.y * mtx12 + v.z * mtx22,
    }
    return w
end

local function camera_can_see_mario(pos)
    -- Floor
    local floorY = find_floor_height(pos.x, pos.y, pos.z)
    if floorY <= gLevelValues.floorLowerLimit then
        return false
    end

    local mDist, mPitch, mYaw = vec3f_get_dist_and_angle(pos, m0.pos)

    for yawOffset = -1, 2 do
        for pitchOffset = -1, 2 do
            if not (math_abs(yawOffset) == 1 and math_abs(pitchOffset) == 1) then
                local target = { x = 0, y = 0, z = 0 }
                vec3f_set_dist_and_angle(pos, target, mDist, mPitch + degrees(pitchOffset), mYaw + degrees(yawOffset))

                target.y = target.y + 75

                local camdir = { x = target.x - pos.x, y = target.y - pos.y, z = target.z - pos.z }

                local wall = collision_find_surface_on_ray(pos.x, pos.y, pos.z, camdir.x, camdir.y, camdir.z)
                if wall.surface == nil then
                    return true
                end
            end
        end
    end

    return false
end

local function camera_process_collisions(pos, dir, dist)
    if camera_can_see_mario(pos) then return pos end
    pos.x = m0.pos.x
    pos.y = m0.pos.y + 150
    pos.z = m0.pos.z

    local movement = {
        x = dir.x * dist,
        y = dir.y * dist,
        z = dir.z * dist,
    }

    local wall = collision_find_surface_on_ray(pos.x, pos.y, pos.z, movement.x, movement.y, movement.z)
    if wall.surface ~= nil then
        local dirNorm = { x = 0, y = 0, z = 0 }
        vec3f_copy(dirNorm, dir)
        vec3f_normalize(dirNorm)

        local normal = {
            x = wall.surface.normal.x,
            y = wall.surface.normal.y,
            z = wall.surface.normal.z,
        }
        vec3f_project(dirNorm, normal, dir)
        dir.x = dirNorm.x - dir.x
        dir.y = dirNorm.y - dir.y
        dir.z = dirNorm.z - dir.z
        vec3f_normalize(dir)

        pos.x = wall.hitPos.x
        pos.y = wall.hitPos.y
        pos.z = wall.hitPos.z
        vec3f_mul(dirNorm, 5)
        vec3f_sub(pos, dirNorm)

        return wall.hitPos
    end

    pos.x = pos.x + movement.x
    pos.y = pos.y + movement.y
    pos.z = pos.z + movement.z
    return pos
end

local function camera_is_slide()
    if m0.floor.normal.y > 0.999 then
        return false
    end

    if m0.area and (m0.area.terrainType & TERRAIN_MASK) == TERRAIN_SLIDE then
        return true
    end

    return false
end

local function camera_update_angles_from_state()
    local maction = m0.action

    -- Flying
    if maction == ACT_FLYING or maction == ACT_SHOT_FROM_CANNON then
        sCamPitch = approach(sCamPitch, (-m0.faceAngle.x * 0.75) + 0xC00, math_max(m0.forwardVel, 4) * 0x20)
        sCamYaw = approach(sCamYaw, -m0.faceAngle.y - 0x4000, math_max(m0.forwardVel, 4) * 0x80)
        sCamYawTarget = sCamYaw
        return
    end

    -- Swimming
    if (maction & ACT_FLAG_SWIMMING) ~= 0 then
        sCamPitch = approach(sCamPitch, (-m0.faceAngle.x * 0.75) + 0xC00, math_max(m0.forwardVel, 4) * 0x20)
        sCamYaw = approach(sCamYaw, -m0.faceAngle.y - 0x4000, math_max(m0.forwardVel, 8) * 0x80)
        sCamYawTarget = sCamYaw
        return
    end

    -- Sliding
    if camera_is_slide() and ((maction & ACT_FLAG_BUTT_OR_STOMACH_SLIDE) ~= 0 or
            (maction == ACT_DIVE_SLIDE) or
            (maction == ACT_CROUCH_SLIDE) or
            (maction == ACT_SLIDE_KICK_SLIDE) or
            (maction == ACT_BUTT_SLIDE) or
            (maction == ACT_STOMACH_SLIDE) or
            (maction == ACT_HOLD_BUTT_SLIDE) or
            (maction == ACT_HOLD_STOMACH_SLIDE)) then
        sCamPitch = approach(sCamPitch, 0x0C00, 0x400)
        sCamYaw = approach(sCamYaw, -m0.faceAngle.y - 0x4000, math_max(m0.forwardVel, 4) * 0x80)
        sCamYawTarget = sCamYaw
        return
    end

    -- Airborne
    if (maction & ACT_FLAG_AIR) ~= 0 then
        sCamPitch = approach(sCamPitch, 0x0C00, 0x400)
        sCamYaw = approach(sCamYaw, sCamYawTarget, 0x800)
        return
    end

    sCamPitch = approach(sCamPitch, 0x0C00, 0x400)
    sCamYaw = approach(sCamYaw, sCamYawTarget, 0x800)
end

local function process_camera_inputs()
    local buttonPressed = m0.controller.buttonPressed
    local buttonDown = m0.controller.buttonDown
    local maction = m0.action

    if (buttonDown & R_TRIG) == 0 then
        -- If R is not held...

        -- 45º rotations
        if (buttonPressed & R_CBUTTONS) ~= 0 then
            play_sound_cbutton_side()
            sCamYawTarget = sCamYawTarget - 0x2000
        elseif (buttonPressed & L_CBUTTONS) ~= 0 then
            play_sound_cbutton_side()
            sCamYawTarget = sCamYawTarget + 0x2000
        end

        -- Zooms-in - C-up
        if (buttonPressed & U_CBUTTONS) ~= 0 then
            if sCamDistMode == 0 then
                play_sound_button_change_blocked()
            else
                play_sound_cbutton_up()
                sCamDistMode = sCamDistMode - 1
            end

            -- Zooms-out - C-down
        elseif (buttonPressed & D_CBUTTONS) ~= 0 then
            if sCamDistMode == #sCameraDistances then
                play_sound_button_change_blocked()
            else
                play_sound_cbutton_down()
                sCamDistMode = sCamDistMode + 1
            end
        end

        -- This centers the camera behind mario. It triggers when you let go of R in less than 5 frames.
        if RTriggerCounter > 0 and RTriggerCounter <= 5 and not ((buttonPressed & L_CBUTTONS) ~= 0 or (buttonPressed & R_CBUTTONS) ~= 0 or (maction & ACT_FLAG_SWIMMING_OR_FLYING) ~= 0) then
            sCamYawTarget = 0xC000 - m0.intendedYaw
            sCamYawTarget = get_nearest_dir_angle((sCamYawTarget / 0x2000) * 0x2000)
            play_sound_rbutton_changed()
        end
        RTriggerCounter = 0
    else
        -- If R is held...

        -- Smooth rotation with C-left and C-right and R
        if (buttonDown & L_CBUTTONS) ~= 0 then
            sCamYawTarget = sCamYawTarget - degrees(camSpeedSelection)
        elseif (buttonDown & R_CBUTTONS) ~= 0 then
            sCamYawTarget = sCamYawTarget + degrees(camSpeedSelection)
        end

        -- Hold C-up and R
        if (buttonDown & U_CBUTTONS) ~= 0 then
            keepCliffCam = true
        end

        RTriggerCounter = RTriggerCounter + 1
    end

    -- If keepCliffCam is already active, keep holding R or C-up
    if ((buttonDown & U_CBUTTONS) ~= 0 or (buttonDown & R_TRIG) ~= 0) and keepCliffCam then
        sCamPitch = degrees(60)
        keepCliffCam = true
    else
        keepCliffCam = false
    end

    -- Hold DPad down to lock the camera behind Mario
    if (buttonDown & D_JPAD) ~= 0 then
        sCamYawTarget = 0xC000 - m0.intendedYaw
    end

    -- Count down for 5 frames every time R is pressed
    -- If R is pressed again in between those 5 frames,
    -- switch to Mario cam (in HOOK_ON_CHANGE_CAMERA_ANGLE)
    RTriggerCounter2 = math_max(RTriggerCounter2 - 1, -1)
end

local function override_camera(m)
    if m.playerIndex ~= 0 then return end
    if camera_config_is_free_cam_enabled() then return end
    local mcam = m0.area.camera
    if mcam == nil then return end
    local camMode = mcam.mode
    local maction = m0.action

    if sOverrideCameraModes[camMode] ~= nil and not ((maction & ACT_FLAG_METAL_WATER) ~= 0 and (m0.flags & MARIO_METAL_CAP) ~= 0) then
        ls.mode = CAMERA_MODE_NONE
    end

    if mcam.cutscene == 0 and camMode == CAMERA_MODE_NONE then
        process_camera_inputs()

        local camDistTarget = sCameraDistances[sCamDistMode]
        local camPosOffsetY = 0
        local camFocOffsetY = 0

        -- Y offset, makes camera movement feel less cheap
        if (m0.action & ACT_FLAG_SWIMMING) == 0 then
            local floorHeight = m0.floorHeight
            if (m0.action & ACT_FLAG_METAL_WATER) == 0 then
                floorHeight = math_max(floorHeight, m0.waterLevel)
            end
            local offsetY = floorHeight - m0.pos.y
            camPosOffsetY = clamp(offsetY, -300, 300)
            camFocOffsetY = clamp(offsetY * 0.9, -300, 300)
        end

        -- Change the camera angles depending on Mario's current state
        camera_update_angles_from_state()

        -- Calculate camera focus
        ls.goalFocus.x = m0.pos.x
        ls.goalFocus.y = m0.pos.y + 120
        ls.goalFocus.z = m0.pos.z

        -- Calculate camera position
        sCamDistance = approach(sCamDistance, camDistTarget, 0x80)
        local v = { x = 0, y = 0, z = sCamDistance }
        v = vec3f_rotate_zxy(v, -(sCamPitch + ls.shakeMagnitude.x), (sCamYaw + ls.shakeMagnitude.y), 0)
        ls.goalPos.x = ls.goalFocus.x + coss(sCamYaw) * camDistTarget
        ls.goalPos.y = ls.goalFocus.y + v.y + camPosOffsetY
        ls.goalPos.z = ls.goalFocus.z + sins(sCamYaw) * camDistTarget

        local dir = {
            x = ls.goalPos.x - ls.goalFocus.x,
            y = ls.goalPos.y - (ls.goalFocus.y + camPosOffsetY),
            z = ls.goalPos.z - ls.goalFocus.z
        }
        vec3f_normalize(dir)

        -- Check for collision and apply the new camera position
        vec3f_copy(ls.pos, camera_process_collisions(ls.goalPos, dir, camDistTarget))

        ls.goalFocus.y = ls.goalFocus.y + camFocOffsetY

        vec3f_copy(ls.focus, ls.goalFocus)
        ls.yaw = 0x4000 - sCamYaw
        ls.nextYaw = ls.yaw

        sCamPitch = s16(sCamPitch)
        sCamYaw = s16(sCamYaw)
        sCamYaw = s16(sCamYawTarget)
    end
end

local function camera_init()
    sCamPitch = 0x0C00
    sCamDistMode = 2
    sCamYaw = 0xC000 - m0.intendedYaw
    sCamYaw = get_nearest_dir_angle((sCamYaw / 0x2000) * 0x2000 + 0x2000)

    sCamYawTarget = sCamYaw
    camera_set_use_course_specific_settings(0)
end

local function on_set_camera_mode(_, mode, _)
    if mode == CAMERA_MODE_NONE or camera_config_is_free_cam_enabled() then return true end

    if sOverrideCameraModes[mode] then
        ls.mode = CAMERA_MODE_NONE
        return false
    end
end

local function chat_commands(msg)
    local v = string.find(msg, "%s ")
    local v2 = string.find(msg, " %s")
    -- djui_chat_message_create(v)
    -- return true
    if v == "speed" then
        local n = tonumber(v2)
        if n and camSpeedTable[n] then
            camSpeedSelection = n
            djui_chat_message_create("Set the camera speed to " .. camSpeedTable[n])
            return true
        end
        djui_chat_message_create("Invalid camera speed")
        return false
    elseif v == "col" then
    end
end

hook_event(HOOK_ON_SET_CAMERA_MODE, on_set_camera_mode)
hook_event(HOOK_ON_LEVEL_INIT, camera_init)
hook_event(HOOK_MARIO_UPDATE, override_camera)
hook_event(HOOK_ON_CHANGE_CAMERA_ANGLE, function(type)
    if type == CAM_ANGLE_MARIO and not camera_config_is_free_cam_enabled() and not (RTriggerCounter2 > -1 and RTriggerCounter2 < 6) then
        RTriggerCounter2 = 6
        return false
    end
end)
hook_chat_command("camSettings", "change camera settings", chat_commands)
