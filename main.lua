-- name: The Phantom's Call
-- description: This is a port of The Phantom's Call.\n\nThere are 30 stars to collect in 4 small courses.\n\nCreated by PhantomPhire\n\nPorted to coop by Isaac0-dev
-- incompatible: romhack

smlua_audio_utils_replace_sequence(0x01, 0x13, 100, "01_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x02, 0x25, 100, "02_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x03, 0x25, 100, "03_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x04, 0x25, 100, "04_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x05, 0x25, 100, "05_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x06, 0x17, 100, "06_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x08, 0x1A, 100, "08_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x0A, 0x15, 100, "0A_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x0B, 0x14, 100, "0B_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x0C, 0x1A, 100, "0C_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x0D, 0x0B, 100, "0D_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x0E, 0x1A, 100, "0E_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x0F, 0x25, 100, "0F_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x09, 0x25, 100, "09_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x10, 0x12, 100, "10_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x12, 0x17, 100, "12_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x13, 0x25, 100, "13_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x14, 0x1A, 100, "14_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x15, 0x0E, 100, "15_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x16, 0x25, 100, "16_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x17, 0x1A, 100, "17_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x1A, 0x1A, 100, "1A_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x1B, 0x14, 100, "1B_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x1C, 0x20, 100, "1C_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x1D, 0x1E, 100, "1D_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x1E, 0x1B, 100, "1E_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x1F, 0x1A, 100, "1F_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x20, 0x23, 100, "20_Seq_phantom_custom")
smlua_audio_utils_replace_sequence(0x21, 0x25, 100, "21_Seq_phantom_custom")

movtexqc_register('castle_grounds_1_Movtex_0', 16, 1, 0)
movtexqc_register("bob_1_Movtex_0", 9, 1, 0)
movtexqc_register("wf_1_Movtex_1", 24, 1, 1)
movtexqc_register("jrb_1_Movtex_0", 12, 1, 0)
movtexqc_register("ccm_2_Movtex_0", 5, 2, 0)
movtexqc_register("totwc_1_Movtex_0", 29, 1, 0)

gServerSettings.skipIntro = 1
starPositions = gLevelValues.starPositions

vec3f_set(starPositions.TuxieMotherStarPos, 2174.0, 1860.0, 1639.0)
vec3f_set(starPositions.KoopaBobStarPos, -13167, -1650, -5734)
vec3f_set(starPositions.KingWhompStarPos, -854.0, 1110.0, 6003.0)

camera_set_use_course_specific_settings(false)

gLevelValues.entryLevel               = LEVEL_CASTLE_GROUNDS
gLevelValues.exitCastleLevel          = LEVEL_CASTLE
gLevelValues.exitCastleWarpNode       = 10
gLevelValues.skipCreditsAt            = LEVEL_CASTLE_GROUNDS
gLevelValues.coinsRequiredForCoinStar = 200

gBehaviorValues.trajectories.KoopaBobTrajectory = get_trajectory('KoopaBoB_path')

-- Stop Mario from sliding while the dialog box is open in "A Shocking Twist"
local function fix_dialog_099(m, act)
    if m.playerIndex ~= 0 then return end
    if get_dialog_id() == DIALOG_099 and act ~= ACT_READING_AUTOMATIC_DIALOG and m.action ~= ACT_READING_AUTOMATIC_DIALOG then
        return ACT_READING_AUTOMATIC_DIALOG
    end
end

hook_event(HOOK_BEFORE_SET_MARIO_ACTION, fix_dialog_099)
