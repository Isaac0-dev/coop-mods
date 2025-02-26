local cur_obj_update_floor_and_walls, obj_lava_death, bhv_bully_loop = cur_obj_update_floor_and_walls, obj_lava_death, bhv_bully_loop

function bhv_chilly_bully_init(o)
    o.oWallHitboxRadius = 100
end

function bhv_chilly_bully_loop(o)
    cur_obj_update_floor_and_walls()
    if o.oAction == BULLY_ACT_LAVA_DEATH then
        o.oBullyPrevX = o.oPosX
        o.oBullyPrevY = o.oPosY
        o.oBullyPrevZ = o.oPosZ

        if obj_lava_death() == 1 then
            cur_obj_spawn_star_at_y_offset(1159.0, 3000.0, 567.0, 0)
        end

        set_object_visibility(o, 3000)
    else
        bhv_bully_loop()
    end
end

-- Fix hidden money bags models
hook_behavior(id_bhvMoneybagHidden, OBJ_LIST_LEVEL, false, function (o)
    obj_set_model_extended(o, E_MODEL_YELLOW_COIN)
end, nil)
