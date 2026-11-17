-------------------------------------------------------------------------------
-- Preview.lua
-- Isolated live renderer for the pinned options preview
-------------------------------------------------------------------------------

local _, ns = ...

local CreateFrame = CreateFrame
local W = ns.DW.Widgets
local WC = ns.DW.WidgetConstants
local L = ns.L
local format = string.format

local SAMPLE_LABELS = { L["Item"], L["Gold"], L["Experience"], L["Honor"], L["Reputation"] }
local QUALITY_LABELS = { L["Uncommon"], L["Rare"], L["Epic"], L["Legendary"] }

local function BuildSample(sample, quality)
    local data = {
        itemName = L["Example item"], itemIcon = 133772, itemID = 32331,
        itemQuality = quality, itemLevel = 141, itemType = L["Armor"], itemSubType = L["Cloth"],
        quantity = 3, isSelf = true, looter = L["You"],
    }
    if sample ~= 1 then
        data.itemQuality, data.quantity = 1, 1
        data.itemID, data.itemType = nil, nil
    end
    if sample == 2 then
        data.itemName = L["Gold"]
        data.itemIcon = 133784
        data.isCurrency = true
        data.copperAmount = 123456
        data.itemSubType = "Gold" -- Renderer discriminator, not display text.
    elseif sample == 3 then
        data.itemName = format(L["+%s XP"], "1,234")
        data.itemIcon = 894556
        data.isXP = true
        data.mobName = L["Example encounter"]
    elseif sample == 4 then
        data.itemName = format(L["+%s Honor"], "150")
        data.itemIcon = 136986
        data.isHonor = true
        data.victimName = L["Example encounter"]
    elseif sample == 5 then
        data.itemName = format(L["+%s Reputation"], "250")
        data.itemIcon = "Interface\\AddOns\\DragonToast\\Media\\ReputationGain"
        data.isReputation = true
        data.factionName = L["Example faction"]
    end
    return data
end

function ns.CreatePreview(host)
    local title = host:CreateFontString(nil, "OVERLAY")
    title:SetFont(WC.FONT_PATH, WC.FONT_SIZE, "")
    title:SetTextColor(WC.TEXT_COLOR[1], WC.TEXT_COLOR[2], WC.TEXT_COLOR[3])
    title:SetPoint("TOPLEFT", host, "TOPLEFT", 16, -14)
    title:SetText(L["Live Preview"])

    local caption = host:CreateFontString(nil, "OVERLAY")
    caption:SetFont(WC.FONT_PATH, WC.FONT_SIZE_SMALL, "")
    caption:SetTextColor(WC.GRAY_COLOR[1], WC.GRAY_COLOR[2], WC.GRAY_COLOR[3])
    caption:SetPoint("TOPLEFT", host, "TOPLEFT", 16, -30)

    local stage = CreateFrame("Frame", nil, host)
    stage:SetPoint("TOPLEFT", host, "TOPLEFT", 16, -44)
    stage:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -16, 16)
    stage:EnableMouse(false)

    local renderer = ns.dtns.ToastFrame.CreatePreview(stage)
    local controller = { renderer = renderer }
    local sampleIndex, qualityIndex = 1, 3
    local sampleButton, qualityButton

    function controller:Refresh()
        sampleButton:SetText(format(L["Sample: %s"], SAMPLE_LABELS[sampleIndex]))
        qualityButton:SetText(format(L["Rarity: %s"], QUALITY_LABELS[qualityIndex]))
        qualityButton:SetDisabled(sampleIndex ~= 1)
        local width, height, scale = renderer:Refresh(BuildSample(sampleIndex, qualityIndex + 1))
        if width then
            caption:SetText(format(L["%d x %d · %d%%"], width, height, math.floor(scale * 100 + 0.5)))
        else
            caption:SetText("")
        end
    end

    function controller:OnHide()
        renderer:OnHide()
    end

    qualityButton = W.CreateButton(host, {
        width = 142,
        text = "",
        tooltip = L["Cycle the item rarity in the preview"],
        onClick = function()
            qualityIndex = qualityIndex % #QUALITY_LABELS + 1
        end,
    })
    qualityButton:SetPoint("TOPRIGHT", host, "TOPRIGHT", -16, -8)

    sampleButton = W.CreateButton(host, {
        width = 160,
        text = "",
        tooltip = L["Cycle the notification shown in the preview"],
        onClick = function()
            sampleIndex = sampleIndex % #SAMPLE_LABELS + 1
        end,
    })
    sampleButton:SetPoint("RIGHT", qualityButton, "LEFT", -8, 0)

    return controller
end
