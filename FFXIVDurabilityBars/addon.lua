FFXIVDurabilityBarsAddOn = LibStub("AceAddon-3.0"):NewAddon("FFXIVDurabilityBars")
local addon = FFXIVDurabilityBarsAddOn

local ffxivDuraOptions = {
	name = "FFXIV Durability Bars",
	handler = addon,
	type = "group",
	childGroups = "tab",
	args = {
		settingsTab = {
			type = "group",
			name = "Settings",
			order = 1,
			inline = true,
			args = {
				showDurabilityFreeBars = {
					type = "toggle",
					name = "Show Durability Free Bars",
					desc = "Should durability bars be shown for items without durability? (eg. trinkets, cloak...)",
					set = function(info, input) addon.db.profile.showDurabilityFreeBars = input end,
					get = function(info) return addon.db.profile.showDurabilityFreeBars end,
				},
				useQualityColours = {
					type = "toggle",
					name = "Use Quality Colours",
					desc = "Should durability bars use the quality/rarity colour of the items?",
					set = function(info, input) addon.db.profile.useQualityColours = input end,
					get = function(info) return addon.db.profile.useQualityColours end,
				},
				useGreenWhenDamaged = {
					type = "toggle",
					name = "Use Green When Damaged",
					desc = "Should durability bars use green instead of another colour when damaged?",
					set = function(info, input) addon.db.profile.useGreenWhenDamaged = input end,
					get = function(info) return addon.db.profile.useGreenWhenDamaged end,
				},
			},
		},
	},
}

local defaults = {
	profile = {
		showDurabilityFreeBars = true,
		useQualityColours = true,
		useGreenWhenDamaged = false,
	}
}

function addon:SetLinePoints(line, frame, durability, maxDurability, side)
	-- Calculate the endpoint of a bar based on its proportional durability
	if side == "left" then
		line:SetStartPoint("CENTER", frame, -22, -18 + 36 * (durability / maxDurability))
		line:SetEndPoint("CENTER", frame, -22, -18)
	elseif side == "right" then
		line:SetStartPoint("CENTER", frame, 22, -18 + 36 * (durability / maxDurability))
		line:SetEndPoint("CENTER", frame, 22, -18)
	elseif side == "top" then
		line:SetStartPoint("CENTER", frame, -18 + 36 * (durability / maxDurability), 22)
		line:SetEndPoint("CENTER", frame, -18, 22)
	end
end

function addon:AddDurabilityBarToSlot(button, side)
	if button.ffxivDurabilityBar then button.ffxivDurabilityBar:Hide() end
	if button.ffxivDurabilityBarBG then button.ffxivDurabilityBarBG:Hide() end
	if not button.ffxivDurabilityBar then
		local overlayFrame = CreateFrame("FRAME", nil, button)
		overlayFrame:SetAllPoints()
		overlayFrame:SetFrameLevel(button:GetFrameLevel() + 1)
		button.ffxivDuraOverlay = overlayFrame

		button.ffxivDurabilityBarBG = overlayFrame:CreateLine()
		button.ffxivDurabilityBarBG:Hide()
		button.ffxivDurabilityBarBG:SetColorTexture(1, 0, 0)
		button.ffxivDurabilityBarBG:SetThickness(2)
		button.ffxivDurabilityBarBG:SetDrawLayer("BACKGROUND")
		addon:SetLinePoints(button.ffxivDurabilityBarBG, overlayFrame, 1, 1, side)

		button.ffxivDurabilityBar = overlayFrame:CreateLine()
		button.ffxivDurabilityBar:Hide()
		button.ffxivDurabilityBar:SetThickness(2)
		button.ffxivDurabilityBar:SetDrawLayer("OVERLAY")
	end

	if button:GetID() >= INVSLOT_FIRST_EQUIPPED and button:GetID() <= INVSLOT_LAST_EQUIPPED then
		local item = Item:CreateFromEquipmentSlot(button:GetID())
		if (item:GetItemID()) then
			local colour
			local r, g, b
			if (addon.db.profile.useQualityColours) then
				GetInventoryItemQuality("player", button:GetID())
				colour = GetInventoryItemQuality("player", button:GetID()) -- Using this over GetItemInfo(item:GetItemID()) because of upgradable items - they return their base rarity rather than the one equipped
				r, g, b = C_Item.GetItemQualityColor(colour)
				button.ffxivDurabilityBar:SetColorTexture(r, g, b)
			end
			
			local durability, maxDura = GetInventoryItemDurability(button:GetID())
			if durability and maxDura then -- Items with durability, whether full or not
				if (not addon.db.profile.useQualityColours) then
					r, g, b = C_Item.GetItemQualityColor(3)
					button.ffxivDurabilityBar:SetColorTexture(r, g, b)
				end
				if durability == 0 then
					button.ffxivDurabilityBar:SetColorTexture(1, 0, 0)
				elseif durability < maxDura and addon.db.profile.useGreenWhenDamaged then
					button.ffxivDurabilityBar:SetColorTexture(0, 1, 0)
				end
				addon:SetLinePoints(button.ffxivDurabilityBar, button.ffxivDuraOverlay, durability, maxDura, side)
				button.ffxivDurabilityBar:Show()
				button.ffxivDurabilityBarBG:Show()
			else -- Items that don't have durability
				if (addon.db.profile.showDurabilityFreeBars) then
					if (not addon.db.profile.useQualityColours) then
						r = 1
						g = 1
						b = 0
						button.ffxivDurabilityBar:SetColorTexture(r, g, b)
					end
					addon:SetLinePoints(button.ffxivDurabilityBar, button.ffxivDuraOverlay, 1, 1, side)
					button.ffxivDurabilityBar:Show()
					button.ffxivDurabilityBarBG:Show()
				end
			end
		end
	end
end

hooksecurefunc("PaperDollItemSlotButton_Update",
	function(button)
		local side = "left" -- Default to a bar on the left, this should only end up on right side items
		if button:GetID() == INVSLOT_MAINHAND or -- Weapons have a bar above them
			button:GetID() == INVSLOT_OFFHAND or
			button:GetID() == INVSLOT_RANGED then
				side = "top"
		elseif button:GetID() == INVSLOT_HEAD or -- Left side items have a bar on the right
			button:GetID() == INVSLOT_NECK or
			button:GetID() == INVSLOT_SHOULDER or
			button:GetID() == INVSLOT_BACK or
			button:GetID() == INVSLOT_CHEST or
			button:GetID() == INVSLOT_BODY or
			button:GetID() == INVSLOT_TABARD or
			button:GetID() == INVSLOT_WRIST then
				side = "right"
		end
		addon:AddDurabilityBarToSlot(button, side)
	end)

function addon:AddDurabilityPercentToTooltip(tooltip, data)
	if not InCombatLockdown() then
    	if tooltip == GameTooltip and not data.leftText and string.len(data.leftText) > 10 and (string.sub(data.leftText,1,string.len("Durability")) == "Durability") then
			local duraString = string.sub(data.leftText,string.len("Durability ") + 1)
			local duraNums = {}
			for str in string.gmatch(duraString,"%d+") do
				table.insert(duraNums, tonumber(str))
			end
			local duraPercent = duraNums[1] / duraNums[2] * 100
			data.leftText = data.leftText .. " (" .. string.format("%.1f", duraPercent) .. "%)"
		end
	end
end

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("FFXIVDurabilityBarsDB", defaults)
	ffxivDuraOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("FFXIVDurabilityBars", ffxivDuraOptions)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FFXIVDurabilityBars", "FFXIV Durability Bars")
	
	TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataType.Item, function(tooltip, data) addon:AddDurabilityPercentToTooltip(tooltip, data) end)
end