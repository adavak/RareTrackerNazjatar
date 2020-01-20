-- Redefine often used functions locally.
local CreateFrame = CreateFrame
local UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local PlaySoundFile = PlaySoundFile
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local getglobal = getglobal
local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory

-- Redefine global variables locally.
local UIParent = UIParent
local C_Map = C_Map

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTrackerNazjatar", true)

-- ####################################################################
-- ##                       Options Interface                        ##
-- ####################################################################

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

function RTN.IntializeSoundSelectionMenu(parent_frame)
	local f = CreateFrame("frame", "RTN.options_panel.sound_selection", parent_frame, "UIDropDownMenuTemplate")
	UIDropDownMenu_SetWidth(f, 140)
	UIDropDownMenu_SetText(f, sound_options_inverse[RTNDB.selected_sound_number])
	
	f.onClick = function(_, sound_id, _, _)
		RTNDB.selected_sound_number = sound_id
		UIDropDownMenu_SetText(f, sound_options_inverse[RTNDB.selected_sound_number])
		PlaySoundFile(RTNDB.selected_sound_number)
	end
	
	f.initialize = function()
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
	f.label:SetText(L["Favorite sound alert"])
	f.label:SetPoint("TOPLEFT", parent_frame)
	
	f:SetPoint("TOPLEFT", f.label, -20, -13)
	
	return f
end

function RTN:IntializeMinimapCheckbox(parent_frame)
	local f = CreateFrame(
		"CheckButton", "RTN.options_panel.minimap_checkbox", parent_frame, "ChatConfigCheckButtonTemplate"
	)
	
	getglobal(f:GetName() .. 'Text'):SetText(L[" Show minimap icon"]);
	f.tooltip = L["Show or hide the minimap button."];
	f:SetScript("OnClick",
		function()
			RTNDB.minimap_icon_enabled = not RTNDB.minimap_icon_enabled
			if not RTNDB.minimap_icon_enabled then
				self.icon:Hide("RTN_icon")
			elseif RTN.target_zones[C_Map.GetBestMapForUnit("player")] then
				self.icon:Show("RTN_icon")
			end
		end
	);
	f:SetChecked(RTNDB.minimap_icon_enabled)
	f:SetPoint("TOPLEFT", parent_frame, 0, -53)
end

function RTN.IntializeRaidCommunicationCheckbox(parent_frame)
	local f = CreateFrame(
		"CheckButton", "RTN.options_panel.raid_comms_checkbox", parent_frame, "ChatConfigCheckButtonTemplate"
	)
	
	getglobal(f:GetName() .. 'Text'):SetText(L[" Enable communication over part/raid channel"])
	f.tooltip = L["Enable communication over party/raid channel, "..
					"to support CRZ functionality while in a party or raid group."]

	f:SetScript("OnClick",
		function()
			RTNDB.enable_raid_communication = not RTNDB.enable_raid_communication
		end
	);
	f:SetChecked(RTNDB.enable_raid_communication)
	f:SetPoint("TOPLEFT", parent_frame, 0, -75)
end

function RTN.IntializeDebugCheckbox(parent_frame)
	local f = CreateFrame("CheckButton", "RTN.options_panel.debug_checkbox", parent_frame, "ChatConfigCheckButtonTemplate")
	getglobal(f:GetName() .. 'Text'):SetText(L[" Enable debug mode"]);
	f:SetScript("OnClick",
		function()
			RTNDB.debug_enabled = not RTNDB.debug_enabled
		end
	);
	f:SetChecked(RTNDB.debug_enabled)
	f:SetPoint("TOPLEFT", parent_frame, 0, -97)
end

function RTN:IntializeScaleSlider(parent_frame)
	local f = CreateFrame("Slider", "RTN.options_panel.scale_slider", parent_frame, "OptionsSliderTemplate")
	f.tooltip = L["Set the scale of the rare window."];
	f:SetMinMaxValues(0.5, 2)
	f:SetValueStep(0.05)
	f:SetValue(RTNDB.window_scale)
	self:SetScale(RTNDB.window_scale)
	f:Enable()
	
	f:SetScript("OnValueChanged",
		function(self2, value)
			-- Round the value to the nearest step value.
			value = math.floor(value * 20) / 20
		
			RTNDB.window_scale = value
			self2.label:SetText(L["Rare window scale "]..string.format("(%.2f)", RTNDB.window_scale))
			RTN:SetScale(RTNDB.window_scale)
		end
	);
	
	f.label = f:CreateFontString(nil, "BORDER", "GameFontNormal")
	f.label:SetJustifyH("LEFT")
	f.label:SetText(L["Rare window scale "]..string.format("(%.2f)", RTNDB.window_scale))
	f.label:SetPoint("TOPLEFT", parent_frame, 0, -125)
	
	f:SetPoint("TOPLEFT", f.label, 5, -15)
end

function RTN:InitializeButtons(parent_frame)
	parent_frame.reset_favorites_button = CreateFrame(
		"Button", "RTN.options_panel.reset_favorites_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_favorites_button:SetText(L["Reset Favorites"])
	parent_frame.reset_favorites_button:SetSize(150, 25)
	parent_frame.reset_favorites_button:SetPoint("TOPLEFT", parent_frame, 0, -175)
	parent_frame.reset_favorites_button:SetScript("OnClick",
		function()
			RTNDB.favorite_rares = {}
			self:CorrectFavoriteMarks()
		end
	)
	
	parent_frame.reset_blacklist_button = CreateFrame(
		"Button", "RTN.options_panel.reset_blacklist_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_blacklist_button:SetText(L["Reset Blacklist"])
	parent_frame.reset_blacklist_button:SetSize(150, 25)
	parent_frame.reset_blacklist_button:SetPoint("TOPRIGHT", parent_frame.reset_favorites_button, 155, 0)
	parent_frame.reset_blacklist_button:SetScript("OnClick",
		function()
			RTNDB.banned_NPC_ids = {}
		end
	)
end

function RTN:CreateRareSelectionEntry(npc_id, parent_frame, entry_data)
	local f = CreateFrame("Frame", "RTN.options_panel.rare_selection.frame.list["..npc_id.."]", parent_frame);
	f:SetSize(500, 12)
	
	f.enable = CreateFrame("Button", "RTN.options_panel.rare_selection.frame.list["..npc_id.."].enable", f);
	f.enable:SetSize(10, 10)
	local texture = f.enable:CreateTexture(nil, "BACKGROUND")
	
	if not RTNDB.ignore_rare[npc_id] then
		texture:SetColorTexture(0, 1, 0, 1)
	else
		texture:SetColorTexture(1, 0, 0, 1)
	end
	
	texture:SetAllPoints(f.enable)
	f.enable.texture = texture
	f.enable:SetPoint("TOPLEFT", f, 0, 0)
	f.enable:SetScript("OnClick",
		function()
			if not RTNDB.ignore_rare[npc_id] then
				if RTNDB.favorite_rares[npc_id] then
					print(L["<RTN> Favorites cannot be hidden."])
				else
					RTNDB.ignore_rare[npc_id] = true
					f.enable.texture:SetColorTexture(1, 0, 0, 1)
					RTN:ReorganizeRareTableFrame(RTN.entities_frame)
				end
			else
				RTNDB.ignore_rare[npc_id] = nil
				f.enable.texture:SetColorTexture(0, 1, 0, 1)
				RTN:ReorganizeRareTableFrame(RTN.entities_frame)
			end
		end
	)
	
	f.up = CreateFrame("Button", "RTN.options_panel.rare_selection.frame.list["..npc_id.."].up", f);
	f.up:SetSize(10, 10)
	texture = f.up:CreateTexture(nil, "OVERLAY")
	texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\UpArrow.tga")
	texture:SetSize(10, 10)
	texture:SetPoint("CENTER", f.up)
	texture:SetAllPoints(f.up)
	
	f.up.texture = texture
	f.up:SetPoint("TOPLEFT", f, 13, 0)
	
	f.up:SetScript("OnClick",
		function()
      -- Here, we use the most up-to-date entry data, instead of the one passed as an argument.
      local previous_entry = RTNDB.rare_ordering.__raw_data_table[npc_id].__previous
			RTNDB.rare_ordering:SwapNeighbors(previous_entry, npc_id)
			self.ReorderRareSelectionEntryItems(parent_frame)
			self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)
		
	if entry_data.__previous == nil then
		f.up:Hide()
	end
	
	f.down = CreateFrame("Button", "RTN.options_panel.rare_selection.frame.list["..npc_id.."].down", f);
	f.down:SetSize(10, 10)
	texture = f.down:CreateTexture(nil, "OVERLAY")
	texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\DownArrow.tga")
	texture:SetSize(10, 10)
	texture:SetPoint("CENTER", f.down)
	texture:SetAllPoints(f.down)
	f.down.texture = texture
	f.down:SetPoint("TOPLEFT", f, 26, 0)
	
	f.down:SetScript("OnClick",
		function()
      -- Here, we use the most up-to-date entry data, instead of the one passed as an argument.
      local next_entry = RTNDB.rare_ordering.__raw_data_table[npc_id].__next
			RTNDB.rare_ordering:SwapNeighbors(npc_id, next_entry)
			self.ReorderRareSelectionEntryItems(parent_frame)
			self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)

	if entry_data.__next == nil then
		f.down:Hide()
	end
	
	f.text = f:CreateFontString(nil, "BORDER", "GameFontNormal")
	f.text:SetJustifyH("LEFT")
	f.text:SetText(self.rare_display_names[npc_id])
	f.text:SetPoint("TOPLEFT", f, 42, 0)
	
	return f
end

function RTN.ReorderRareSelectionEntryItems(parent_frame)
	local i = 1
	RTNDB.rare_ordering:ForEach(
		function(npc_id, entry_data)
			local f = parent_frame.list_item[npc_id]
			if entry_data.__previous == nil then
				f.up:Hide()
			else
				f.up:Show()
			end
			
			if entry_data.__next == nil then
				f.down:Hide()
			else
				f.down:Show()
			end
				
			f:SetPoint("TOPLEFT", parent_frame, 1, -(i - 1) * 12 - 5)
			i = i + 1
		end
	)
end

function RTN:DisableAllRaresButton(parent_frame)
  parent_frame.reset_all_button = CreateFrame(
		"Button", "RTN.options_panel.rare_selection.reset_all_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_all_button:SetText(L["Disable All"])
	parent_frame.reset_all_button:SetSize(150, 25)
	parent_frame.reset_all_button:SetPoint("TOPRIGHT", parent_frame, 0, 0)
	parent_frame.reset_all_button:SetScript("OnClick",
		function()
			for i=1, #self.rare_ids do
        local npc_id = self.rare_ids[i]
        if RTNDB.favorite_rares[npc_id] ~= true then
          RTNDB.ignore_rare[npc_id] = true
          parent_frame.list_item[npc_id].enable.texture:SetColorTexture(1, 0, 0, 1)
        end
      end
      self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)
end

function RTN:EnableAllRaresButton(parent_frame)
  parent_frame.enable_all_button = CreateFrame(
		"Button", "RTN.options_panel.rare_selection.enable_all_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.enable_all_button:SetText(L["Enable All"])
	parent_frame.enable_all_button:SetSize(150, 25)
	parent_frame.enable_all_button:SetPoint("TOPRIGHT", parent_frame, 0, -25)
	parent_frame.enable_all_button:SetScript("OnClick",
		function()
      for i=1, #self.rare_ids do
        local npc_id = self.rare_ids[i]
        RTNDB.ignore_rare[npc_id] = nil
        parent_frame.list_item[npc_id].enable.texture:SetColorTexture(0, 1, 0, 1)
      end
      self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)
end

function RTN:ResetRareOrderButton(parent_frame)
  parent_frame.reset_order_button = CreateFrame(
		"Button", "RTN.options_panel.rare_selection.reset_order_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_order_button:SetText(L["Reset Order"])
	parent_frame.reset_order_button:SetSize(150, 25)
	parent_frame.reset_order_button:SetPoint("TOPRIGHT", parent_frame, 0, -50)
	parent_frame.reset_order_button:SetScript("OnClick",
		function()
			RTNDB.rare_ordering:Clear()
      for i=1, #self.rare_ids do
        local npc_id = self.rare_ids[i]
        RTNDB.rare_ordering:AddBack(npc_id)
      end
      self:ReorganizeRareTableFrame(self.entities_frame)
      self.ReorderRareSelectionEntryItems(parent_frame)
		end
	)
end

function RTN:InitializeRareSelectionChildMenu(parent_frame)
	parent_frame.rare_selection = CreateFrame("Frame", "RTN.options_panel.rare_selection", parent_frame)
	parent_frame.rare_selection.name = L["Rare ordering/selection"]
	parent_frame.rare_selection.parent = parent_frame.name
	InterfaceOptions_AddCategory(parent_frame.rare_selection)
	
	parent_frame.rare_selection.frame = CreateFrame(
      "Frame",
      "RTN.options_panel.rare_selection.frame",
      parent_frame.rare_selection
  )
  
	parent_frame.rare_selection.frame:SetPoint("LEFT", parent_frame.rare_selection, 101, 0)
	parent_frame.rare_selection.frame:SetSize(400, 500)
	
	local f = parent_frame.rare_selection.frame
	local i = 1
	f.list_item = {}
	
	RTNDB.rare_ordering:ForEach(
		function(npc_id, entry_data)
			f.list_item[npc_id] = self:CreateRareSelectionEntry(npc_id, f, entry_data)
			f.list_item[npc_id]:SetPoint("TOPLEFT", f, 1, -(i - 1) * 12 - 5)
			i = i + 1
		end
	)
  
  -- Add utility buttons.
  RTN:DisableAllRaresButton(f)
  RTN:EnableAllRaresButton(f)
  RTN:ResetRareOrderButton(f)
end

function RTN:InitializeConfigMenu()
	self.options_panel = CreateFrame("Frame", "RTN.options_panel", UIParent)
	self.options_panel.name = "RareTrackerNazjatar"
	InterfaceOptions_AddCategory(self.options_panel)
	
	self.options_panel.frame = CreateFrame("Frame", "RTN.options_panel.frame", self.options_panel)
	self.options_panel.frame:SetPoint("TOPLEFT", self.options_panel, 11, -14)
	self.options_panel.frame:SetSize(500, 500)

	self.options_panel.sound_selector = self.IntializeSoundSelectionMenu(self.options_panel.frame)
	self.options_panel.minimap_checkbox = self:IntializeMinimapCheckbox(self.options_panel.frame)
	self.options_panel.raid_comms_checkbox = self.IntializeRaidCommunicationCheckbox(self.options_panel.frame)
	self.options_panel.debug_checkbox = self.IntializeDebugCheckbox(self.options_panel.frame)
	self.options_panel.scale_slider = self:IntializeScaleSlider(self.options_panel.frame)
	self:InitializeButtons(self.options_panel.frame)
	self:InitializeRareSelectionChildMenu(self.options_panel)
end
