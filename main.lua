-- name: Star Colors
-- description: Change the Star color depending on what level you are in.

local object

local switch = {
    [0] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star0_geo"))
    end,
    [1] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star1_geo"))
    end,
    [2] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star2_geo"))
    end,
    [3] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star3_geo"))
    end,
    [4] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star4_geo"))
    end,
    [5] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star5_geo"))
    end,
    [6] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star6_geo"))
    end,
    [7] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star7_geo"))
    end,
    [8] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star8_geo"))
    end,
    [9] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star9_geo"))
    end,
    [10] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star10_geo"))
    end,
    [11] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star11_geo"))
    end,
    [12] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star12_geo"))
    end,
    [13] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star13_geo"))
    end,
    [14] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star14_geo"))
    end,
    [15] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star15_geo"))
    end,
    [16] = function()
        obj_set_model_extended(object, smlua_model_util_get_id("star16_geo"))
    end,
    default = function() end
}

-- runs whenever a star is spawned
function bhv_color_star(o)
    -- if the star isn't transparent, change it's color
    if obj_has_model_extended(o, E_MODEL_TRANSPARENT_STAR) == 0 then
        object = o
        -- force the current level number to be from 0-16, and then set the star color
        switch[math.max(0, math.min(16, gNetworkPlayers[0].currCourseNum))]()
    end
end

hook_behavior(id_bhvStar, OBJ_LIST_LEVEL, false, bhv_color_star, nil)
hook_behavior(id_bhvActSelectorStarType, OBJ_LIST_LEVEL, false, bhv_color_star, nil)
hook_behavior(id_bhvCelebrationStar, OBJ_LIST_LEVEL, false, bhv_color_star, nil)
hook_behavior(id_bhvSpawnedStar, OBJ_LIST_LEVEL, false, bhv_color_star, nil)
hook_behavior(id_bhvSpawnedStarNoLevelExit, OBJ_LIST_LEVEL, false, bhv_color_star, nil)
hook_behavior(id_bhvHiddenRedCoinStar, OBJ_LIST_LEVEL, false, bhv_color_star, nil)
hook_behavior(id_bhvStarSpawnCoordinates, OBJ_LIST_LEVEL, false, bhv_color_star, nil)
