if not ChatTypingInfo then
	dofile(ModPath.."lua/chat_info_base.lua")
end

-- in game chat stuff

-- create our panel
Hooks:PostHook(HUDChat, "init", "ChatTypingInfo_HUDChat_init_post", function(self, ...)
	self:SetupIngameTypingTextPanelProperties()
end)

-- report using in game chat to peers
Hooks:PostHook(HUDChat, "key_press", "chat_info_in_game_chat_key_press_post", function(self, o, k)
	ChatTypingInfo:InformPeersAboutTyping(k)
end)

-- allow for chat adjusting mods to be compatible with this mod by allowing overrides on chat on-screen location, font size etc
-- if you want to add support for this mod you can create a post hook for this function to override appropraite parmaeters, just make sure that your mod's priority is lower then 999
function HUDChat:SetupIngameTypingTextPanelProperties()
	
	if not HUDChat then return end -- idek, just keep it
	
	ChatTypingInfo.text_panel_game = {
		w_override = nil,
		h_override = nil,
		x_override = nil,
		y_override = nil,
		w_shift = 0,
		h_shift = 0,
		x_shift = 0,
		y_shift = 0,
		font_size_override = nil
	}
	
	if ChatTypingInfo.settings.in_game_use_alignment_preset then
		-- vanilla chat's magical number offset
		ChatTypingInfo.text_panel_game.y_shift = -112
		
		-- VHUD SUPPORT -- similary can add any other chat adjusting mod
		if VHUDPlus then
			if VHUDPlus:getSetting({"HUDChat", "ENABLED"}, true) then
				if HUDChat.LINE_HEIGHT and HUDChat.MAX_OUTPUT_LINES then
					ChatTypingInfo.text_panel_game.h_override = HUDChat.LINE_HEIGHT * (HUDChat.MAX_OUTPUT_LINES + 1)
				end
				if HUDChat.WIDTH then
					ChatTypingInfo.text_panel_game.w_override = HUDChat.WIDTH
				end
				if HUDChat.LINE_HEIGHT then
					ChatTypingInfo.text_panel_game.font_size_override = HUDChat.LINE_HEIGHT * 0.95
				end
				ChatTypingInfo.text_panel_game.x_shift = VHUDPlus:getSetting({"HUDChat", "X_POS_FIX"}, 0)
				ChatTypingInfo.text_panel_game.y_shift = 0 - VHUDPlus:getSetting({"HUDChat", "Y_POS"}, 112)
			end
		end
		
		if VoidUI and VoidUI.options.enable_chat then
			ChatTypingInfo.text_panel_game.y_override = self._panel:parent():h() / 2 + 140
		end
	else
		ChatTypingInfo.text_panel_game.w_override = ChatTypingInfo.settings.in_game_alignment_w
		ChatTypingInfo.text_panel_game.h_override = ChatTypingInfo.settings.in_game_alignment_h
		ChatTypingInfo.text_panel_game.x_override = ChatTypingInfo.settings.in_game_alignment_x
		ChatTypingInfo.text_panel_game.y_override = ChatTypingInfo.settings.in_game_alignment_y
		ChatTypingInfo.text_panel_game.font_size_override = ChatTypingInfo.settings.in_game_font_size
	end
	
end

-- only called if user is adjusting settings in the mod's menu, responsible for text panel's visuals
function HUDChat:UpdateIngameTypingTextPanel()
	
	-- reset properties
	self:SetupIngameTypingTextPanelProperties()
	
	local state = ChatTypingInfo:GetGameState()
	if state == "in_match" then
		
		local chat_window = managers.hud._hud_chat_ingame
		if chat_window then
			local screen_panel = chat_window._panel:parent()
			local tpg = ChatTypingInfo.text_panel_game
			if screen_panel:child("typing_alert") then
				local panel = screen_panel:child("typing_alert")
				panel:set_visible(ChatTypingInfo.settings.in_game_info_enabled)
				panel:set_w(tpg.w_override or (screen_panel:w() + tpg.w_shift))
				panel:set_h(tpg.h_override or (screen_panel:h() + tpg.h_shift))
				panel:set_x(tpg.x_override or (screen_panel:x() + tpg.x_shift))
				panel:set_y(tpg.y_override or (screen_panel:h() + tpg.y_shift))
				panel:set_alpha(ChatTypingInfo.settings.in_game_alpha or 1)
				--panel:set_font(tpg.font_override or tweak_data.menu.pd2_small_font) -- evidently cant update font after it was setup without crashes, unless the func is named smth else?
				panel:set_font_size(tpg.font_size_override or tweak_data.menu.pd2_small_font_size)
			end
		end
		
	end
end

-- update panel's text
function HUDChat:UpdateIngameTypingInfoText()
	
	local chat_window = managers.hud._hud_chat_ingame
	if chat_window then
		local screen_panel = chat_window._panel:parent()
		local tpg = ChatTypingInfo.text_panel_game
		
		-- create our info panel with overrides
		if not screen_panel:child("typing_alert") then
			local typing_alert = screen_panel:text({
				name = "typing_alert",
				visible = ChatTypingInfo.settings.in_game_info_enabled,
				text = "",
				valign = "left",
				align = "left",
				layer = 1,
				color = Color.white,
				wrap = true,
				word_wrap = false,
				alpha = ChatTypingInfo.settings.in_game_alpha or 1,
				font = tpg.font_override or tweak_data.menu.pd2_small_font,
				font_size = tpg.font_size_override or tweak_data.menu.pd2_small_font_size,
				w = tpg.w_override or (screen_panel:w() + tpg.w_shift),
				h = tpg.h_override or (screen_panel:h() + tpg.h_shift),
				x = tpg.x_override or (screen_panel:x() + tpg.x_shift),
				y = tpg.y_override or (screen_panel:h() + tpg.y_shift)
			})
		else
			local text, ranges = ChatTypingInfo:GetTypingWarningText()
			local info_panel_text = screen_panel:child("typing_alert")
			info_panel_text:set_text(text)
			
			if next(ranges) ~= nil then
				for i, range in ipairs(ranges) do
					info_panel_text:set_range_color(range.from, range.to, tweak_data.chat_colors[range.id])
				end
			end
		end
	end
	
end