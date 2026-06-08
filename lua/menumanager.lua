if not ChatTypingInfo then
	dofile(ModPath .. "mod.lua")
end

-- menu itself
Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenus_ChatTypingInfo", function(menu_manager, nodes)
	local menu_id = "ChatTypingInfo"

	MenuHelper:NewMenu(menu_id)

	MenuCallbackHandler.ChatTypingInfo_save = function(this, item)
		ChatTypingInfo:Save()
	end

	MenuCallbackHandler.ChatTypingInfo_donothing = function(this, item)
		-- warm, primordial blackness
	end

	local menu_slider_alpha, menu_alignment_preset, menu_slider_w, menu_slider_h, menu_slider_x, menu_slider_y, menu_slider_font
	local game_slider_alpha, game_alignment_preset, game_slider_w, game_slider_h, game_slider_x, game_slider_y, game_slider_font

	MenuCallbackHandler.ChatTypingInfo_slider_menu = function(this, item)
		ChatTypingInfo.settings[string.sub(item:name(), 16, -1)] = item:value() -- cursed, but im too lazy to rename all the toggle/slider menu items
		ChatTypingInfo:Save()
		ChatTypingInfo:UpdateMenuTextPanel()
		local state = ChatTypingInfo:GetGameState()
		if (state == "menus" or state == "pre_game_lobby") and managers.network and managers.network:session() and managers.network:session():local_peer() then
			managers.network:session():local_peer()._last_typing_info_t = TimerManager:game():time() -- preview the text while customizing it
		end
	end

	MenuCallbackHandler.ChatTypingInfo_toggle_menu = function(this, item)
		local param = string.sub(item:name(), 16, -1)
		ChatTypingInfo.settings[param] = item:value() == "on"
		ChatTypingInfo:Save()
		ChatTypingInfo:UpdateMenuTextPanel()
		local state = ChatTypingInfo:GetGameState()
		if (state == "menus" or state == "pre_game_lobby") and managers.network and managers.network:session() and managers.network:session():local_peer() then
			managers.network:session():local_peer()._last_typing_info_t = TimerManager:game():time()
		end
		-- disable certain options to make it simpler for the end user
		local function update_custom_options(toggle)
			menu_slider_w:set_enabled(toggle)
			menu_slider_h:set_enabled(toggle)
			menu_slider_x:set_enabled(toggle)
			menu_slider_y:set_enabled(toggle)
			menu_slider_font:set_enabled(toggle)
		end
		if param == "menus_info_enabled" then -- disable all options if our text gets disabled entirely
			menu_slider_alpha:set_enabled(ChatTypingInfo.settings[param])
			menu_alignment_preset:set_enabled(ChatTypingInfo.settings[param])
			-- update custom location options based on "custom options toggle" status, if everything was enabled
			if ChatTypingInfo.settings.menus_info_enabled then
				update_custom_options(not ChatTypingInfo.settings.menus_use_alignment_preset)
			else -- or disable everything
				update_custom_options(ChatTypingInfo.settings[param])
			end
		elseif param == "menus_use_alignment_preset" and ChatTypingInfo.settings.menus_info_enabled then -- adjust configurable options exclusive to the custom placement
			update_custom_options(not ChatTypingInfo.settings.menus_use_alignment_preset)
		end
	end

	MenuCallbackHandler.ChatTypingInfo_slider_ingame = function(this, item)
		ChatTypingInfo.settings[string.sub(item:name(), 16, -1)] = item:value()
		ChatTypingInfo:Save()
		if managers.hud and managers.hud._hud_chat_ingame then
			managers.hud._hud_chat_ingame:UpdateIngameTypingTextPanel()
		end
		local state = ChatTypingInfo:GetGameState()
		if state == "in_match" and managers.network and managers.network:session() and managers.network:session():local_peer() then
			managers.network:session():local_peer()._last_typing_info_t = TimerManager:game():time()
		end
	end

	MenuCallbackHandler.ChatTypingInfo_toggle_ingame = function(this, item)
		local param = string.sub(item:name(), 16, -1)
		ChatTypingInfo.settings[param] = item:value() == "on"
		ChatTypingInfo:Save()
		if managers.hud and managers.hud._hud_chat_ingame then
			managers.hud._hud_chat_ingame:UpdateIngameTypingTextPanel()
		end
		local state = ChatTypingInfo:GetGameState()
		if state == "in_match" and managers.network and managers.network:session() and managers.network:session():local_peer() then
			managers.network:session():local_peer()._last_typing_info_t = TimerManager:game():time()
		end
		-- same shit as with menu options
		local function update_custom_options(toggle)
			game_slider_w:set_enabled(toggle)
			game_slider_h:set_enabled(toggle)
			game_slider_x:set_enabled(toggle)
			game_slider_y:set_enabled(toggle)
			game_slider_font:set_enabled(toggle)
		end
		if param == "in_game_info_enabled" then
			game_slider_alpha:set_enabled(ChatTypingInfo.settings[param])
			game_alignment_preset:set_enabled(ChatTypingInfo.settings[param])
			if ChatTypingInfo.settings.in_game_info_enabled then
				update_custom_options(not ChatTypingInfo.settings.in_game_use_alignment_preset)
			else
				update_custom_options(ChatTypingInfo.settings[param])
			end
		elseif param == "in_game_use_alignment_preset" and ChatTypingInfo.settings.in_game_info_enabled then
			update_custom_options(not ChatTypingInfo.settings[param])
		end
	end

	MenuHelper:AddToggle({
		id = "ChatTypingInfo_menus_info_enabled",
		title = "ChatTypingInfo_menus_info_enabled",
		desc = "ChatTypingInfo_menus_info_enabled_desc",
		callback = "ChatTypingInfo_toggle_menu",
		value = ChatTypingInfo.settings.menus_info_enabled,
		menu_id = menu_id,
		priority = 100
	})

	menu_slider_alpha = MenuHelper:AddSlider({
		id = "ChatTypingInfo_menus_alpha",
		title = "ChatTypingInfo_menus_alpha",
		desc = "ChatTypingInfo_menus_alpha_desc",
		callback = "ChatTypingInfo_slider_menu",
		disabled = not ChatTypingInfo.settings.menus_info_enabled,
		value = ChatTypingInfo.settings.menus_alpha,
		min = 0,
		max = 1,
		step = 0.01,
		show_value = true,
		-- display_precision = 0.01,
		-- display_scale = 0.01,
		menu_id = menu_id,
		priority = 99
	})

	menu_alignment_preset = MenuHelper:AddToggle({
		id = "ChatTypingInfo_menus_use_alignment_preset",
		title = "ChatTypingInfo_menus_use_alignment_preset",
		desc = "ChatTypingInfo_menus_use_alignment_preset_desc",
		callback = "ChatTypingInfo_toggle_menu",
		disabled = not ChatTypingInfo.settings.menus_info_enabled,
		value = ChatTypingInfo.settings.menus_use_alignment_preset,
		menu_id = menu_id,
		priority = 98
	})

	local disabled_menu_extras = ChatTypingInfo.settings.menus_use_alignment_preset
	if not ChatTypingInfo.settings.menus_info_enabled then
		disabled_menu_extras = true
	end
	menu_slider_w = MenuHelper:AddSlider({
		id = "ChatTypingInfo_menus_alignment_w",
		title = "ChatTypingInfo_menus_alignment_w",
		desc = "ChatTypingInfo_menus_alignment_w_desc",
		callback = "ChatTypingInfo_slider_menu",
		disabled = disabled_menu_extras,
		value = ChatTypingInfo.settings.menus_alignment_w,
		min = 0,
		max = 500,
		step = 0.1,
		show_value = true,
		-- display_precision = 0.1,
		-- display_scale = 0.01,
		menu_id = menu_id,
		priority = 97
	})

	menu_slider_h = MenuHelper:AddSlider({
		id = "ChatTypingInfo_menus_alignment_h",
		title = "ChatTypingInfo_menus_alignment_h",
		desc = "ChatTypingInfo_menus_alignment_h_desc",
		callback = "ChatTypingInfo_slider_menu",
		disabled = disabled_menu_extras,
		value = ChatTypingInfo.settings.menus_alignment_h,
		min = 0,
		max = 500,
		step = 0.1,
		show_value = true,
		-- display_precision = 0.1,
		-- display_scale = 0.01,
		menu_id = menu_id,
		priority = 96
	})

	menu_slider_x = MenuHelper:AddSlider({
		id = "ChatTypingInfo_menus_alignment_x",
		title = "ChatTypingInfo_menus_alignment_x",
		desc = "ChatTypingInfo_menus_alignment_x_desc",
		callback = "ChatTypingInfo_slider_menu",
		disabled = disabled_menu_extras,
		value = ChatTypingInfo.settings.menus_alignment_x,
		min = -200,
		max = 1500,
		step = 1,
		show_value = true,
		-- display_precision = 1,
		-- display_scale = 1,
		menu_id = menu_id,
		priority = 95
	})

	menu_slider_y = MenuHelper:AddSlider({
		id = "ChatTypingInfo_menus_alignment_y",
		title = "ChatTypingInfo_menus_alignment_y",
		desc = "ChatTypingInfo_menus_alignment_y_desc",
		callback = "ChatTypingInfo_slider_menu",
		disabled = disabled_menu_extras,
		value = ChatTypingInfo.settings.menus_alignment_y,
		min = -200,
		max = 1500,
		step = 1,
		show_value = true,
		-- display_precision = 1,
		-- display_scale = 1,
		menu_id = menu_id,
		priority = 94
	})

	menu_slider_font = MenuHelper:AddSlider({
		id = "ChatTypingInfo_menus_font_size",
		title = "ChatTypingInfo_menus_font_size",
		desc = "ChatTypingInfo_menus_font_size_desc",
		callback = "ChatTypingInfo_slider_menu",
		disabled = disabled_menu_extras,
		value = ChatTypingInfo.settings.menus_font_size,
		min = 0,
		max = 128,
		step = 1,
		show_value = true,
		-- display_precision = 1,
		-- display_scale = 1,
		menu_id = menu_id,
		priority = 93
	})

	MenuHelper:AddDivider({
		id = "ChatTypingInfo_divider_1",
		size = 16,
		menu_id = menu_id,
		priority = 92
	})

	MenuHelper:AddToggle({
		id = "ChatTypingInfo_in_game_info_enabled",
		title = "ChatTypingInfo_in_game_info_enabled",
		desc = "ChatTypingInfo_in_game_info_enabled_desc",
		callback = "ChatTypingInfo_toggle_ingame",
		value = ChatTypingInfo.settings.in_game_info_enabled,
		menu_id = menu_id,
		priority = 91
	})

	game_slider_alpha = MenuHelper:AddSlider({
		id = "ChatTypingInfo_in_game_alpha",
		title = "ChatTypingInfo_in_game_alpha",
		desc = "ChatTypingInfo_in_game_alpha_desc",
		callback = "ChatTypingInfo_slider_ingame",
		disabled = not ChatTypingInfo.settings.in_game_info_enabled,
		value = ChatTypingInfo.settings.in_game_alpha,
		min = 0,
		max = 1,
		step = 0.01,
		show_value = true,
		-- display_precision = 0.01,
		-- display_scale = 0.01,
		menu_id = menu_id,
		priority = 90
	})

	game_alignment_preset = MenuHelper:AddToggle({
		id = "ChatTypingInfo_in_game_use_alignment_preset",
		title = "ChatTypingInfo_in_game_use_alignment_preset",
		desc = "ChatTypingInfo_in_game_use_alignment_preset_desc",
		callback = "ChatTypingInfo_toggle_ingame",
		disabled = not ChatTypingInfo.settings.in_game_info_enabled,
		value = ChatTypingInfo.settings.in_game_use_alignment_preset,
		menu_id = menu_id,
		priority = 89
	})

	local disabled_ingame_extras = ChatTypingInfo.settings.in_game_use_alignment_preset
	if not ChatTypingInfo.settings.in_game_info_enabled then
		disabled_ingame_extras = true
	end
	game_slider_w = MenuHelper:AddSlider({
		id = "ChatTypingInfo_in_game_alignment_w",
		title = "ChatTypingInfo_in_game_alignment_w",
		desc = "ChatTypingInfo_in_game_alignment_w_desc",
		callback = "ChatTypingInfo_slider_ingame",
		disabled = disabled_ingame_extras,
		value = ChatTypingInfo.settings.in_game_alignment_w,
		min = 0,
		max = 500,
		step = 0.1,
		show_value = true,
		-- display_precision = 0.1,
		-- display_scale = 0.01,
		menu_id = menu_id,
		priority = 88
	})

	game_slider_h = MenuHelper:AddSlider({
		id = "ChatTypingInfo_in_game_alignment_h",
		title = "ChatTypingInfo_in_game_alignment_h",
		desc = "ChatTypingInfo_in_game_alignment_h_desc",
		callback = "ChatTypingInfo_slider_ingame",
		disabled = disabled_ingame_extras,
		value = ChatTypingInfo.settings.in_game_alignment_h,
		min = 0,
		max = 500,
		step = 0.1,
		show_value = true,
		-- display_precision = 0.1,
		-- display_scale = 0.01,
		menu_id = menu_id,
		priority = 87
	})

	game_slider_x = MenuHelper:AddSlider({
		id = "ChatTypingInfo_in_game_alignment_x",
		title = "ChatTypingInfo_in_game_alignment_x",
		desc = "ChatTypingInfo_in_game_alignment_x_desc",
		callback = "ChatTypingInfo_slider_ingame",
		disabled = disabled_ingame_extras,
		value = ChatTypingInfo.settings.in_game_alignment_x,
		min = -200,
		max = 1500,
		step = 1,
		show_value = true,
		-- display_precision = 1,
		-- display_scale = 1,
		menu_id = menu_id,
		priority = 86
	})

	game_slider_y = MenuHelper:AddSlider({
		id = "ChatTypingInfo_in_game_alignment_y",
		title = "ChatTypingInfo_in_game_alignment_y",
		desc = "ChatTypingInfo_in_game_alignment_y_desc",
		callback = "ChatTypingInfo_slider_ingame",
		disabled = disabled_ingame_extras,
		value = ChatTypingInfo.settings.in_game_alignment_y,
		min = -200,
		max = 1500,
		step = 1,
		show_value = true,
		-- display_precision = 1,
		-- display_scale = 1,
		menu_id = menu_id,
		priority = 85
	})

	game_slider_font = MenuHelper:AddSlider({
		id = "ChatTypingInfo_in_game_font_size",
		title = "ChatTypingInfo_in_game_font_size",
		desc = "ChatTypingInfo_in_game_font_size_desc",
		callback = "ChatTypingInfo_slider_ingame",
		disabled = disabled_ingame_extras,
		value = ChatTypingInfo.settings.in_game_font_size,
		min = 0,
		max = 128,
		step = 1,
		show_value = true,
		-- display_precision = 1,
		-- display_scale = 1,
		menu_id = menu_id,
		priority = 84
	})

	nodes[menu_id] = MenuHelper:BuildMenu(menu_id, { back_callback = "ChatTypingInfo_save", area_bg = "half" })
	MenuHelper:AddMenuItem(nodes.blt_options, menu_id, "ChatTypingInfo_title")
end)

-- locs
Hooks:Add("LocalizationManagerPostInit", "ChatTypingInfo_option_loc", function(loc)
	local chosen_language = BLT.Localization:get_language().language
	if not io.file_is_readable(ChatTypingInfo._path .. "loc/" .. chosen_language .. ".json") then
		chosen_language = "en"
	end
	loc:load_localization_file(ChatTypingInfo._path .. "loc/" .. chosen_language .. ".json")
end)
