function bhv_custom_big_bully_init(o)
    o.oFlags = 9
    o.oAnimations = gObjectAnimations.bully_seg5_anims_0500470C
    o.oWallHitboxRadius = 100
    cur_obj_update_floor_and_walls();

    cur_obj_init_animation(0)
    bhv_big_bully_init()
end

function bhv_custom_bully_loop(o)
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

bhvCustomBigChillBully = hook_behavior(id_bhvBigChillBully, OBJ_LIST_GENACTOR, true, bhv_custom_big_bully_init,
    bhv_custom_bully_loop)
