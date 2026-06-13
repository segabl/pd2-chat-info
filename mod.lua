-- setup
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

function ChatTypingInfo:Save()
	io.save_as_json(ChatTypingInfo.settings, ChatTypingInfo._save_path)
end

function ChatTypingInfo:Load()
	local settings = io.file_is_readable(ChatTypingInfo._save_path) and io.load_as_json(ChatTypingInfo._save_path) or {}
	for k, v in pairs(settings) do
		ChatTypingInfo.settings[k] = v
	end
end

ChatTypingInfo:Load()

function ChatTypingInfo:GetGameState()
	if not Utils:IsInGameState() then
		return "menus"
	else
		if (BaseNetworkHandler and BaseNetworkHandler._gamestate_filter and BaseNetworkHandler._gamestate_filter.any_ingame_playing) then
			if BaseNetworkHandler._gamestate_filter.any_ingame_playing[game_state_machine:last_queued_state_name()] == true then
				return "in_match"
			else
				return "pre_game_lobby"
			end
		else
			return "unidentifiable" -- can this even happen?
		end
	end
end

-- "x is typing" text itself
function ChatTypingInfo:GetTypingWarningText()
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

-- tell others i'm typing
function ChatTypingInfo:InformPeersAboutTyping(key_pressed)
	local t = TimerManager:game():time()
	local valid_key = key_pressed ~= Idstring("enter") and key_pressed ~= Idstring("esc") -- add checks fow windows key and/or alt+tab?
	if valid_key and (not ChatTypingInfo._last_press_t or t > ChatTypingInfo._last_press_t + 2) then
		LuaNetworking:SendToPeers("typing_info", "")
		ChatTypingInfo._last_press_t = t
	elseif not valid_key then
		ChatTypingInfo._last_press_t = nil
	end
end

-- if received needed network message from peer, add "x is typing" text for them
Hooks:Add("NetworkReceivedData", "NetworkReceivedData_ChatTypingInfo", function(sender, id, data)
	local peer = LuaNetworking:GetPeers()[sender]
	if id == "typing_info" and peer then
		peer._last_typing_info_t = TimerManager:game():time()
	end
end)

-- updater which is ran to check if text needs to be adjusted
Hooks:PostHook(MenuComponentManager, "update", "ChatTypingInfo_updater", function(self, t)

	-- refresh rate
	if self._last_chat_typing_info_update_t and self._last_chat_typing_info_update_t + 0.1 < t then
		return
	else
		self._last_chat_typing_info_update_t = t
	end

	local state = ChatTypingInfo:GetGameState()
	if state == "menus" or state == "pre_game_lobby" then
		if self._game_chat_gui then
			self._game_chat_gui:update_info_text()
		end
	elseif state == "in_match" then
		HUDChat:UpdateIngameTypingInfoText()
	end
end)
