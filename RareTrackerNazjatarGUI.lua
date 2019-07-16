local _, data = ...

local RTN = data.RTN

local entity_name_width = 180
local entity_status_width = 50 
local frame_padding = 4
local favorite_rares_width = 10

local shard_id_frame_height = 16

background_opacity = 0.4
front_opacity = 0.6

-- ####################################################################
-- ##                              GUI                               ##
-- ####################################################################

function RTN:InitializeShardNumberFrame()
	local f = CreateFrame("Frame", "RTN.shard_id_frame", self)
	f:SetSize(entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width, shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.status_text = f:CreateFontString(nil, nil, "GameFontNormal")
	f.status_text:SetPoint("TOPLEFT", 10 + 2 * favorite_rares_width + 2 * frame_padding, -3)
	f.status_text:SetText("Shard ID: Unknown")
	f:SetPoint("TOPLEFT", self, frame_padding, -frame_padding)
	
	return f
end

function RTN:InitializeFavoriteMarkerFrame()
	local f = CreateFrame("Frame", "RTN.RTNDB.favorite_rares_frame", self)
	f:SetSize(favorite_rares_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	
	f.checkboxes = {}
	local height_offset = -(2 * frame_padding + shard_id_frame_height)
	for i=1, #RTN.rare_ids do
		local npc_id = RTN.rare_ids[i]
		f.checkboxes[npc_id] = CreateFrame("CheckButton", "RTN.shard_id_frame.checkbox["..i.."]", f)
		f.checkboxes[npc_id]:SetSize(10, 10)
		local texture = f.checkboxes[npc_id]:CreateTexture(nil, "BACKGROUND")
		texture:SetColorTexture(0, 0, 0, front_opacity)
		texture:SetAllPoints(f.checkboxes[npc_id])
		f.checkboxes[npc_id].texture = texture
		f.checkboxes[npc_id]:SetPoint("TOPLEFT", 1, -(i - 1) * 12 - 5)
		
		-- Add an action listener.
		f.checkboxes[npc_id]:SetScript("OnClick", 
			function()
				if RTNDB.favorite_rares[npc_id] then
					RTNDB.favorite_rares[npc_id] = nil
					f.checkboxes[npc_id].texture:SetColorTexture(0, 0, 0, front_opacity)
				else
					RTNDB.favorite_rares[npc_id] = true
					f.checkboxes[npc_id].texture:SetColorTexture(0, 1, 0, 1)
				end
			end
		);
	end
	
	f:SetPoint("TOPLEFT", self, frame_padding, height_offset)
	return f
end

function RTN:InitializeAliveMarkerFrame()
	local f = CreateFrame("Frame", "RTN.alive_marker_frame", self)
	f:SetSize(favorite_rares_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	
	f.checkboxes = {}
	local height_offset = -(2 * frame_padding + shard_id_frame_height)
	for i=1, #RTN.rare_ids do
		local npc_id = RTN.rare_ids[i]
		f.checkboxes[npc_id] = CreateFrame("Button", "RTN.shard_id_frame.checkbox["..i.."]", f)
		
		f.checkboxes[npc_id]:SetSize(10, 10)
		local texture = f.checkboxes[npc_id]:CreateTexture(nil, "BACKGROUND")
		texture:SetColorTexture(0, 0, 0, front_opacity)
		texture:SetAllPoints(f.checkboxes[npc_id])
		f.checkboxes[npc_id].texture = texture
		f.checkboxes[npc_id]:SetPoint("TOPLEFT", 1, -(i - 1) * 12 - 5)
		f.checkboxes[npc_id]:RegisterForClicks("LeftButtonDown", "RightButtonDown")
		
		-- Add an action listener.
		f.checkboxes[npc_id]:SetScript("OnClick", 
			function(self, button, down)
				local name = RTN.rare_names_localized["enUS"][npc_id]
				local health = RTN.current_health[npc_id]
				local last_death = RTN.last_recorded_death[npc_id]
				local loc = RTN.current_coordinates[npc_id]
				
				if button == "LeftButton" then
					if RTN.current_health[npc_id] then
						-- SendChatMessage
						if loc then
							SendChatMessage(string.format("<RTN> %s (%s%%) seen at ~(%.2f, %.2f)", name, health, loc.x, loc.y), "CHANNEL", nil, 1)
						else 
							SendChatMessage(string.format("<RTN> %s (%s%%) seen at ~(N/A)", name, health), "CHANNEL", nil, 1)
						end
					elseif RTN.last_recorded_death[npc_id] ~= nil then
						if GetServerTime() - last_death < 60 then
							SendChatMessage(string.format("<RTN> %s has died", name, GetServerTime() - last_death), "CHANNEL", nil, 1)
						else
							SendChatMessage(string.format("<RTN> %s was last seen ~%s minutes ago", name, math.floor((GetServerTime() - last_death) / 60)), "CHANNEL", nil, 1)
						end
					elseif RTN.is_alive[npc_id] then
						if loc then
							SendChatMessage(string.format("<RTN> %s seen alive, vignette at ~(%.2f, %.2f)", name, loc.x, loc.y), "CHANNEL", nil, 1)
						else
							SendChatMessage(string.format("<RTN> %s seen alive (vignette)", name), "CHANNEL", nil, 1)
						end
					end
				else
					-- does the user have tom tom? if so, add a waypoint if it exists.
					if TomTom ~= nil and loc then
						RTN.waypoints[npc_id] = TomTom:AddWaypointToCurrentZone(loc.x, loc.y, name)
					end
				end
			end
		);
	end
	
	f:SetPoint("TOPLEFT", self, 2 * frame_padding + favorite_rares_width, height_offset)
	return f
end

function RTN:InitializeInterfaceEntityNameFrame()
	local f = CreateFrame("Frame", "RTN.entity_name_frame", self)
	f:SetSize(entity_name_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #RTN.rare_ids do
		local npc_id = RTN.rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil, "GameFontNormal")
		f.strings[npc_id]:SetJustifyH("LEFT")
		f.strings[npc_id]:SetJustifyV("TOP")
		f.strings[npc_id]:SetPoint("TOPLEFT", 10, -(i - 1) * 12 - 4)
		f.strings[npc_id]:SetText(RTN.rare_names_localized["enUS"][npc_id])
	end
	
	f:SetPoint("TOPLEFT", self, 3 * frame_padding + 2 * favorite_rares_width, -(2 * frame_padding + shard_id_frame_height))
	return f
end

function RTN:InitializeInterfaceEntityStatusFrame()
	local f = CreateFrame("Frame", "RTN.entity_status_frame", self)
	f:SetSize(entity_status_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #RTN.rare_ids do
		local npc_id = RTN.rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil, "GameFontNormal")
		f.strings[npc_id]:SetPoint("TOP", 0, -(i - 1) * 12 - 4)
		f.strings[npc_id]:SetText("--")
		f.strings[npc_id]:SetJustifyH("LEFT")
		f.strings[npc_id]:SetJustifyV("TOP")
	end
	
	f:SetPoint("TOPRIGHT", self, -frame_padding, -(2 * frame_padding + shard_id_frame_height))
	return f
end

function RTN:UpdateStatus(npc_id)
	local status_text_frame = RTN.entity_status_frame.strings[npc_id]
	local alive_status_frame = RTN.alive_marker_frame.checkboxes[npc_id]

	if RTN.current_health[npc_id] then
		status_text_frame:SetText(RTN.current_health[npc_id].."%")
		alive_status_frame.texture:SetColorTexture(0, 1, 0, 1)
	elseif RTN.last_recorded_death[npc_id] ~= nil then
		local last_death = RTN.last_recorded_death[npc_id]
		status_text_frame:SetText(math.floor((GetServerTime() - last_death) / 60).."m")
		alive_status_frame.texture:SetColorTexture(0, 0, 1, front_opacity)
	elseif RTN.is_alive[npc_id] then
		status_text_frame:SetText("N/A")
		alive_status_frame.texture:SetColorTexture(0, 1, 0, 1)
	else
		status_text_frame:SetText("--")
		alive_status_frame.texture:SetColorTexture(0, 0, 0, front_opacity)
	end
end

function RTN:UpdateShardNumber(shard_number)
	if shard_number then
		RTN.shard_id_frame.status_text:SetText("Shard ID: "..(shard_number + 42))
	else
		RTN.shard_id_frame.status_text:SetText("Shard ID: Unknown")
	end
end

function RTN:CorrectFavoriteMarks()
	for i=1, #RTN.rare_ids do
		local npc_id = RTN.rare_ids[i]
		
		if RTNDB.favorite_rares[npc_id] then
			self.favorite_rares_frame.checkboxes[npc_id].texture:SetColorTexture(0, 1, 0, 1)
		end
	end
end

function RTN:UpdateDailyKillMark(npc_id)
	if RTN.completion_quest_ids[npc_id] and IsQuestFlaggedCompleted(RTN.completion_quest_ids[npc_id]) then
		self.entity_name_frame.strings[npc_id]:SetText("(x) "..RTN.rare_names_localized["enUS"][npc_id])
	else
		self.entity_name_frame.strings[npc_id]:SetText(RTN.rare_names_localized["enUS"][npc_id])
	end
end

function RTN:UpdateAllDailyKillMarks()
	for i=1, #RTN.rare_ids do
		local npc_id = RTN.rare_ids[i]
		self:UpdateDailyKillMark(npc_id)
	end
end

function RTN:InitializeFavoriteIconFrame(f)
	f.favorite_icon = CreateFrame("Frame", "RTN.favorite_icon", f)
	f.favorite_icon:SetSize(10, 10)
	f.favorite_icon:SetPoint("TOPLEFT", f, frame_padding + 1, -(frame_padding + 3))

	f.favorite_icon.texture = f.favorite_icon:CreateTexture(nil, "OVERLAY")
	f.favorite_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\Favorite.tga")
	f.favorite_icon.texture:SetSize(10, 10)
	f.favorite_icon.texture:SetPoint("CENTER", f.favorite_icon)
	
	f.favorite_icon.tooltip = CreateFrame("Frame", nil, UIParent)
	f.favorite_icon.tooltip:SetSize(300, 18)
	
	local texture = f.favorite_icon.tooltip:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.favorite_icon.tooltip)
	f.favorite_icon.tooltip.texture = texture
	f.favorite_icon.tooltip:SetPoint("TOPLEFT", f, 0, 19)
	f.favorite_icon.tooltip:Hide()
	
	f.favorite_icon.tooltip.text = f.favorite_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.favorite_icon.tooltip.text:SetJustifyH("LEFT")
	f.favorite_icon.tooltip.text:SetJustifyV("TOP")
	f.favorite_icon.tooltip.text:SetPoint("TOPLEFT", f.favorite_icon.tooltip, 5, -3)
	f.favorite_icon.tooltip.text:SetText("Click on the squares to add rares to your favorites.")
	
	f.favorite_icon:SetScript("OnEnter", 
		function(self)
			self.tooltip:Show()
		end
	);
	
	f.favorite_icon:SetScript("OnLeave", 
		function(self)
			self.tooltip:Hide()
		end
	);
end

function RTN:InitializeAnnounceIconFrame(f)
	f.broadcast_icon = CreateFrame("Frame", "RTN.broadcast_icon", f)
	f.broadcast_icon:SetSize(10, 10)
	f.broadcast_icon:SetPoint("TOPLEFT", f, 2 * frame_padding + favorite_rares_width + 1, -(frame_padding + 3))

	f.broadcast_icon.texture = f.broadcast_icon:CreateTexture(nil, "OVERLAY")
	f.broadcast_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\Broadcast.tga")
	f.broadcast_icon.texture:SetSize(10, 10)
	f.broadcast_icon.texture:SetPoint("CENTER", f.broadcast_icon)
	
	f.broadcast_icon.tooltip = CreateFrame("Frame", nil, UIParent)
	f.broadcast_icon.tooltip:SetSize(273, 44)
	
	local texture = f.broadcast_icon.tooltip:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.broadcast_icon.tooltip)
	f.broadcast_icon.tooltip.texture = texture
	f.broadcast_icon.tooltip:SetPoint("TOPLEFT", f, 0, 45)
	f.broadcast_icon.tooltip:Hide()
	
	f.broadcast_icon.tooltip.text1 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text1:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text1:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text1:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -3)
	f.broadcast_icon.tooltip.text1:SetText("Click on the squares to announce rare timers.")
	
	f.broadcast_icon.tooltip.text2 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text2:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text2:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text2:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -15)
	f.broadcast_icon.tooltip.text2:SetText("Left click: report to general chat")
	  
	f.broadcast_icon.tooltip.text3 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text3:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text3:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text3:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -27)
	f.broadcast_icon.tooltip.text3:SetText("Right click: set waypoint if available")
	
	f.broadcast_icon:SetScript("OnEnter", 
		function(self)
			self.tooltip:Show()
		end
	);
	
	f.broadcast_icon:SetScript("OnLeave", 
		function(self)
			self.tooltip:Hide()
		end
	);
end


function RTN:InitializeInterface()
	self:SetSize(entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding, shard_id_frame_height + 3 * frame_padding + #RTN.rare_ids * 12 + 8)
	local texture = self:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, background_opacity)
	texture:SetAllPoints(self)
	self.texture = texture
	self:SetPoint("CENTER")
	
	-- Create a sub-frame for the entity names.
	self.shard_id_frame = self:InitializeShardNumberFrame()
	self.favorite_rares_frame = self:InitializeFavoriteMarkerFrame()
	self.alive_marker_frame = self:InitializeAliveMarkerFrame()
	self.entity_name_frame = self:InitializeInterfaceEntityNameFrame()
	self.entity_status_frame = self:InitializeInterfaceEntityStatusFrame()

	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	
	-- Add icons for the favorite and broadcast columns.
	RTN:InitializeFavoriteIconFrame(self)
	RTN:InitializeAnnounceIconFrame(self)
	
	-- Create a reset button.
	self.reload_button = CreateFrame("Button", "RTN.reload_button", self)
	self.reload_button:SetSize(10, 10)
	self.reload_button:SetPoint("TOPRIGHT", self, -2 * frame_padding, -(frame_padding + 3))

	self.reload_button.texture = self.reload_button:CreateTexture(nil, "OVERLAY")
	self.reload_button.texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\Reload.tga")
	self.reload_button.texture:SetSize(10, 10)
	self.reload_button.texture:SetPoint("CENTER", self.reload_button)
	
	self.reload_button:SetScript("OnClick", 
		function()
			if RTN.current_shard_id then
				print("<RTN> Resetting current rare timers and requesting up-to-date data.")
				RTN.is_alive = {}
				RTN.current_health = {}
				RTN.last_recorded_death = {}
				RTN.recorded_entity_death_ids = {}
				RTN.current_coordinates = {}
				RTN.reported_spawn_uids = {}
				RTN.reported_vignettes = {}
				
				-- Reset the cache.
				RTNDB.previous_records[RTN.current_shard_id] = nil
				
				-- Re-register your arrival in the shard.
				RTN:RegisterArrival(RTN.current_shard_id)
			else
				print("<RTN> Please target a non-player entity prior to reloading, such that the addon can determine the current shard id.")
			end
		end
	);
	
	self:Hide()
end

RTN:InitializeInterface()

-- ####################################################################
-- ##                       Options Interface                        ##
-- ####################################################################



-- Options:
-- Select warning sound
-- Reset Favorites
-- Show/hide minimap icon
-- Enable debug prints

-- The provided sound options.
local sound_options = {}
sound_options[''] = -1
sound_options["Rubber Ducky"] = 566121
sound_options["Cartoon FX"] = 566543
sound_options["Explosion"] = 566982
sound_options["Shing!"] = 566240
sound_options["Wham!"] = 566946
sound_options["Simon Chime"] = 566076
sound_options["War Drums"] = 567275
sound_options["Scourge Horn"] = 567386
sound_options["Pygmy Drums"] = 566508
sound_options["Cheer"] = 567283
sound_options["Humm"] = 569518
sound_options["Short Circuit"] = 568975
sound_options["Fel Portal"] = 569215
sound_options["Fel Nova"] = 568582
sound_options["PVP Flag"] = 569200
sound_options["Beware!"] = 543587
sound_options["Laugh"] = 564859
sound_options["Not Prepared"] = 552503
sound_options["I am Unleashed"] = 554554
sound_options["I see you"] = 554236

local sound_options_inverse = {}
for key, value in pairs(sound_options) do
	sound_options_inverse[value] = key
end

function RTN:IntializeSoundSelectionMenu(parent_frame)
	local f = CreateFrame("frame", "RTN.options_panel.sound_selection", parent_frame, "UIDropDownMenuTemplate")
	UIDropDownMenu_SetWidth(f, 140)
	UIDropDownMenu_SetText(f, sound_options_inverse[RTNDB.selected_sound_number])
	
	f.onClick = function(self, sound_id, arg2, checked)
		RTNDB.selected_sound_number = sound_id
		UIDropDownMenu_SetText(f, sound_options_inverse[RTNDB.selected_sound_number])
		PlaySoundFile(RTNDB.selected_sound_number)
	end
	
	f.initialize = function(self, level, menuList)
		local info = UIDropDownMenu_CreateInfo()
		
		for key, value in pairs(sound_options) do
			info.text = key
			info.arg1 = value
			info.func = f.onClick
			info.menuList = key
			info.checked = RTNDB.selected_sound_number == value
			UIDropDownMenu_AddButton(info)
		end
	end
	
	f.label = f:CreateFontString(nil, "BORDER", "GameFontNormal")
	f.label:SetJustifyH("LEFT")
	f.label:SetText("Favorite sound alert")
	f.label:SetPoint("TOPLEFT", parent_frame)
	
	f:SetPoint("TOPLEFT", f.label, -20, -13)
	
	return f
end

function RTN:IntializeMinimapCheckbox(parent_frame)
	local f = CreateFrame("CheckButton", "RTN.options_panel.minimap_checkbox", parent_frame, "ChatConfigCheckButtonTemplate");
	getglobal(f:GetName() .. 'Text'):SetText(" Show minimap icon");
	f.tooltip = "Show or hide the minimap button.";
	f:SetScript("OnClick", 
		function()
			local zone_id = C_Map.GetBestMapForUnit("player")
		
			RTNDB.minimap_icon_enabled = not RTNDB.minimap_icon_enabled
			if not RTNDB.minimap_icon_enabled then
				RTN.icon:Hide("RTN_icon")
			elseif RTN.target_zones[C_Map.GetBestMapForUnit("player")] then
				RTN.icon:Show("RTN_icon")
			end
		end
	);
	f:SetChecked(RTNDB.minimap_icon_enabled)
	f:SetPoint("TOPLEFT", parent_frame, 0, -53)
end

function RTN:IntializeDebugCheckbox(parent_frame)
	local f = CreateFrame("CheckButton", "RTN.options_panel.debug_checkbox", parent_frame, "ChatConfigCheckButtonTemplate");
	getglobal(f:GetName() .. 'Text'):SetText(" Enable debug mode");
	f.tooltip = "Show or hide the minimap button.";
	f:SetScript("OnClick", 
		function()
			RTNDB.debug_enabled = not RTNDB.debug_enabled
		end
	);
	f:SetChecked(RTNDB.debug_enabled)
	f:SetPoint("TOPLEFT", parent_frame, 0, -75)
end

function RTN:InitializeConfigMenu()
	RTN.options_panel = CreateFrame("Frame", "RTN.options_panel", UIParent)
	RTN.options_panel.name = "RareTrackerNazjatar"
	InterfaceOptions_AddCategory(RTN.options_panel)
	
	RTN.options_panel.frame = CreateFrame("Frame", "RTN.options_panel.frame", RTN.options_panel)
	RTN.options_panel.frame:SetPoint("TOPLEFT", RTN.options_panel, 11, -14)
	RTN.options_panel.frame:SetSize(500, 500)

	RTN.options_panel.sound_selector = RTN:IntializeSoundSelectionMenu(RTN.options_panel.frame)
	RTN.options_panel.minimap_checkbox = RTN:IntializeMinimapCheckbox(RTN.options_panel.frame)
	RTN.options_panel.debug_checkbox = RTN:IntializeDebugCheckbox(RTN.options_panel.frame)
end



















