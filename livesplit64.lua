-- name: ! LiveSplit 64
-- description: LiveSplit + an auto splitter for coop
-- pausable: false

-- Edit `livesplit64.sav` in your appdata folder to configure splits.
-- You can only fit as much into a configuration as mod storage supports

local math_min, math_max, math_floor, math_ceil, math_abs, math_sqrt, coss, sins, atan2s, vec3f_copy, vec3f_normalize, vec3f_dot, vec3f_mul, vec3f_dif, vec3f_length, vec3f_rotate_zxy, clamp =
      math.min, math.max, math.floor, math.ceil, math.abs, math.sqrt, coss, sins, atan2s, vec3f_copy, vec3f_normalize, vec3f_dot, vec3f_mul, vec3f_dif, vec3f_length, vec3f_rotate_zxy, clamp

local string_format = string.format

local pairs, ipairs, djui_hud_print_text, djui_hud_render_rect, djui_hud_set_color, network_local_index_from_global, network_global_index_from_local, network_is_server, djui_hud_measure_text =
      pairs, ipairs, djui_hud_print_text, djui_hud_render_rect, djui_hud_set_color, network_local_index_from_global, network_global_index_from_local, network_is_server, djui_hud_measure_text
local djui_hud_set_resolution = djui_hud_set_resolution
local djui_hud_get_screen_width = djui_hud_get_screen_width
local djui_hud_get_screen_height = djui_hud_get_screen_height
local djui_hud_set_font = djui_hud_set_font

local sLiveSplitSettings = {}

local function storage_save(key, value)
    if network_is_server() then
        mod_storage_save(key, value)
    end
end
local function storage_load(key)
    if network_is_server() then
        return mod_storage_load(key)
    end
end

local sMenuX = tonumber(mod_storage_load("menuX")) or 0
local sMenuY = tonumber(mod_storage_load("menuY")) or 0

local function throw_error(str)
    local errStr = "LiveSplit64: " .. str
    log_to_console(errStr)
    print(errStr)

    hook_event(HOOK_ON_HUD_RENDER, function ()
        djui_hud_set_font(FONT_NORMAL)
        djui_hud_set_resolution(RESOLUTION_N64)
        djui_hud_set_rotation(0, 0, 0)

        local x = sMenuX
        local w = 50
        local h = 95

        djui_hud_set_color(0x00, 0x00, 0x00, 0x9F)
        djui_hud_render_rect(x, sMenuY, w + 1, h + 10)

        local text = "Error, see console"
        local len = djui_hud_measure_text(text) * 0.2
        djui_hud_print_text(text, x + ((w - len) / 2), sMenuY + (h / 2), 0.2)
    end)
end

local error = false
if network_is_server() then
    local function load_variable(name, isNumber, table, saveStr)
        if error then return end
        local var = storage_load(name)
        if not var then return end
        if not table then table = sLiveSplitSettings end
        if not saveStr then saveStr = name end
        table[saveStr] = isNumber and tonumber(var) or var
    end

    -- These are variables that are required for the mod to run
    load_variable("settings",        false)
    load_variable("numberOfPlayers", true)

    if sLiveSplitSettings.numberOfPlayers then
        for num = 1, sLiveSplitSettings.numberOfPlayers do
            sLiveSplitSettings[num] = {}
            load_variable("numberOfSplits" .. tostring(num), true, sLiveSplitSettings[num], "numberOfSplits")
            if sLiveSplitSettings[num].numberOfSplits then
                if sLiveSplitSettings[num].numberOfSplits < 0 then
                    throw_error("Invalid number of splits " .. sLiveSplitSettings[num].numberOfSplits)
                    return
                end
            else
                sLiveSplitSettings[num].numberOfSplits = 0
            end
        end
    else
        sLiveSplitSettings.numberOfPlayers = 0
    end

    if error then return end

    if sLiveSplitSettings.numberOfPlayers < 0 or sLiveSplitSettings.numberOfPlayers >= MAX_PLAYERS then
        throw_error("Invalid number of players " .. sLiveSplitSettings.numberOfPlayers)
        return
    end
end

local courseToLevel = {
    [COURSE_NONE] = LEVEL_NONE,
    [COURSE_BOB] = LEVEL_BOB,
    [COURSE_WF] = LEVEL_WF,
    [COURSE_JRB] = LEVEL_JRB,
    [COURSE_CCM] = LEVEL_CCM,
    [COURSE_BBH] = LEVEL_BBH,
    [COURSE_HMC] = LEVEL_HMC,
    [COURSE_LLL] = LEVEL_LLL,
    [COURSE_SSL] = LEVEL_SSL,
    [COURSE_DDD] = LEVEL_DDD,
    [COURSE_SL] = LEVEL_SL,
    [COURSE_WDW] = LEVEL_WDW,
    [COURSE_TTM] = LEVEL_TTM,
    [COURSE_THI] = LEVEL_THI,
    [COURSE_TTC] = LEVEL_TTC,
    [COURSE_RR] = LEVEL_RR,
    [COURSE_BITDW] = LEVEL_BITDW,
    [COURSE_BITFS] = LEVEL_BITFS,
    [COURSE_BITS] = LEVEL_BITS,
    [COURSE_PSS] = LEVEL_PSS,
    [COURSE_COTMC] = LEVEL_COTMC,
    [COURSE_TOTWC] = LEVEL_TOTWC,
    [COURSE_VCUTM] = LEVEL_VCUTM,
    [COURSE_WMOTR] = LEVEL_WMOTR,
    [COURSE_SA] = LEVEL_SA,
    [COURSE_CAKE_END] = LEVEL_ENDING,
}

local function course_to_level(course)
    return courseToLevel[course] or LEVEL_NONE
end

local levelToCourse = {}
for k, v in pairs(courseToLevel) do
    levelToCourse[v] = k
end

local function level_to_course(level)
    return levelToCourse[level] or COURSE_NONE
end

local sSplits = {}

local SPLIT_PAUSE_EXIT = 0
local SPLIT_BOWSER     = 1
local SPLIT_STAR       = 2
local SPLIT_STAR_EXIT  = 3
local SPLIT_COUNT      = SPLIT_STAR_EXIT

local SPLIT_MENU_RUN       = -1
local SPLIT_MENU_MAIN      = 0
local SPLIT_MENU_SETTINGS  = 1
local SPLIT_MENU_ADD_SPLIT = 2
local SPLIT_MENU_EDIT      = 3

local sSplitMenu = SPLIT_MENU_RUN
local sSplitEdit = nil
local sSplitEditSegmentNum = 0

local function get_abbreviated_level_name(levelNum)
    local levelName = get_level_name(level_to_course(levelNum), levelNum, 0)
    if not levelName then return "" end

    -- Level abbreviation
    local levelStr = ""
    for word in levelName:upper():gmatch("[^ %-%s]+") do
        local firstLetter = word:match("^(%a)")
        if firstLetter then levelStr = levelStr .. firstLetter end
    end
    if levelNum == LEVEL_PSS and levelStr == "TPSS" then levelStr = "PSS" end

    return levelStr
end

local sIsWaitingLevelNameRefresh = true

local old_smlua_text_utils_course_acts_replace = smlua_text_utils_course_acts_replace
_G.smlua_text_utils_course_acts_replace = function (courseNum, courseName, act1, act2, act3, act4, act5, act6)
    sIsWaitingLevelNameRefresh = true
    old_smlua_text_utils_course_acts_replace(courseNum, courseName, act1, act2, act3, act4, act5, act6)
end

local old_smlua_text_utils_course_name_replace = smlua_text_utils_course_name_replace
_G.smlua_text_utils_course_name_replace = function (courseNum, name)
    sIsWaitingLevelNameRefresh = true
    old_smlua_text_utils_course_name_replace(courseNum, name)
end

local function parse_split(key, orig, flags)
    if #flags < 2 then return end
    local levelNum = tonumber(flags[2])
    local pbSegment = tonumber(flags[3])
    local split = {
        key = key,
        orig = orig,
        type = tonumber(flags[1]),
        levelID = levelNum,
        levelName = get_abbreviated_level_name(levelNum),
        pbSegment = pbSegment,
        prevPbSegment = pbSegment,
        thisSegment = -1,
    }
    return split
end

---@diagnostic disable-next-line: duplicate-set-field
function string:split(delimiter) -- from stack overflow
	local result = {}
	local from  = 1
	local delim_from, delim_to = string.find(self, delimiter, from )
	while delim_from do
		table.insert(result, string.sub(self, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = string.find(self, delimiter, from)
	end
	table.insert(result, string.sub(self, from))
	return result
end

for i = 0, MAX_PLAYERS - 1 do
    local syncTable = gPlayerSyncTable[i]
    syncTable.speedrunSplit = 1
end

-- Load splits
if network_is_server() then
    for player = 1, sLiveSplitSettings.numberOfPlayers do
        local playerStr = tostring(player) .. "P_split_"
        sSplits[player] = {}
        local split = 1
        local i = 1
        local numSplits = sLiveSplitSettings[player].numberOfSplits
        while i <= numSplits do
            local splitStr = playerStr .. tostring(i)
            local str = storage_load(splitStr)
            if not str then throw_error("Expected to find key '" .. splitStr .. "', but it was undefined.") return end
            if str ~= "cleared" then
                sSplits[player][split] = parse_split(splitStr, str, str:split("_"))
                split = split + 1
            end
            i = i + 1
        end
    end
    if error then return end
end

local m0 = gMarioStates[0]
local np0 = gNetworkPlayers[0]

local sSpeedrunTimer = 0
local sSpeedrunTimerPlaying = false
local sSpeedrunTimerFinished = false
local sSpeedrunSplitFrames = 0

-- Warp Node constants
local WARP_NODE_F0 = 0xF0

local sLocalPlayer = network_global_index_from_local(0)
local sNetworkLoaded = network_is_server()

local PACKET_TYPE_SPLIT             = 0
local PACKET_TYPE_ADD_SPLIT         = 1
local PACKET_TYPE_RESET_TIMER       = 2
local PACKET_TYPE_REQUEST_JOIN_INFO = 3
local PACKET_TYPE_TIMER_SET_STATE   = 4
local PACKET_TYPE_EDIT_SPLIT        = 5

local function get_uncolored_string(str)
    local s = ""
    local ignore = false
    for c in str:gmatch(".") do
        if c == "\\" then ignore = not ignore
        elseif not ignore then s = s .. c end
    end
    return s
end

local function on_network_load(m)
    if m and m.playerIndex ~= 0 then return end

    if not network_is_server() then

        -- Request from the server join info
        network_send_to(network_local_index_from_global(0), true, {
            globalIndex = sLocalPlayer,
            packetType = PACKET_TYPE_REQUEST_JOIN_INFO,
        })
    end
end

if network_is_server() then
    hook_event(HOOK_ON_PLAYER_CONNECTED, on_network_load)
else
    hook_event(HOOK_JOINED_GAME, on_network_load)
end

local function speedrun_get_split_frames(type)
    if type == SPLIT_STAR       then return 1 end
    if type == SPLIT_PAUSE_EXIT then return 4 end
    if type == SPLIT_STAR_EXIT  then return 4 end
    if type == SPLIT_BOWSER     then return 1 end
end

local function split_same_level(split)
    local localLevel = np0.currLevelNum
    if split.type == SPLIT_BOWSER and (localLevel == LEVEL_BOWSER_1 or localLevel == LEVEL_BOWSER_2 or localLevel == LEVEL_BOWSER_3) then
        return true
    end
    if split.type == SPLIT_PAUSE_EXIT and split.levelID == LEVEL_HMC and localLevel == LEVEL_COTMC then
        return true
    end
    return split.levelID == np0.currLevelNum
end

local function speedrun_split(type)
    if sSpeedrunTimerPlaying then
        local splits = sSplits[sLocalPlayer + 1]
        if splits then
            local split = splits[gPlayerSyncTable[0].speedrunSplit]
            if split and split_same_level(split) and split.type == type and sSpeedrunSplitFrames <= 0 then
                sSpeedrunSplitFrames = speedrun_get_split_frames(type)
            end
        end
    end
end

-- Only to be executed by server
local function speedrun_add_split(levelNum, type, playerNum)
    if not sSplits[playerNum] then sSplits[playerNum] = {} end
    local key = tostring(playerNum) .. "P_split_" .. #sSplits[playerNum] + 1
    local value = tostring(type) .. "_" .. tostring(levelNum) .. "_" .. tostring(-1)
    sSplits[playerNum][#sSplits[playerNum] + 1] = {
        key = key,
        orig = value,
        type = type,
        levelID = levelNum,
        levelName = get_abbreviated_level_name(levelNum),
        pbSegment = -1,
        prevPbSegment = -1,
        thisSegment = -1,
    }
    if not sLiveSplitSettings[playerNum] then
        sLiveSplitSettings[playerNum] = { numberOfSplits = 0 }
        storage_save("numberOfPlayers", tostring(#sSplits))
    end
    sLiveSplitSettings[playerNum].numberOfSplits = sLiveSplitSettings[playerNum].numberOfSplits + 1
    storage_save("numberOfSplits" .. tostring(playerNum), tostring(sLiveSplitSettings[playerNum].numberOfSplits))
    storage_save(key, value)

    -- Tell the other players about the new split
    network_send(true, {
        packetType = PACKET_TYPE_ADD_SPLIT,
        playerNum = playerNum,
        splitNum = #sSplits[playerNum],
        type = type,
        levelNum = levelNum,
        pbSegment = -1,
        prevPbSegment = -1,
    })
end
local function speedrun_reset_timer()
    if not network_is_server() then return end
    network_send(true, {
        packetType = PACKET_TYPE_RESET_TIMER,
    })
    sSplitMenu = SPLIT_MENU_RUN
    sSpeedrunTimerFinished = false
    sSpeedrunTimerPlaying = false
    sSpeedrunTimer = 0
    gPlayerSyncTable[0].speedrunSplit = 1
    sSpeedrunSplitFrames = 0
    for _, player in ipairs(sSplits) do
        for _, s in ipairs(player) do
            s.thisSegment = -1
            s.prevPbSegment = s.pbSegment
        end
    end
end

local function mh_is_runner_timer()
    if not mhApi then return false end
    if mhApi.getState() ~= 1 then return false end
    local timer = mhApi.getGlobalField("mhTimer")
    local countdown = mhApi.getGlobalField("countdown")
    return timer > countdown
end

hook_event(HOOK_UPDATE, function ()
    if mhApi then
        local state = mhApi.getState()
        if state ~= nil then
            sSpeedrunTimer = mhApi.getGlobalField("speedrunTimer")
            if state == 1 then
                if mh_is_runner_timer() then
                    sSpeedrunTimer = mhApi.getGlobalField("mhTimer") - mhApi.getGlobalField("countdown") + 30
                end
            end
            sSpeedrunTimerPlaying = state == 1 or state == 2
            if state ~= 0 then
                if network_is_server() then
                    if sSpeedrunTimerFinished and state <= 2 then
                        speedrun_reset_timer()
                    end
                    if state == 1 and sSpeedrunTimer == 180 and mhApi.getGlobalField("speedrunTimer") == 0 then
                        speedrun_reset_timer()
                        sSpeedrunTimerPlaying = true
                    end
                end
                sSpeedrunTimerFinished = state > 2
            end
        end
    end
    if sSpeedrunTimerPlaying then
        if not mhApi then sSpeedrunTimer = sSpeedrunTimer + 1 end

        if sSpeedrunSplitFrames == 1 then
            local curSplit = gPlayerSyncTable[0].speedrunSplit
            local splits = sSplits[sLocalPlayer + 1]
            local split = splits[curSplit]

            split.thisSegment = sSpeedrunTimer
            network_send(true, {
                globalIndex = sLocalPlayer,
                packetType = PACKET_TYPE_SPLIT,
                curSplit = curSplit,
                segmentTime = sSpeedrunTimer,
            })
            if curSplit >= #splits then -- Run finished
                sSpeedrunTimerPlaying = false
                sSpeedrunTimerFinished = true

                for i, player in ipairs(sSplits) do
                    gPlayerSyncTable[i].speedrunSplit = #player
                    player[#player].thisSegment = sSpeedrunTimer
                end

                -- Got a personal best?
                if splits[#splits].pbSegment == -1 or splits[#splits].pbSegment > sSpeedrunTimer then
                    for _, player in ipairs(sSplits) do
                        for _, s in ipairs(player) do
                            s.prevPbSegment = s.pbSegment
                            s.pbSegment = s.thisSegment
                            if network_is_server() then storage_save(s.key, s.orig:match("^(.*)_") .. "_" .. tostring(s.thisSegment)) end
                        end
                    end
                end
            else
                gPlayerSyncTable[0].speedrunSplit = curSplit + 1
            end
        end
        if sSpeedrunSplitFrames > 0 then sSpeedrunSplitFrames = sSpeedrunSplitFrames - 1 end
    end

    if sIsWaitingLevelNameRefresh then
        sIsWaitingLevelNameRefresh = false
        for _, player in ipairs(sSplits) do
            for _, segment in ipairs(player) do
                segment.levelName = get_abbreviated_level_name(segment.levelID)
            end
        end
    end
end)

local sPacketTable = {
    [PACKET_TYPE_REQUEST_JOIN_INFO] = function (data)
        if not network_is_server() then return end
        local localIndex = network_local_index_from_global(data.globalIndex)
        local sendData = {
            packetType = PACKET_TYPE_ADD_SPLIT,
            playerNum = 0,
            splitNum = 0,
            type = 0,
            levelNum = 0,
            pbSegment = 0,
            prevPbSegment = 0,
            complete = false,
            compTime = 0,
            noSplits = false,
            finished = false,
            playing = false,
        }
        for playerNum, player in ipairs(sSplits) do
            sendData.playerNum = playerNum
            for splitNum, split in ipairs(player) do
                sendData.splitNum = splitNum
                sendData.type = split.type
                sendData.levelNum = split.levelID
                sendData.pbSegment = split.pbSegment
                sendData.prevPbSegment = split.prevPbSegment
                if #sSplits == playerNum and #player == splitNum then
                    sendData.complete = true
                    sendData.compTime = sSpeedrunTimer
                    sendData.finished = sSpeedrunTimerFinished
                    sendData.playing = sSpeedrunTimerPlaying
                end
                network_send_to(localIndex, true, sendData)
            end
        end
        if #sSplits == 0 then
            sendData.noSplits = true
            sendData.complete = true
            sendData.compTime = sSpeedrunTimer
            sendData.finished = sSpeedrunTimerFinished
            sendData.playing = sSpeedrunTimerPlaying
            network_send_to(localIndex, true, sendData)
        end
    end,
    [PACKET_TYPE_SPLIT] = function (data)
        local localIndex = network_local_index_from_global(data.globalIndex)
        local curSplit = gPlayerSyncTable[localIndex].speedrunSplit
        local splits = sSplits[data.globalIndex + 1]
        local split = splits[curSplit]

        split.thisSegment = data.segmentTime
        if curSplit >= #splits then -- Run finished
            sSpeedrunTimerPlaying = false
            sSpeedrunTimerFinished = true

            local clientSplits = sSplits[sLocalPlayer + 1]
            if clientSplits then
                gPlayerSyncTable[0].speedrunSplit = #clientSplits
                clientSplits[#clientSplits].thisSegment = data.segmentTime
            end

            -- Got a personal best?
            if splits[#splits].pbSegment == -1 or splits[#splits].pbSegment > sSpeedrunTimer then
                for _, player in ipairs(sSplits) do
                    for _, s in ipairs(player) do
                        s.prevPbSegment = s.pbSegment
                        s.pbSegment = s.thisSegment
                        if network_is_server() then storage_save(s.key, s.orig:match("^(.*)_") .. "_" .. tostring(s.thisSegment)) end
                    end
                end
            end
        else
            gPlayerSyncTable[localIndex].speedrunSplit = curSplit + 1
        end
    end,
    [PACKET_TYPE_ADD_SPLIT] = function (data)
        if not data.noSplits then
            if not sSplits[data.playerNum] then sSplits[data.playerNum] = {} end
            sSplits[data.playerNum][data.splitNum] = {
                type = data.type,
                levelID = data.levelNum,
                levelName = get_abbreviated_level_name(data.levelNum),
                pbSegment = data.pbSegment,
                prevPbSegment = data.prevPbSegment,
                thisSegment = -1,
            }
        end
        if data.complete then
            sSpeedrunTimer = data.compTime
            sSpeedrunTimerFinished = data.finished
            sSpeedrunTimerPlaying = data.playing
            sNetworkLoaded = true
        end
    end,
    [PACKET_TYPE_RESET_TIMER] = function ()
        sSplitMenu = SPLIT_MENU_RUN
        sSpeedrunTimerFinished = false
        sSpeedrunTimerPlaying = false
        sSpeedrunTimer = 0
        gPlayerSyncTable[0].speedrunSplit = 1
        sSpeedrunSplitFrames = 0
        for _, player in ipairs(sSplits) do
            for _, s in ipairs(player) do
                s.thisSegment = -1
                s.prevPbSegment = s.pbSegment
            end
        end
    end,
    [PACKET_TYPE_TIMER_SET_STATE] = function (data)
        sSpeedrunTimerPlaying = data.playing
        sSpeedrunTimerFinished = data.finished
    end,
    [PACKET_TYPE_EDIT_SPLIT] = function (data)
        if not sSplits[data.playerNum] then return end -- If this triggers it means we're desynced
        if data.delete then
            table.remove(sSplits[data.playerNum], data.splitNum)
            if #sSplits[data.playerNum] == 0 then table.remove(sSplits, data.playerNum) end
            return
        end
        local split = sSplits[data.playerNum][data.splitNum]
        split.type = data.type
        split.levelID = data.levelNum
        split.levelName = get_abbreviated_level_name(data.levelNum)
        split.pbSegment = data.pbSegment
        split.prevPbSegment = data.prevPbSegment
        split.thisSegment = data.thisSegment
    end,
}

hook_event(HOOK_ON_PACKET_RECEIVE, function (data) if sPacketTable[data.packetType] then sPacketTable[data.packetType](data) end end)

local function get_last_warp_node_id() return m0.area.warpNodes.node.id end

-- Level Exit

local sWarpEntryArea = 0
local sWarpEntryLevel = 0

local sHookOnPauseExit = {}
local old_hook_event = hook_event
local function custom_hook_event(hook, func)
    if hook == HOOK_ON_PAUSE_EXIT then
        sHookOnPauseExit[#sHookOnPauseExit+1] = func
        return
    end
    old_hook_event(hook, func)
end

hook_event(HOOK_ON_PAUSE_EXIT, function (usedExitToCastle)

    -- Used to check if a mod has refused pause exiting
    for _, func in ipairs(sHookOnPauseExit) do
        local ret = func(usedExitToCastle)
        if ret ~= nil and not ret then return false end
    end

    -- Split
    speedrun_split(SPLIT_PAUSE_EXIT)
end)

local function on_warp()
    local warpNodeID = get_last_warp_node_id()
    if warpNodeID == WARP_NODE_F0 then speedrun_split(SPLIT_STAR_EXIT) end -- Star dance exit (does not work)
end

hook_event(HOOK_MARIO_UPDATE, function (m)
    if m.playerIndex ~= 0 then return end
    if sWarpEntryLevel ~= np0.currLevelNum or sWarpEntryArea ~= np0.currAreaIndex then
        sWarpEntryLevel = np0.currLevelNum
        sWarpEntryArea = np0.currAreaIndex
        on_warp()
    end
end)

hook_event(HOOK_ON_WARP, function ()
    if m0.action ~= ACT_TELEPORT_FADE_IN and m0.action ~= ACT_TELEPORT_FADE_OUT then
        sWarpEntryLevel = np0.currLevelNum
        sWarpEntryArea = np0.currAreaIndex
        on_warp()
    end
end)

-- Stars and keys

bhvGrandStar = get_behavior_from_id(id_bhvGrandStar)
hook_event(HOOK_ON_INTERACT, function (m, o, intType, intVal)
    if m.playerIndex ~= 0 then return end
    if intVal then
        if intType == INTERACT_STAR_OR_KEY then
            local level = np0.currLevelNum
            if (level == LEVEL_BOWSER_1 or
                level == LEVEL_BOWSER_2 or
                level == LEVEL_BOWSER_3) then
                speedrun_split(SPLIT_BOWSER)
            else
                speedrun_split(SPLIT_STAR)
            end
        end

        if intType == INTERACT_WARP then
            if o.behavior == bhvGrandStar then
                speedrun_split(SPLIT_BOWSER)
            end
        end
    end
end)

-- Render

local sMouse = {
    click = false,
    hoverElement = nil,
    clickedElement = nil,
    prevClickedElement = nil,
    x = 0, -- DJUI Resolution
    y = 0, -- DJUI Resolution
    cx = 0, -- Converted to N64 resolution
    cy = 0, -- Converted to N64 resolution
    prevX = 0, -- Previous X value
    prevY = 0, -- Previous Y value
}

local HAND_OPEN_TEX   = get_texture_info("gd_texture_hand_open")
local HAND_CLOSED_TEX = get_texture_info("gd_texture_hand_closed")

local isUpdate = false
local wasHolding = false

-- This is to make sure we grab inputs before they're needed
local function update_inputs()
    local cntr = m0.controller
    if not isUpdate then
        isUpdate = true
        sMouse.click = cntr.buttonDown & A_BUTTON ~= 0 and not (is_game_paused() or djui_hud_is_pause_menu_created())

        if cntr.buttonDown & U_JPAD ~= 0 and cntr.buttonDown & U_CBUTTONS ~= 0 then
            wasHolding = true
        else
            if wasHolding then
                if sSplitMenu == SPLIT_MENU_MAIN then
                    sSplitMenu = SPLIT_MENU_RUN
                else
                    sSplitMenu = SPLIT_MENU_MAIN
                end
            end
            wasHolding = false
        end
    end
    if sMouse.hoverElement ~= nil and sMouse.click then
        cntr.buttonDown = cntr.buttonDown & ~A_BUTTON
        cntr.buttonPressed = cntr.buttonPressed & ~A_BUTTON
    end
end
hook_event(HOOK_UPDATE, function () isUpdate = false end)

local function mouse_set_element(set, tag)
    if sMouse.clickedElement and sMouse.clickedElement ~= tag and set then
        sMouse.clickedElement = tag
    end
    if not sMouse.clickedElement and set then
        sMouse.clickedElement = tag
    end
    if not sMouse.click then
        sMouse.clickedElement = nil
    end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE, function (m)
    if m.playerIndex == 0 then
        update_inputs()
    end
end)

local sLiveSplit64Chars = {
    ["."] = 10,
    [":"] = 10,
    ["0"] = 14,
    ["1"] = 14,
    ["2"] = 14,
    ["3"] = 14,
    ["4"] = 14,
    ["5"] = 14,
    ["6"] = 14,
    ["7"] = 14,
    ["8"] = 14,
    ["9"] = 14,
}

-- String rendering function that uses a custom width for characters
-- intended for rendering the timer
local function livesplit64_render(str, x, y, s)
    for i = 1, #str do
        local c = str:sub(i, i)
        djui_hud_print_text(c, x, y, s)
        local charSize = sLiveSplit64Chars[c] or 16
        x = x + (charSize * s)
    end
end

local function livesplit64_measure(str, size)
    local len = 0
    for i = 1, #str do
        local c = str:sub(i, i)
        local charSize = sLiveSplit64Chars[c] or 16
        len = len + (charSize * size)
    end
    return len
end

local function livesplit64_print_text(message, x, y, scale, shadow, r, g, b, a)
    if shadow and shadow > 0 then
        djui_hud_set_color(0, 0, 0, a or 0xFF)
        livesplit64_render(message, x + shadow, y + shadow, scale)
    end
    djui_hud_set_color(r or 0xFF, g or 0xFF, b or 0xFF, a or 0xFF)
    livesplit64_render(message, x, y, scale)
end

local old_djui_hud_print_text = djui_hud_print_text
local function djui_hud_print_text(message, x, y, scale, shadow, r, g, b, a)
    if shadow and shadow > 0 then
        djui_hud_set_color(0, 0, 0, a or 0xFF)
        old_djui_hud_print_text(message, x + shadow, y + shadow, scale)
    end
    djui_hud_set_color(r or 0xFF, g or 0xFF, b or 0xFF, a or 0xFF)
    old_djui_hud_print_text(message, x, y, scale)
end

local function draw_rectangle(x, y, h, w, lineW)
    djui_hud_render_rect(x,     y,     lineW + w, lineW)
    djui_hud_render_rect(x,     y + h, lineW + w, lineW)
    djui_hud_render_rect(x,     y,     lineW,     lineW + h)
    djui_hud_render_rect(x + w, y,     lineW,     lineW + h)
end

local function is_point_in_box(px, py, bx, by, bw, bh)
    return (px > bx and px < bx + bw) and (py > by and py < by + bh)
end

local sButtons = {}
local function render_button(t, ts, x, y, w, h, callback, id, fadeOut)
    local mouseInBox = is_point_in_box(sMouse.cx, sMouse.cy, x, y, w, h) and not (is_game_paused() or djui_hud_is_pause_menu_created())

    local r, g, b = 0x30, 0x30, 0x30
    djui_hud_set_color(r, g, b, (fadeOut and 0x50) or 0xFF)
    local outlineS = 1
    local hos = outlineS / 2
    draw_rectangle(x, y, h - hos, w - hos, outlineS)
    local isEnabled = callback and callback(true)
    if isEnabled then
        r, g, b = 0x00, 0xFF, 0x00
        if fadeOut then
            r, g, b = 0x10, 0x10, 0x10
        end
    end
    djui_hud_print_text(t, x + ((w - (djui_hud_measure_text(t) * ts))/2), y + (h / 2) - ((32 * ts) / 2), ts, 1, 0xFF, 0xFF, 0xFF, (fadeOut and 0x50) or 0xFF)
    djui_hud_set_color(r, g, b, 0x50)
    if not id then id = t end
    if not (isEnabled and fadeOut) and mouseInBox and (not sMouse.clickedElement or sMouse.clickedElement == t) then
        sMouse.hoverElement = t
        djui_hud_set_color(r, g, b, 0x96)
        if sMouse.click then
            mouse_set_element(true, t)
            djui_hud_set_color(r, g, b, 0xFF)
        elseif sButtons[id] and sMouse.prevClickedElement == t then
            if callback then callback() end
        end
    end
    sButtons[id] = sMouse.click and mouseInBox
    djui_hud_render_rect(x + hos, y + hos, w - hos, h - hos)
end

local function frames_to_time_str(frames, forceMinutes)
    local s = frames // 30
    local seconds = s % 60
    local minutes = s // 60 % 60
    local hours = s // 60 // 60
    if minutes == 0 and not forceMinutes then
        return string_format("%d", seconds)
    elseif hours == 0 then
        return string_format("%d:%02d", minutes, seconds)
    else
        return string_format("%d:%02d:%02d", hours, minutes, seconds)
    end
end
local function frames_to_time_str_decimal(frames, forceMinutes)
    local milliseconds = math_floor(frames / 30 % 1 * 100)
    local s = frames // 30
    local seconds = s % 60
    local minutes = s // 60 % 60
    local hours = s // 60 // 60
    if minutes == 0 and not forceMinutes then
        return string_format("%d.%02d", seconds, milliseconds)
    elseif hours == 0 then
        return string_format("%d:%02d.%02d", minutes, seconds, milliseconds)
    else
        return string_format("%d:%02d:%02d.%02d", hours, minutes, seconds, milliseconds)
    end
end

local sMenuX = tonumber(mod_storage_load("menuX")) or 0
local sMenuY = tonumber(mod_storage_load("menuY")) or 0
local sCourseID = COURSE_BOB
local sSplitAddType = SPLIT_PAUSE_EXIT
local sSplitAddPlayer = 1

local function split_menu_run_render(x, y, w, h, segmentW)
    djui_hud_set_color(0x00, 0x00, 0x00, 0xCF)
    djui_hud_render_rect(x, sMenuY, w, 10)

    for playerIndex, player in ipairs(sSplits) do
        local connected = gNetworkPlayers[playerIndex - 1].connected
        for segmentNum, segment in ipairs(player) do
            local speedRunSplit = gPlayerSyncTable[network_local_index_from_global(playerIndex - 1)].speedrunSplit
            if sSpeedrunTimerPlaying and connected and segmentNum == speedRunSplit then
                djui_hud_set_color(0x00, 0x00, 0xFF, 0xEF)
            else
                if segmentNum % 2 == 1 then
                    djui_hud_set_color(0x00, 0x00, 0x00, 0xBF)
                else
                    djui_hud_set_color(0x30, 0x30, 0x30, 0xBF)
                end
            end
            local drawS = 7
            local x = x + (segmentW * (playerIndex - 1))
            local y = y + (drawS * (segmentNum - 1))
            djui_hud_render_rect(x, y, segmentW, drawS)

            local time = segment.pbSegment == -1 and "-" or frames_to_time_str(segment.pbSegment, true)
            local m = djui_hud_measure_text(time) * 0.2
            local sideX = x + segmentW - m - 2
            djui_hud_print_text(time, sideX, y, 0.2, 1)

            if connected then
                if segment.prevPbSegment ~= -1 and segmentNum <= speedRunSplit then
                    local tracker = segment.thisSegment == -1 and sSpeedrunTimer or segment.thisSegment
                    if segment.prevPbSegment <= tracker then
                        local time = "+" .. frames_to_time_str_decimal(tracker - segment.prevPbSegment)
                        local m2 = livesplit64_measure(time, 0.2)
                        sideX = sideX - m2 - 3
                        livesplit64_print_text(time, sideX, y, 0.2, 0.5, 0xFF, 0x00, 0x00)
                    end
                    if segment.thisSegment ~= -1 and segment.thisSegment < segment.prevPbSegment then
                        local time = "-" .. frames_to_time_str_decimal(segment.prevPbSegment - segment.thisSegment)
                        local m2 = livesplit64_measure(time, 0.2)
                        sideX = sideX - m2 - 3
                        livesplit64_print_text(time, sideX, y, 0.2, 0.5, 0x00, 0xFF, 0x00)
                    end
                end
            end

            local levelStr = segment.levelName
            local levelLen = djui_hud_measure_text(levelStr) * 0.2
            if x + 1 + levelLen > sideX then -- Shorten the level name if there's overlap
                local i = #levelStr
                while i > 0 do
                    levelLen = djui_hud_measure_text(levelStr) * 0.2
                    if x + 1 + levelLen < sideX then break end
                    i = i - 1
                    levelStr = levelStr:sub(0, i)
                end
            end
            djui_hud_print_text(levelStr, x + 1, y, 0.2, 1)
        end
    end

    -- Timer
    local r, g, b = 0xFF, 0xFF, 0xFF
    if #sSplits > 0 then
        local splits = sSplits[sLocalPlayer + 1] or sSplits[1]
        local split = splits[gPlayerSyncTable[0].speedrunSplit] or splits[gPlayerSyncTable[network_local_index_from_global(0)].speedrunSplit]
        local isPbRun = false
        if sSpeedrunTimerFinished then
            local fastestSplit = nil
            for _, player in ipairs(sSplits) do
                local lastSplit = player[#player]
                if lastSplit.prevPbSegment ~= -1 then
                    if fastestSplit == nil or lastSplit.prevPbSegment < fastestSplit then
                        fastestSplit = lastSplit.prevPbSegment
                    end
                end
            end
            isPbRun = fastestSplit == nil or fastestSplit > sSpeedrunTimer
        end
        if ((sSpeedrunTimerFinished and not isPbRun) or
            (sSpeedrunTimerPlaying and split.prevPbSegment ~= -1 and split.prevPbSegment < sSpeedrunTimer)) then
            r, g, b = 0xFF, 0x00, 0x00
        elseif sSpeedrunTimerPlaying then
            r, g, b = 0x00, 0xFF, 0x00
        elseif sSpeedrunTimerFinished and isPbRun then
            r, g, b = 0x00, 0x00, 0xFF
        end
    elseif sSpeedrunTimerPlaying then
        r, g, b = 0x00, 0xFF, 0x00
    elseif sSpeedrunTimerFinished then
        r, g, b = 0x00, 0x00, 0xFF
    end

    local scale = 0.5
    local milliseconds = math_floor(sSpeedrunTimer / 30 % 1 * 100)
    local milliSize = 0.4
    local milliText = string_format("%02d", milliseconds)
    local t = frames_to_time_str(sSpeedrunTimer) .. "."

    local timerY = y + h - (32 * scale)

    -- Show player names
    local playerNum = math_max(#sSplits - 1, 0)
    for playerIndex = 0, playerNum do
        local np = gNetworkPlayers[network_local_index_from_global(playerIndex)]
        local connected = np.connected
        local str = connected and get_uncolored_string(np.name) or "-"
        local segX = x + (segmentW * playerIndex)
        local txtX = segX + 2
        local m = djui_hud_measure_text(str) * 0.3
        if #sSplits == 2 and playerIndex == 1 then
            txtX = x + (w - m) - 2
        end
        if m > segmentW then
            str = str:sub(1, math_floor(((#str + 2 * 16) - (m - segmentW)) * 0.3)) .. ".."
        end
        djui_hud_print_text(str, txtX, sMenuY, 0.3)
    end

    local milliTextLen = livesplit64_measure(milliText, milliSize)
    local tLen = livesplit64_measure(t, scale)
    local txtX = x + w - 2
    if #sSplits == 2 then txtX = x + ((w / 2) + ((tLen + milliTextLen) / 2)) end
    if mh_is_runner_timer() then djui_hud_print_text("-", txtX - (tLen + milliTextLen) - (16 * scale), timerY, scale, 1, r, g, b) end
    livesplit64_print_text(t, txtX - (tLen + milliTextLen), timerY, scale, 1, r, g, b)
    local milliY = timerY + (32 * 0.5 * scale) - 5
    livesplit64_print_text(milliText, txtX - milliTextLen, milliY, milliSize, 1, r, g, b)
end

local function split_menu_main_render(x, y, menuW, menuH, segmentW)
    local mouseInBox = is_point_in_box(sMouse.cx, sMouse.cy, x, y, menuW, menuH)

    local w = menuW
    local h = 10
    local textS = 0.15
    local isServer = network_is_server()
    if isServer then
        render_button((sSpeedrunTimerPlaying and "Pause Timer" or "Start Timer"), textS, x, y + (h * 0), w, h, function (getEnabled)
            if getEnabled then return false end
            if sSpeedrunTimerFinished then return end
            if not isServer then return end
            sSplitMenu = SPLIT_MENU_RUN
            sSpeedrunTimerPlaying = not sSpeedrunTimerPlaying
            network_send(true, {
                packetType = PACKET_TYPE_TIMER_SET_STATE,
                playing = sSpeedrunTimerPlaying,
                finished = sSpeedrunTimerFinished,
            })
        end, "Timer State Toggle", sSpeedrunTimerFinished)
        render_button("Reset Timer", textS, x, y + (h * 1), w, h, function (getEnabled)
            if getEnabled then return false end
            speedrun_reset_timer()
        end)
        render_button("Edit Splits", textS, x, y + (h * 2), w, h, function (getEnabled)
            if getEnabled then return false end
            if not isServer then return end
            sSplitMenu = SPLIT_MENU_EDIT
        end)
    end
    render_button("Open DJUI Menu", textS, x, y + (h * (isServer and 3 or 0)), w, h, function (getEnabled)
        if getEnabled then return djui_hud_is_pause_menu_created() end
        if not djui_hud_is_pause_menu_created() then djui_open_pause_menu() end
    end)

    render_button("Close Menu", textS, x, y + (menuH - h), w, h, function (getEnabled)
        if getEnabled then return false end
        sSplitMenu = SPLIT_MENU_RUN
    end)

    -- Drag the UI in the main menu
    if (not sMouse.clickedElement and mouseInBox) or (type(sMouse.clickedElement) == "table" and sMouse.clickedElement.type == "menu-drag") then
        if sMouse.click then
            local xDist = sMouse.cx - sMenuX
            local yDist = sMouse.cy - sMenuY
            if not sMouse.clickedElement then
                mouse_set_element(true, {
                    type = "menu-drag",
                    x = xDist,
                    y = yDist,
                })
            end

            local screen_w = djui_hud_get_screen_width()
            local screen_h = djui_hud_get_screen_height()
            sMenuX = clamp(sMenuX + (xDist - sMouse.clickedElement.x), 0, screen_w - menuW)
            sMenuY = clamp(sMenuY + (yDist - sMouse.clickedElement.y), 0, screen_h - menuH)
        end
    end
    if type(sMouse.prevClickedElement) == "table" and sMouse.prevClickedElement.type == "menu-drag" then
        sMouse.prevClickedElement = nil
        mod_storage_save("menuX", tostring(sMenuX))
        mod_storage_save("menuY", tostring(sMenuY))
    end
end

local function split_menu_add_split_render(x, y, w, h)
    local isEditing = sSplitEdit ~= nil

    local textS = 0.2
    local halfWidth = w / 2
    local halfW = x + halfWidth
    local name = isEditing and "Edit Split" or "Add Split"
    djui_hud_print_text(name, halfW - ((djui_hud_measure_text(name) * 0.3) / 2), y + 10, 0.3)

    local s = 0.2
    local levelNum = course_to_level(sCourseID)
    local levelName = get_level_name(sCourseID, levelNum, 0)
    local levelNameLen = djui_hud_measure_text(levelName) * s
    local levelNameX = halfW - (levelNameLen / 2)
    djui_hud_print_text(levelName, levelNameX, y + 20, s)
    render_button("<", textS, halfW - 15, y + 35, 10, 10, function (getEnabled)
        if getEnabled then return false end
        sCourseID = math_max(COURSE_BOB, sCourseID - 1)
    end)
    render_button(">", textS, halfW + 5, y + 35, 10, 10, function (getEnabled)
        if getEnabled then return false end
        sCourseID = math_min(COURSE_SA, sCourseID + 1)
    end)

    local splitName = "Star"
    if sSplitAddType == SPLIT_PAUSE_EXIT then splitName = "Pause Exit" end
    if sSplitAddType == SPLIT_STAR_EXIT  then splitName = "Star Exit"  end
    if sSplitAddType == SPLIT_BOWSER     then splitName = "Bowser"     end
    render_button(splitName, textS, halfW - 15, y + 55, 30, 10, function (getEnabled)
        if getEnabled then return false end
        sSplitAddType = (sSplitAddType + 1) % (SPLIT_COUNT + 1)
    end)

    if isEditing then
        render_button("Clear Times", textS, halfW - 20, y + 65, 20, 10, function (getEnabled)
            if getEnabled then return sSplitEdit.pbSegment == -1 end
            sSplitEdit.pbSegment = -1
            sSplitEdit.prevPbSegment = -1
            sSplitEdit.thisSegment = -1

            local playerNum = sSplitAddPlayer + 1
            network_send(true, {
                packetType = PACKET_TYPE_EDIT_SPLIT,
                playerNum = playerNum,
                splitNum = sSplitEditSegmentNum,
                type = sSplitAddType,
                levelNum = levelNum,
                pbSegment = -1,
                prevPbSegment = -1,
                thisSegment = -1,
            })
        end, "Clear Times", sSplitEdit.prevPbSegment == -1)
        render_button("Delete", textS, halfW, y + 65, 20, 10, function (getEnabled)
            if getEnabled then return false end
            local playerNum = sSplitAddPlayer
            table.remove(sSplits[playerNum], sSplitEditSegmentNum)
            if #sSplits[playerNum] == 0 then table.remove(sSplits, playerNum) end
            local key = tostring(playerNum) .. "P_split_" .. tostring(sSplitEditSegmentNum)
            storage_save(key, "cleared")
            network_send(true, {
                packetType = PACKET_TYPE_EDIT_SPLIT,
                playerNum = playerNum,
                splitNum = sSplitEditSegmentNum,
                delete = true,
            })
            sSplitMenu = SPLIT_MENU_EDIT
        end)
    else
        local np = gNetworkPlayers[sSplitAddPlayer - 1]
        local connected = np.connected
        local pName = tostring(sSplitAddPlayer - 1) .. " - " .. (connected and get_uncolored_string(np.name) or "Not connected")
        local pLen = djui_hud_measure_text(pName) * s
        local pX = halfW - (pLen / 2)
        djui_hud_print_text(pName, pX, y + 67, s)
        render_button("<", textS, halfW - 15, y + 75, 10, 10, function (getEnabled)
            if getEnabled then return false end
            sSplitAddPlayer = math_max(1, sSplitAddPlayer - 1)
        end, "<2")
        render_button(">", textS, halfW + 5, y + 75, 10, 10, function (getEnabled)
            if getEnabled then return false end
            sSplitAddPlayer = math_min(network_player_connected_count(), sSplitAddPlayer + 1)
        end, ">2")
    end

    render_button("Cancel", textS, x, y + h - 9, halfWidth, 8, function (getEnabled)
        if getEnabled then return false end
        sSplitMenu = SPLIT_MENU_EDIT
    end)
    render_button(isEditing and "Save" or "Add", textS, halfW, y + h - 9, halfWidth, 8, function (getEnabled)
        if getEnabled then return false end
        sSplitMenu = SPLIT_MENU_EDIT
        if isEditing then
            sSplitEdit.type = sSplitAddType
            sSplitEdit.levelID = levelNum
            sSplitEdit.levelName = get_abbreviated_level_name(levelNum)

            local playerNum = sSplitAddPlayer
            local key = tostring(playerNum) .. "P_split_" .. tostring(sSplitEditSegmentNum)
            local value = tostring(sSplitAddType) .. "_" .. tostring(levelNum) .. "_" .. tostring(-1)
            storage_save(key, value)

            network_send(true, {
                packetType = PACKET_TYPE_EDIT_SPLIT,
                playerNum = playerNum,
                splitNum = sSplitEditSegmentNum,
                type = sSplitAddType,
                levelNum = levelNum,
                pbSegment = sSplitEdit.pbSegment,
                prevPbSegment = sSplitEdit.prevPbSegment,
                thisSegment = sSplitEdit.thisSegment,
            })
        else
            speedrun_add_split(levelNum, sSplitAddType, sSplitAddPlayer)
        end
    end)
end

local function split_menu_edit_render(x, y, w, h, segmentW)
    djui_hud_set_color(0x00, 0x00, 0x00, 0xCF)

    local mouseClickBox = false
    local inBoxPI = 0 -- playerIndex
    local inBoxSN = 0 -- segmentNumber
    for playerIndex, player in ipairs(sSplits) do
        for segmentNum, segment in ipairs(player) do
            local drawS = 7
            local x = x + (segmentW * (playerIndex - 1))
            local y = y + (drawS * (segmentNum - 1))
            local isInBox = is_point_in_box(sMouse.cx, sMouse.cy, x, y, segmentW, drawS)

            if isInBox and sMouse.click then
                mouseClickBox = true
                inBoxPI = playerIndex
                inBoxSN = segmentNum
            else
                local levelStr = segment.levelName
                if isInBox then
                    djui_hud_set_color(0x00, 0x00, 0xFF, 0xFF)
                    if sMouse.prevClickedElement == levelStr then
                        sSplitMenu = SPLIT_MENU_ADD_SPLIT
                        sSplitEdit = segment
                        sCourseID = level_to_course(segment.levelID)
                        sSplitAddType = segment.type
                        sSplitAddPlayer = playerIndex
                        sSplitEditSegmentNum = segmentNum
                    end
                elseif segmentNum % 2 == 1 then
                    djui_hud_set_color(0x00, 0x00, 0x00, 0xBF)
                else
                    djui_hud_set_color(0x30, 0x30, 0x30, 0xBF)
                end
                djui_hud_render_rect(x, y, segmentW, drawS)

                local time = segment.pbSegment == -1 and "-" or frames_to_time_str(segment.pbSegment, true)
                local m = djui_hud_measure_text(time) * 0.2
                local sideX = x + segmentW - m - 2
                djui_hud_print_text(time, sideX, y, 0.2, 1)

                local levelLen = djui_hud_measure_text(levelStr) * 0.2
                djui_hud_print_text(levelStr, x + ((segmentW - levelLen) / 2), y, 0.2, 1)
            end
        end
    end
    if mouseClickBox then
        local segment = sSplits[inBoxPI][inBoxSN]
        local drawS = 7
        local x = x + (segmentW * (inBoxPI - 1))
        local y = y + (drawS * (inBoxSN - 1))
        djui_hud_set_color(0x00, 0x00, 0xFF, 0xFF)
        djui_hud_render_rect(x - 1, y - 1, segmentW + 2, drawS + 2)

        local time = segment.pbSegment == -1 and "-" or frames_to_time_str(segment.pbSegment, true)
        local m = djui_hud_measure_text(time) * 0.2
        local sideX = x + segmentW - m - 2
        djui_hud_print_text(time, sideX, y, 0.2, 1)

        local levelStr = segment.levelName
        local levelLen = djui_hud_measure_text(levelStr) * 0.2
        if x + 1 + levelLen > sideX then -- Shorten the level name if there's overlap
            local i = #levelStr
            while i > 0 do
                levelLen = djui_hud_measure_text(levelStr) * 0.2
                if x + 1 + levelLen < sideX then break end
                i = i - 1
                levelStr = levelStr:sub(0, i)
            end
        end

        if not sMouse.clickedElement then
            mouse_set_element(true, levelStr)
        end

        djui_hud_print_text(levelStr, x + ((segmentW - levelLen) / 2), y - 1, 0.25, 1)
    end

    render_button("Add Split", 0.2, x + w / 2, y + h - 16, w / 2, 15, function (getEnabled)
        if getEnabled then return false end
        if not network_is_server() then return end
        sSplitMenu = SPLIT_MENU_ADD_SPLIT
        sSplitEdit = nil
        sCourseID = COURSE_BOB
        sSplitAddType = SPLIT_PAUSE_EXIT
        sSplitAddPlayer = 1
    end)
    render_button("Back", 0.2, x, y + h - 16, w / 2, 15, function (getEnabled)
        if getEnabled then return false end
        sSplitMenu = SPLIT_MENU_MAIN
    end)
end

hook_event(HOOK_ON_HUD_RENDER, function ()
    if not sMouse.click then
        sMouse.prevClickedElement = sMouse.clickedElement
        sMouse.clickedElement = nil
    end
    sMouse.hoverElement = nil

    -- Process mouse inputs
    djui_hud_set_resolution(RESOLUTION_DJUI)
    sMouse.prevX, sMouse.prevY = sMouse.x, sMouse.y
    sMouse.x = djui_hud_get_mouse_x()
    sMouse.y = djui_hud_get_mouse_y()
    local screen_w_djui = djui_hud_get_screen_width()
    local screen_h_djui = djui_hud_get_screen_height()

    djui_hud_set_font(FONT_NORMAL)
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_rotation(0, 0, 0)

    local screen_w = djui_hud_get_screen_width()
    local screen_h = djui_hud_get_screen_height()

    local diffX = screen_w / screen_w_djui
    local diffY = screen_h / screen_h_djui
    sMouse.cx = sMouse.x * diffX
    sMouse.cy = sMouse.y * diffY

    local x = sMenuX
    local y = sMenuY
    local segmentW = 40
    local w = segmentW
    local h = 100

    y = y + 10
    w = math_max(#sSplits, 1) * segmentW
    local largest = 1
    for _, s in ipairs(sSplits) do
        if #s > largest then
            largest = #s
        end
    end
    h = (largest * 7) + 18

    w = math_max(w, 50)
    h = math_max(h, 95)
    if #sSplits < 2 then segmentW = w end

    djui_hud_set_color(0x00, 0x00, 0x00, 0x9F)
    djui_hud_render_rect(x, sMenuY, w + 1, h + 10)

    if sSplitMenu ~= SPLIT_MENU_RUN or not sNetworkLoaded then
        local text = "LiveSplit64"
        local len = djui_hud_measure_text(text) * 0.3
        djui_hud_print_text(text, x + ((w - len) / 2), sMenuY, 0.3, 1)

        if is_point_in_box(sMouse.cx, sMouse.cy, x, y, w, h) then
            sMouse.hoverElement = "menu"
        end
    end
    if not sNetworkLoaded then
        local text = "Loading splits from host..."
        local len = djui_hud_measure_text(text) * 0.2
        djui_hud_print_text(text, x + ((w - len) / 2), sMenuY + (h / 2), 0.2, 1)
        return
    end

    -- Render the menus
    if sSplitMenu == SPLIT_MENU_RUN then       split_menu_run_render(x, y, w, h, segmentW)  end
    if sSplitMenu == SPLIT_MENU_MAIN then      split_menu_main_render(x, y, w, h, segmentW) end
    if sSplitMenu == SPLIT_MENU_ADD_SPLIT then split_menu_add_split_render(x, y, w, h)      end
    if sSplitMenu == SPLIT_MENU_EDIT then      split_menu_edit_render(x, y, w, h, segmentW) end

    ---------------------------------------------

    -- Render mouse interpolated
    if sSplitMenu ~= SPLIT_MENU_RUN and not djui_hud_is_pause_menu_created() then
        djui_hud_set_resolution(RESOLUTION_DJUI)
        local s = 2
        local t = sMouse.click and HAND_CLOSED_TEX or HAND_OPEN_TEX
        djui_hud_set_color(0xFF, 0xFF, 0xFF, 0xFF)
        djui_hud_render_texture_interpolated(t,
            sMouse.prevX, sMouse.prevY, s, s, -- interpolate from
            sMouse.x, sMouse.y, s, s -- interpolate to
        )
    end
end)

_G.hook_event = custom_hook_event -- Apply custom hook_event
