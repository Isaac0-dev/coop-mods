-- name: Crystal Caverns
-- description: This is a port of a short, one level romhack made for Simpleflips' 4th reimagined stages romhack competition.\n\nHazy Maze Cave is replaced with Crystal Caverns, where there are 7 stars to collect.\n\nCreated by luigiman0640\n\nPorted to coop by Isaac0-dev
-- incompatible: romhack

local warpPipeChild
local warpType = 0
local np = gNetworkPlayers[0]
local m = gMarioStates[0]

movtexqc_register("cc_1_Movtex_0", LEVEL_HMC, 1, 0)
movtexqc_register("cc_2_Movtex_0", LEVEL_HMC, 2, 0)
movtexqc_register("cc_2_Movtex_1", LEVEL_HMC, 2, 1)
movtexqc_register("cc_3_Movtex_0", LEVEL_HMC, 3, 0)
movtexqc_register("cc_4_Movtex_0", LEVEL_HMC, 4, 0)
movtexqc_register("cc_5_Movtex_0", LEVEL_HMC, 5, 0)

smlua_audio_utils_replace_sequence(0x26, 0x0E, 100, "05_Seq_cc_custom")
smlua_audio_utils_replace_sequence(0x25, 0x1A, 100, "06_Seq_cc_custom")
smlua_audio_utils_replace_sequence(0x16, 0x1A, 100, "16_Seq_cc_custom")
smlua_audio_utils_replace_sequence(0x23, 0x1A, 100, "23_Seq_cc_custom")
smlua_audio_utils_replace_sequence(0x24, 0x25, 100, "0C_Seq_cc_custom")

smlua_text_utils_course_acts_replace(COURSE_HMC, (" 6 CRYSTAL CAVERNS"), ("A VERY ''SIMPLE'' STAR"),
    ("DEEP WITHIN THE DUNGEON MAZE"), ("METAL MARIO'S GOT SOME HOT MOVES!"), ("SPELUNKING IN THE LAVA TEMPLE"),
    ("8 REDS IN THE DUNGEON MAZE"), ("SECRET OF THE CRYSTAL REALM"))


function on_object_interact(_, interactee)
    if np.currLevelNum == LEVEL_CASTLE_GROUNDS then
        if interactee == warpPipeChild then
            initiate_warp(LEVEL_HMC, 1, 0x0A, 0x00)
        end
    end
end

function on_level_init()
    if np.currLevelNum == LEVEL_CASTLE_GROUNDS then
        if warpType == 1 then
            m.pos.x = -5380
            m.pos.y = 800
            m.pos.z = -3907
            set_mario_action(m, ACT_DEATH_EXIT, 0)
            warpType = 0
        elseif warpType == 2 then
            m.pos.x = -5380
            m.pos.y = 800
            m.pos.z = -3907
            set_mario_action(m, ACT_EXIT_AIRBORNE, 0)
            warpType = 0
        end

        -- Spawn a Warp Pipe and a sign near the waterfall in the castle grounds.
        warpPipeChild = spawn_non_sync_object(id_bhvWarpPipe, E_MODEL_BITS_WARP_PIPE, -5380, 543, -3907, nil)

        spawn_non_sync_object(id_bhvMessagePanel, E_MODEL_WOODEN_SIGNPOST, -5037, 543, -3900, function(o)
            o.oFaceAngleYaw = 126
            o.oMoveAngleYaw = 126
            o.oBehParams2ndByte = DIALOG_051
        end)
    end

    if np.currLevelNum == LEVEL_HMC then
        camera_set_use_course_specific_settings(false)
    else
        camera_set_use_course_specific_settings(true)
    end
end

function mario_update()
    if np.currLevelNum == LEVEL_HMC then
        override_camera(m)

        if m.action == ACT_STAR_DANCE_EXIT or m.action == ACT_STAR_DANCE_WATER then
            warpType = 2
        end
    end
end

function on_pause_exit(usedExitToCastle)
    if np.currLevelNum == LEVEL_HMC then
        if not usedExitToCastle then
            warpType = 1
        end
    end
end

function on_death()
    if np.currLevelNum == LEVEL_HMC then
        warpType = 1
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_DEATH, on_death)
hook_event(HOOK_ON_INTERACT, on_object_interact)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_PAUSE_EXIT, on_pause_exit)
