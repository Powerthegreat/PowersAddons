FFXIVDurabilityBarsAddOn = {};
local addon = FFXIVDurabilityBarsAddOn

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

		-- This was a string used for testing, just to get something on screen
		-- SetFormattedText below was used with this to set what to display and what colour to display it in
		-- (using rich text style hex codes of the format |cAARRGGBB, and |r at the end to reset)
		--button.ffxivDurabilityBar = overlayFrame:CreateFontString(nil, "OVERLAY")
		--button.ffxivDurabilityBar:Hide()
		--button.ffxivDurabilityBar:SetAllPoints()
		--button.ffxivDurabilityBar:SetFontObject(NumberFontNormal)
		button.ffxivDurabilityBar = overlayFrame:CreateLine()
		button.ffxivDurabilityBar:Hide()
		button.ffxivDurabilityBar:SetThickness(2)
		button.ffxivDurabilityBar:SetDrawLayer("OVERLAY")
	end

	if button:GetID() >= INVSLOT_FIRST_EQUIPPED and button:GetID() <= INVSLOT_LAST_EQUIPPED then
		local item = Item:CreateFromEquipmentSlot(button:GetID())
		if (item:GetItemID()) then
			local durability, maxDura = GetInventoryItemDurability(button:GetID())
			if durability and maxDura then
				--local r, g, b, hex = C_Item.GetItemQualityColor(2)
				local r, g, b, hex = C_Item.GetItemQualityColor(3)
				button.ffxivDurabilityBar:SetColorTexture(r, g, b)
				if durability == 0 then
					button.ffxivDurabilityBar:SetColorTexture(1, 0, 0)
				elseif durability < maxDura then
					--hex = "ff00ff00"
					button.ffxivDurabilityBar:SetColorTexture(0, 1, 0)
				end
				--button.ffxivDurabilityBar:SetFormattedText("|c%s%s/%s|r", hex, durability, maxDura)
				addon:SetLinePoints(button.ffxivDurabilityBar, button.ffxivDuraOverlay, durability, maxDura, side)
				button.ffxivDurabilityBar:Show()
				button.ffxivDurabilityBarBG:Show()
			else
				--local hex = "ffffff00"
				--button.ffxivDurabilityBar:SetFormattedText("|c%sNope|r", hex)
				button.ffxivDurabilityBar:SetColorTexture(1, 1, 0)
				addon:SetLinePoints(button.ffxivDurabilityBar, button.ffxivDuraOverlay, 1, 1, side)
				button.ffxivDurabilityBar:Show()
				button.ffxivDurabilityBarBG:Show()
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
