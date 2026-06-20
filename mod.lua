if ChatTypingInfo then
	return
end

_G.ChatTypingInfo = {
	_path = ModPath,
	_save_path = SavePath .. "ChatTypingInfo_save.txt",
	settings = {
		menus_info_enabled = true,
		menus_alpha = 0.8,
		menus_use_alignment_preset = true,
		menus_alignment_w = 300,
		menus_alignment_h = 150,
		menus_alignment_x = 120,
		menus_alignment_y = 500,
		menus_font_size = 20,
		in_game_info_enabled = true,
		in_game_alpha = 1,
		in_game_use_alignment_preset = true,
		in_game_alignment_w = 380,
		in_game_alignment_h = 180,
		in_game_alignment_x = 0,
		in_game_alignment_y = 608,
		in_game_font_size = 20,
	}
}

function ChatTypingInfo:save()
	io.save_as_json(ChatTypingInfo.settings, ChatTypingInfo._save_path)
end

function ChatTypingInfo:load()
	local settings = io.file_is_readable(ChatTypingInfo._save_path) and io.load_as_json(ChatTypingInfo._save_path) or {}
	for k, v in pairs(settings) do
		ChatTypingInfo.settings[k] = v
	end
end

function ChatTypingInfo:get_typing_text()
	local text = ""
	local t = TimerManager:game():time()
	local ranges = {}
	local peers = managers.network and managers.network:session() and managers.network:session():all_peers() or {}

	peers = table.filter_list(peers, function(peer) return peer and peer._last_typing_info_t and t < peer._last_typing_info_t + 4 end)
	if #peers == 0 then
		return text, ranges
	end

	for i, peer in pairs(peers) do
		if i > 1 and i == #peers then
			text = text .. " " .. managers.localization:text("ChatTypingInfo_xIsTyping_message_and") .. " "
		elseif i > 1 then
			text = text .. ", "
		end
		table.insert(ranges, { id = peer:id(), from = utf8.len(text), to = utf8.len(text .. peer:name()) })
		text = text .. peer:name()
	end

	local amount_dots = math.floor((t * 2) % 4)
	local typing_id = #peers > 1 and "ChatTypingInfo_xIsTyping_message_plural" or "ChatTypingInfo_xIsTyping_message_singular"
	text = text .. " " .. managers.localization:text(typing_id) .. string.rep(".", amount_dots)

	return text, ranges
end

function ChatTypingInfo:send_typing(key_pressed)
	local t = TimerManager:game():time()
	local valid_key = key_pressed ~= Idstring("enter") and key_pressed ~= Idstring("esc") -- add checks fow windows key and/or alt+tab?
	if valid_key and (not ChatTypingInfo._last_press_t or t > ChatTypingInfo._last_press_t + 2) then
		NetworkHelper:SendToPeers("typing_info", "")
		ChatTypingInfo._last_press_t = t
	elseif not valid_key then
		ChatTypingInfo._last_press_t = nil
	end
end

-- allow for chat adjusting mods to be compatible with this mod by allowing overrides on chat on-screen location, font size etc
-- if you want to add support for this mod you can create a post hook for this function to override appropraite parmaeters, just make sure that your mod's priority is lower then 999
function ChatTypingInfo:setup_menu_typing_panel()

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

-- only called if user is adjusting settings in the mod's menu, resets visuals
function ChatTypingInfo:update_menu_typing_panel()

	-- reset properties
	ChatTypingInfo:setup_menu_typing_panel()

	-- and if not in game, update already existing panel
	if not self:is_ingame() and managers.menu_component._game_chat_gui then
		managers.menu_component._game_chat_gui:update_text_panel_visuals()
	end
end

function ChatTypingInfo:is_ingame()
	return Utils:IsInHeist() and managers.hud and managers.hud._hud_chat_ingame
end

ChatTypingInfo:load()

NetworkHelper:AddReceiveHook("typing_info", "typing_info", function(data, sender)
	local peer = managers.network:session():peer(sender)
	peer._last_typing_info_t = TimerManager:game():time()
end)

Hooks:PostHook(MenuComponentManager, "update", "ChatTypingInfo_updater", function(self, t)
	if self._next_typing_update_t and self._next_typing_update_t > t then
		return
	end

	self._next_typing_update_t = t + 0.1

	if ChatTypingInfo:is_ingame() then
		managers.hud._hud_chat_ingame:update_typing_text()
	elseif self._game_chat_gui then
		self._game_chat_gui:update_typing_text()
	end
end)
