local sOverrideCameraModes = {
    [CAMERA_MODE_RADIAL]            = true,
    [CAMERA_MODE_OUTWARD_RADIAL]    = true,
    [CAMERA_MODE_CLOSE]             = true,
    [CAMERA_MODE_SLIDE_HOOT]        = true,
    [CAMERA_MODE_PARALLEL_TRACKING] = true,
    [CAMERA_MODE_FIXED]             = true,
    [CAMERA_MODE_8_DIRECTIONS]      = true,
    [CAMERA_MODE_FREE_ROAM]         = true,
    [CAMERA_MODE_SPIRAL_STAIRS]     = true,
}

function override_camera(m)
    local np = gNetworkPlayers[0]

    if sOverrideCameraModes[m.area.camera.mode] == nil or np.currLevelNum == LEVEL_BOWSER_1 or np.currLevelNum == LEVEL_BOWSER_2 or np.currLevelNum == LEVEL_BOWSER_3 then
        return
    end

    set_camera_mode(m.area.camera, CAMERA_MODE_ROM_HACK, 0)
end

local function on_set_camera_mode(c, mode, frames)
    if sOverrideCameraModes[mode] ~= nil and mode ~= CAMERA_MODE_ROM_HACK then
        -- do not allow change
        set_camera_mode(c, CAMERA_MODE_ROM_HACK, frames)
        return false
    end
end

hook_event(HOOK_ON_SET_CAMERA_MODE, on_set_camera_mode)
