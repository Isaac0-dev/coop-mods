-- name: SM64: The Green Stars
-- description: This is a port of Super Mario 64: The Green Stars.\n\nThere are 130 stars to collect.\n\nCreated by Kampel125\n\nPorted to coop by Isaac0-dev
-- incompatible: romhack

-- unoptimized, just terrible code in general

local m = gMarioStates[0]
local fov = 50
local pipe
local hudVisible = false

movtexqc_register("bob_1_Movtex_0", LEVEL_BOB, 1, 0)
movtexqc_register("wf_1_Movtex_0", LEVEL_WF, 1, 0)
movtexqc_register("jrb_1_Movtex_0", LEVEL_JRB, 1, 0)
movtexqc_register("ccm_1_Movtex_0", LEVEL_CCM, 1, 0)
movtexqc_register("bbh_1_Movtex_0", LEVEL_BBH, 1, 0)
movtexqc_register("bbh_2_Movtex_0", LEVEL_BBH, 2, 0)
movtexqc_register("hmc_1_Movtex_0", LEVEL_HMC, 1, 0)
movtexqc_register("lll_1_Movtex_0", LEVEL_LLL, 1, 0)
movtexqc_register("lll_2_Movtex_0", LEVEL_LLL, 2, 0)
movtexqc_register("ssl_1_Movtex_0", LEVEL_SSL, 1, 0)
movtexqc_register("ssl_2_Movtex_0", LEVEL_SSL, 2, 0)
movtexqc_register("ddd_1_Movtex_0", LEVEL_DDD, 1, 0)
movtexqc_register("ddd_2_Movtex_0", LEVEL_DDD, 2, 0)
movtexqc_register("ddd_3_Movtex_0", LEVEL_DDD, 3, 0)
movtexqc_register("sl_1_Movtex_0", LEVEL_SL, 1, 0)
movtexqc_register("sl_2_Movtex_0", LEVEL_SL, 2, 0)
movtexqc_register("ttm_1_Movtex_0", LEVEL_TTM, 1, 0)
movtexqc_register("thi_1_Movtex_0", LEVEL_THI, 1, 0)
movtexqc_register("thi_2_Movtex_0", LEVEL_THI, 2, 0)
movtexqc_register("rr_1_Movtex_0", LEVEL_RR, 1, 0)
movtexqc_register("pss_1_Movtex_0", LEVEL_PSS, 1, 0)
movtexqc_register("wdw_1_Movtex_0", LEVEL_WDW, 1, 0)
movtexqc_register("sa_1_Movtex_0", LEVEL_SA, 1, 0)
movtexqc_register("sa_2_Movtex_0", LEVEL_SA, 2, 0)
movtexqc_register("wmotr_1_Movtex_0", LEVEL_WMOTR, 1, 0)
movtexqc_register("totwc_1_Movtex_0", LEVEL_TOTWC, 1, 0)
movtexqc_register("vcutm_1_Movtex_0", LEVEL_VCUTM, 1, 0)
movtexqc_register("cotmc_1_Movtex_0", LEVEL_COTMC, 1, 0)
movtexqc_register("bitdw_1_Movtex_0", LEVEL_BITDW, 1, 0)
movtexqc_register("bitfs_1_Movtex_0", LEVEL_BITFS, 1, 0)
movtexqc_register("bowser_1_Movtex_0", LEVEL_BOWSER_1, 1, 0)
movtexqc_register("bowser_2_Movtex_0", LEVEL_BOWSER_2, 1, 0)
movtexqc_register('castle_courtyard_1_Movtex_0', 22 + 4, 1, 0)

smlua_audio_utils_replace_sequence(0x01, 0x22, 70, "01_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x02, 0x25, 70, "02_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x03, 0x11, 70, "03_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x04, 0x25, 70, "04_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x05, 0x25, 70, "05_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x06, 0x11, 70, "06_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x07, 0x19, 70, "07_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x08, 0x25, 70, "08_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x09, 0x11, 70, "09_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x0A, 0x21, 70, "0A_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x0B, 0x14, 70, "0B_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x0C, 0x15, 70, "0C_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x0D, 0x25, 70, "0D_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x0E, 0x25, 70, "0E_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x0F, 0x18, 70, "0F_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x10, 0x12, 70, "10_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x11, 0x25, 70, "11_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x12, 0x1F, 70, "12_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x13, 0x11, 70, "13_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x14, 0x1A, 70, "14_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x15, 0x0E, 70, "15_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x16, 0x1B, 70, "16_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x17, 0x1A, 70, "17_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x18, 0x25, 70, "18_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x19, 0x1A, 70, "19_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x1A, 0x25, 70, "1A_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x1B, 0x14, 70, "1B_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x1C, 0x20, 70, "1C_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x1D, 0x1E, 70, "1D_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x1E, 0x1B, 70, "1E_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x1F, 0x1A, 70, "1F_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x20, 0x23, 70, "20_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x21, 0x25, 70, "21_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x23, 0x25, 70, "23_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x24, 0x1B, 70, "24_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x25, 0x11, 70, "25_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x26, 0x25, 70, "26_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x27, 0x25, 70, "27_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x28, 0x25, 70, "28_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x29, 0x19, 70, "29_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x2A, 0x25, 70, "2A_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x2B, 0x25, 70, "2B_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x2C, 0x25, 70, "2C_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x2D, 0x25, 70, "2D_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x2E, 0x19, 70, "2E_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x2F, 0x25, 70, "2F_Seq_GS_custom")
smlua_audio_utils_replace_sequence(0x30, 0x25, 70, "30_Seq_GS_custom")

gServerSettings.skipIntro = 1
starPositions = gLevelValues.starPositions

vec3f_set(starPositions.KoopaBobStarPos, 4920.0, -625.0, -5115.0)
vec3f_set(starPositions.KoopaThiStarPos, 4920.0, -625.0, -5115.0)
vec3f_set(starPositions.KingBobombStarPos, -4421.0, 2199.0, -2482.0)
vec3f_set(starPositions.KingWhompStarPos, 5720.0, 677.0, -5079.0)
vec3f_set(starPositions.EyerockStarPos, 527.0, -6742.0, 380.0)
vec3f_set(starPositions.BigBullyTrioStarPos, 3208.0, 1036.0, 5583.0)
vec3f_set(starPositions.ChillBullyStarPos, 130.0, 1600.0, -4335.0)
vec3f_set(starPositions.BigPiranhasStarPos, 6423.0, -104.0, -5111.0)
vec3f_set(starPositions.TuxieMotherStarPos, -4909.0, 60.0, -2527.0)
vec3f_set(starPositions.WigglerStarPos, -60.0, 3646.0, 8111.0)
vec3f_set(starPositions.PssSlideStarPos, 5377.0, -2050.0, 7890.0)
vec3f_set(starPositions.RacingPenguinStarPos, -7339.0, -5700.0, -6774.0)
vec3f_set(starPositions.TreasureChestStarPos, -1800.0, -2500.0, -1700.0)
vec3f_set(starPositions.GhostHuntBooStarPos, 980.0, 1100.0, 250.0)
vec3f_set(starPositions.KleptoStarPos, -5550.0, 300.0, -930.0)
vec3f_set(starPositions.MerryGoRoundStarPos, 6983.0, 1877.0, 4204.0)
vec3f_set(starPositions.MrIStarPos, -4714.0, 5305.0, 1757.0)
vec3f_set(starPositions.BalconyBooStarPos, 1757.0, 7240.0, -690.0)
vec3f_set(starPositions.BigBullyStarPos, 4748.0, -260.0, -5441.0)

gBehaviorValues.trajectories.KoopaBobTrajectory            = get_trajectory('KoopaBoB_path')
gBehaviorValues.trajectories.KoopaThiTrajectory            = get_trajectory('KoopaTHI_path')
gBehaviorValues.trajectories.PlatformRrTrajectory          = get_trajectory('rr_seg7_trajectory_0702EC3C_RM2C_path')
gBehaviorValues.trajectories.PlatformRr2Trajectory         = get_trajectory('rr_seg7_trajectory_0702ECC0_RM2C_path')
gBehaviorValues.trajectories.PlatformCcmTrajectory         = get_trajectory('ccm_seg7_trajectory_0701669C_RM2C_path')
gBehaviorValues.trajectories.PlatformBitfsTrajectory       = get_trajectory('bitfs_seg7_trajectory_070159AC_RM2C_path')
gBehaviorValues.trajectories.PlatformHmcTrajectory         = get_trajectory('hmc_seg7_trajectory_0702B86C_RM2C_path')
gBehaviorValues.trajectories.PlatformLllTrajectory         = get_trajectory('lll_seg7_trajectory_0702856C_RM2C_path')
gBehaviorValues.trajectories.PlatformLll2Trajectory        = get_trajectory('lll_seg7_trajectory_07028660_RM2C_path')
gBehaviorValues.trajectories.PlatformRr3Trajectory         = get_trajectory('rr_seg7_trajectory_0702ED9C_RM2C_path')
gBehaviorValues.trajectories.PlatformRr4Trajectory         = get_trajectory('rr_seg7_trajectory_0702EEE0_RM2C_path')
gBehaviorValues.trajectories.RacingPenguinTrajectory       = get_trajectory('ccm_seg7_trajectory_penguin_race_RM2C_path')
gBehaviorValues.trajectories.BowlingBallBobTrajectory      = get_trajectory('ttc_bowling_ball_path')
gBehaviorValues.trajectories.BowlingBallThiLargeTrajectory = get_trajectory('bob_bowling_ball_path')

gLevelValues.entryLevel             = LEVEL_CASTLE_GROUNDS
gLevelValues.exitCastleLevel        = LEVEL_CASTLE_GROUNDS
gLevelValues.exitCastleWarpNode     = 243
gLevelValues.skipCreditsAt          = LEVEL_CASTLE_GROUNDS
gLevelValues.pssSlideStarTime       = 1050
gLevelValues.wingCapDuration        = 2700
gLevelValues.metalCapDuration       = 900
gLevelValues.vanishCapDuration      = 900
gLevelValues.wingCapDurationTotwc   = 1800
gLevelValues.metalCapDurationCotmc  = 900
gLevelValues.vanishCapDurationVcutm = 900
gBehaviorValues.KoopaBobAgility     = 4.0
gBehaviorValues.KoopaCatchupAgility = 8.0
gBehaviorValues.KoopaThiAgility     = 6.0

hud_hide()
camera_set_use_course_specific_settings(false)

local function mario_update()
    override_camera(m)
end

local function update()
    if obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil or (m.action == ACT_END_PEACH_CUTSCENE or m.action == ACT_CREDITS_CUTSCENE or m.action == ACT_END_WAVING_CUTSCENE) then

        if fov > 45 then
            set_override_fov(45)
        end

        hudVisible = false
        return
    end

    if (m.controller.buttonPressed & R_TRIG) ~= 0 then
        play_sound(SOUND_MENU_CLICK_CHANGE_VIEW, m.marioObj.header.gfx.cameraToObject)
    end

    if (m.controller.buttonDown & R_TRIG) ~= 0 then
        hudVisible = true
    else
        hudVisible = false
    end

    if (m.controller.buttonDown & L_TRIG) ~= 0 then
        fov = 65
    end

    if fov > 45 then
        fov = fov - 1
        set_override_fov(fov)
    end
end

local function on_object_interact(_, interactee)
    if interactee == pipe then
        initiate_warp(LEVEL_WMOTR, 1, 0x0A, 0x00)
    end
end

local function bhv_warp_pipe_spawner()
    local starCount = save_file_get_total_star_count(get_current_save_file_num() - 1, 0, 24)
    if starCount >= 130 then
        pipe = spawn_non_sync_object(id_bhvWarpPipe, E_MODEL_BITS_WARP_PIPE, -2000, -546, -672, nil)
    end
end

bhvPipeSpawner = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_warp_pipe_spawner, nil)

-- awful way to do this, don't copy off me
local function on_hud_render()
    local np = gNetworkPlayers[m.playerIndex]
    djui_hud_set_font(FONT_HUD)
    djui_hud_set_resolution(RESOLUTION_N64)

    local scale = 1
    local sStarSelectCourse = np.currCourseNum - COURSE_MIN
    local starFlags = save_file_get_star_flags(get_current_save_file_num() - 1, sStarSelectCourse)
    local starCount = save_file_get_course_star_count(get_current_save_file_num() - 1, sStarSelectCourse)
    local nextStar = 0
    local hasStar = 0
    local text = ""

    while hasStar < starCount do
        if starFlags & (1 << nextStar) ~= 0 then
            text = text .. "*"
            hasStar = hasStar + 1
        else
            text = text .. "x"
            hasStar = hasStar + 1
        end
        nextStar = nextStar + 1
    end

    if (starFlags & 0x40) then
        starCount = starCount -1
        text = text .. "*"
    end

    while hasStar < starCount do
        if starFlags & (1 << nextStar) ~= 0 then
            text = text .. "*"
            hasStar = hasStar + 1
        else
            text = text .. "x"
        end
        nextStar = nextStar + 1
    end

    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local width = (djui_hud_measure_text(text) + 8) * scale
    local x = (screenWidth - width) / 2.0 * scale
    local y = (screenHeight * 0.6) / 2.0

    if djui_hud_is_pause_menu_created() then
        -- if get_dialog_box_state() ~= 0 and is_game_paused() then
        djui_hud_set_color(127.5, 127.5, 127.5, 255)
    else
        djui_hud_set_color(255, 255, 255, 255)
    end

    if hudVisible then
        hud_show()
        hud_set_value(HUD_DISPLAY_FLAGS_CAMERA_AND_POWER, 0)
        hud_set_value(HUD_DISPLAY_LIVES, 0)

        if (m.flags & MARIO_METAL_CAP) ~= 0 or (m.flags & MARIO_WING_CAP) ~= 0 or (m.flags & MARIO_VANISH_CAP) ~= 0 then
            if m.action ~= ACT_JUMBO_STAR_CUTSCENE then
                djui_hud_print_text(string.format("CAP TIME  %.0f", m.capTimer), x + 40 * scale, y + 133, scale)
            end
        end
        djui_hud_print_text(string.format(text), x - 130 * scale, y + 133, scale)
    else
        hud_hide()
    end
end

hook_event(HOOK_ON_HUD_RENDER_BEHIND, on_hud_render)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_INTERACT, on_object_interact)
hook_event(HOOK_ON_CHANGE_CAMERA_ANGLE, function(mode)if mode == CAM_ANGLE_MARIO then return false end end)
hook_event(HOOK_UPDATE, update)
