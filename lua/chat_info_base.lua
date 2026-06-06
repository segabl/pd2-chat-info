-- setup
if ChatTypingInfo then
	return
end

_G.ChatTypingInfo = {
	_path = ModPath,
	_save_path = SavePath.."ChatTypingInfo_save.txt",
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

-- user settings
function ChatTypingInfo:Save()
	local file = io.open(ChatTypingInfo._save_path, 'w+')
	if file then
		file:write(json.encode(ChatTypingInfo.settings))
		file:close()
	end
end
function ChatTypingInfo:Load()
	local file = io.open(ChatTypingInfo._save_path, 'r')
	if file then
		for i, v in pairs(json.decode(file:read('*all')) or {}) do
			ChatTypingInfo.settings[i] = v
		end
		file:close()
	end
end
ChatTypingInfo:Load()
ChatTypingInfo:Save()

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
	local amount = 0
	local t = TimerManager:game():time()
	local ranges = {}
	local peers = managers.network and managers.network:session() and managers.network:session():all_peers() -- LuaNetworking:GetPeers() is safer, but doesn't grab our own player, and we need our own player when we configure panels in mod options
	
	if peers then
		for _, peer in pairs(peers) do
			if peer and peer._last_typing_info_t and t < peer._last_typing_info_t + 4 then
				text = text .. (amount > 0 and ", " or "")
				table.insert(ranges, { id = peer:id(), from = utf8.len(text), to = utf8.len(text .. peer:name()) })
				text = text .. peer:name()
				amount = amount + 1
			end
		end
		
		if amount > 0 then
			local amount_dots = math.floor((t * 2) % 4)
			local part_1_plur = managers.localization:text("ChatTypingInfo_xIsTyping_message_part_1_plural")
			local part_1_sing = managers.localization:text("ChatTypingInfo_xIsTyping_message_part_1_singular")
			local part_2_plur = managers.localization:text("ChatTypingInfo_xIsTyping_message_part_2_plural")
			local part_2_sing = managers.localization:text("ChatTypingInfo_xIsTyping_message_part_2_singular")
			text = text .. " " .. (amount > 1 and part_1_plur or part_1_sing) .. (amount > 1 and part_2_plur or part_2_sing) .. string.rep(".", amount_dots)
			if amount > 1 then
				text = text:gsub("(.*),", "%1 and")
				ranges[#ranges].from = ranges[#ranges].from + 3
				ranges[#ranges].to = ranges[#ranges].to + 3
			end
		end
	end
	
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
Hooks:PostHook(MenuComponentManager, "update", "ChatTypingInfo_updater", function (self, t)
	
	-- refresh rate
	if self._last_chat_typing_info_update_t and self._last_chat_typing_info_update_t + 0.1 < t then
		return
	else
		self._last_chat_typing_info_update_t = t
	end
	
	local state = ChatTypingInfo:GetGameState()
	if state == "menus" or state == "pre_game_lobby" then
		if not self._game_chat_gui then
			return
		end
		self._game_chat_gui:update_info_text()
	elseif state == "in_match" then
		HUDChat:UpdateIngameTypingInfoText()
	end
end)