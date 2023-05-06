if _G.OmmEnabled then
    _G.OmmApi.omm_register_game("The Phantom's Call", function() return true end, function()
        ---------------
        -- Game data --
        ---------------

        _G.OmmApi.omm_register_game_data(-1, 0, nil, true, false, 0xFFFF00, 250)
        _G.OmmApi.omm_disable_non_stop_mode(true)

        -----------------
        -- Level stars --
        -----------------

        _G.OmmApi.omm_register_level_stars(LEVEL_NONE, 0x0000000)
        _G.OmmApi.omm_register_level_stars(LEVEL_WF, 0xFFFFFFF)
        _G.OmmApi.omm_register_level_stars(LEVEL_WMOTR, 0x0000000)

        --------------------
        -- Star behaviors --
        --------------------

        --------------------
        -- Camera presets --
        --------------------

        -------------------------
        -- Camera no-col boxes --
        -------------------------

        ----------------
        -- Warp pipes --
        ----------------

        -------------------
        -- Non-Stop mode --
        -------------------
    end)
end
