if not ChatTypingInfo then
	dofile(ModPath.."lua/chat_info_base.lua")
end

-- menus chat stuff

-- if received a message from peer, remove "x is typing" from them. funnily enough this hook is reponsible for all msg recieves, regardless of games state
Hooks:PostHook(ChatManager, "receive_message_by_peer", "receive_message_by_peer_ChatTypingInfo_post", function (self, channel_id, peer)
	if tonumber(channel_id) == 1 then
		peer._last_typing_info_t = nil
	end
end)

-- yep
Hooks:PostHook(ChatGui, "key_press", "key_press_chat_info", function (self, o, k)
	ChatTypingInfo:InformPeersAboutTyping(k)
end)

-- yep
function ChatGui:update_info_text()
	local text, ranges = ChatTypingInfo:GetTypingWarningText()
	local info_panel_text = self._hud_panel:child("info_text")
	info_panel_text:set_text(text)
	
	if next(ranges) ~= nil then
		for i, range in ipairs(ranges) do
			info_panel_text:set_range_color(range.from, range.to, tweak_data.chat_colors[range.id])
		end
	end
end

-- move standard chat window up. TODO: call this function whenever we adjust font via custom options?
Hooks:OverrideFunction(ChatGui, "set_leftbottom", function (self, left, bottom)
	self._panel:set_left(left)
	local adjust_by = 24
	if not ChatTypingInfo.settings.menus_use_alignment_preset then
		adjust_by = ChatTypingInfo.settings.menus_font_size * 1.2
	end
	self._panel:set_bottom(self._panel:parent():h() - bottom + adjust_by)
end)

-- only called by mod options tweaking. TODO: make the standard chat window move up or down whenever font is updated, cause otherwise it doesnt make sense
function ChatGui:update_text_panel_visuals()
	local tpl = ChatTypingInfo.text_panel_menus
	local panel = self._chat_info_text
	panel:set_visible(ChatTypingInfo.settings.menus_info_enabled)
	panel:set_x(tpl.x_override or (self._panel:x() + tpl.x_shift))
	panel:set_y(tpl.y_override or (self._panel:h() + tpl.h_shift))
	panel:set_w(tpl.w_override or (self._panel:w() + tpl.w_shift))
	panel:set_h(tpl.h_override or (self._panel:h() + tpl.h_shift))
	panel:set_alpha(ChatTypingInfo.settings.menus_alpha or 1)
	--panel:set_font(tpg.font_override or tweak_data.menu.pd2_small_font) -- evidently cant update font after it was setup without crashes, unless the func is named smth else?
	panel:set_font_size(tpl.font_size_override or tweak_data.menu.pd2_small_font_size)
	if ChatTypingInfo.settings.menus_use_alignment_preset then
		self._chat_info_text:set_left(self._panel:left() + self._input_panel:left() + self._input_panel:child("input_text"):left())
	end
end

-- our "x is typing panel" in menus/briefing
Hooks:PostHook(ChatGui, "init", "init_chat_info", function (self)
	local tpl = ChatTypingInfo.text_panel_menus
	self._chat_info_text = self._hud_panel:text({
		name = "info_text",
		text = "",
		valign = "bottom",
		wrap = true,
		word_wrap = false,
		visible = ChatTypingInfo.settings.menus_info_enabled,
		font = tweak_data.menu.pd2_small_font,
		font_size = tpl.font_size_override or tweak_data.menu.pd2_small_font_size, 
		x = tpl.x_override or (self._panel:x() + tpl.x_shift),
		y = tpl.y_override or (self._panel:h() + tpl.h_shift),
		w = tpl.w_override or (self._panel:w() + tpl.w_shift),
		h = tpl.h_override or (self._panel:h() + tpl.h_shift),
		color = Color.white,
		alpha = ChatTypingInfo.settings.menus_alpha or 1,
		layer = 50
	})
	if ChatTypingInfo.settings.menus_use_alignment_preset then
		self._chat_info_text:set_left(self._panel:left() + self._input_panel:left() + self._input_panel:child("input_text"):left())
		--self._chat_info_text = text -- wtf even is this??
	end
end)

-- allign to vanilla chat?
Hooks:PostHook(ChatGui, "_layout_input_panel", "_layout_input_panel_chat_info", function (self)
	local adjust_by = 24
	if not ChatTypingInfo.settings.menus_use_alignment_preset then
		adjust_by = ChatTypingInfo.settings.menus_font_size * 1.2
	end
	self._input_panel:set_y(self._input_panel:parent():h() - self._input_panel:h() - adjust_by)
end)

-- allow for chat adjusting mods to be compatible with this mod by allowing overrides on chat on-screen location, font size etc
-- if you want to add support for this mod you can create a post hook for this function to override appropraite parmaeters, just make sure that your mod's priority is lower then 999
function ChatTypingInfo:SetupMenuTextPanelProperties()
	
	ChatTypingInfo.text_panel_menus = {
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
	
	if ChatTypingInfo.settings.menus_use_alignment_preset then
		ChatTypingInfo.text_panel_menus.h_shift = 120
	else
		ChatTypingInfo.text_panel_menus.w_override = ChatTypingInfo.settings.menus_alignment_w
		ChatTypingInfo.text_panel_menus.h_override = ChatTypingInfo.settings.menus_alignment_h
		ChatTypingInfo.text_panel_menus.x_override = ChatTypingInfo.settings.menus_alignment_x
		ChatTypingInfo.text_panel_menus.y_override = ChatTypingInfo.settings.menus_alignment_y
		ChatTypingInfo.text_panel_menus.font_size_override = ChatTypingInfo.settings.menus_font_size
	end
	
end
-- run it once on boot
ChatTypingInfo:SetupMenuTextPanelProperties()

-- only called if user is adjusting settings in the mod's menu, resets visuals
function ChatTypingInfo:UpdateMenuTextPanel()

	-- reset properties
	ChatTypingInfo:SetupMenuTextPanelProperties()
	
	-- and if not in game, update already existing panel
	local state = ChatTypingInfo:GetGameState()
	if state == "menus" or state == "pre_game_lobby" then
		if not managers.menu_component._game_chat_gui then
			return
		end
		managers.menu_component._game_chat_gui:update_text_panel_visuals()
	end
end