if not ChatTypingInfo then
	dofile(ModPath .. "mod.lua")
end

-- menus chat stuff

Hooks:PostHook(ChatManager, "init", "init_ChatTypingInfo_post", function()
	ChatTypingInfo:setup_menu_typing_panel()
end)

-- if received a message from peer, remove "x is typing" from them. funnily enough this hook is reponsible for all msg recieves, regardless of games state
Hooks:PostHook(ChatManager, "receive_message_by_peer", "receive_message_by_peer_ChatTypingInfo_post", function(self, channel_id, peer)
	if tonumber(channel_id) == 1 then
		peer._last_typing_info_t = nil
	end
end)

Hooks:PostHook(ChatGui, "key_press", "key_press_chat_info", function(self, o, k)
	ChatTypingInfo:send_typing(k)
end)

function ChatGui:update_typing_text()
	if not self._chat_info_text then
		return
	end

	local text, ranges = ChatTypingInfo:get_typing_text()
	self._chat_info_text:set_text(text)
	for _, range in pairs(ranges) do
		self._chat_info_text:set_range_color(range.from, range.to, tweak_data.chat_colors[range.id])
	end
end

-- move standard chat window up. TODO: call this function whenever we adjust font via custom options?
Hooks:OverrideFunction(ChatGui, "set_leftbottom", function(self, left, bottom)
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
Hooks:PostHook(ChatGui, "init", "init_chat_info", function(self)
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
	end
end)

-- allign to vanilla chat?
Hooks:PostHook(ChatGui, "_layout_input_panel", "_layout_input_panel_chat_info", function(self)
	local adjust_by = 24
	if not ChatTypingInfo.settings.menus_use_alignment_preset then
		adjust_by = ChatTypingInfo.settings.menus_font_size * 1.2
	end
	self._input_panel:set_y(self._input_panel:parent():h() - self._input_panel:h() - adjust_by)
end)
