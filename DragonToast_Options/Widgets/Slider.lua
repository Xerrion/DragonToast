-------------------------------------------------------------------------------
-- Slider.lua
-- Horizontal slider with label, min/max labels, and editable value display
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local WC = ns.WidgetConstants

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local pcall = pcall
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local tonumber = tonumber
local format = string.format

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local LABEL_FONT_SIZE = 12
local VALUE_FONT_SIZE = 11
local MIN_MAX_FONT_SIZE = 10
local THUMB_TEXTURE = "Interface\\Buttons\\UI-SliderBar-Button-Horizontal"
local EDITBOX_WIDTH = 50
local FRAME_HEIGHT = 55
local SLIDER_HEIGHT = 17
local TRACK_BG = { 0.15, 0.15, 0.15, 0.9 }
local TRACK_BORDER = { 0.3, 0.3, 0.3, 1 }

-------------------------------------------------------------------------------
-- Utility: round to step
-------------------------------------------------------------------------------

local function RoundToStep(value, step)
    if not step or step <= 0 then return value end
    return math_floor(value / step + 0.5) * step
end

-------------------------------------------------------------------------------
-- Utility: clamp value
-------------------------------------------------------------------------------

local function Clamp(value, minVal, maxVal)
    return math_max(minVal, math_min(maxVal, value))
end

-------------------------------------------------------------------------------
-- Format the display value
-------------------------------------------------------------------------------

local function FormatValue(value, opts)
    local fmt = opts.format or "%.1f"
    if opts.isPercent then
        return format(fmt, value * 100) .. "%"
    end
    return format(fmt, value)
end

-------------------------------------------------------------------------------
-- Build a custom slider frame (fallback when template is unavailable)
-------------------------------------------------------------------------------

local function CreateCustomSlider(parent)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetHeight(SLIDER_HEIGHT)
    slider:SetBackdrop({
        bgFile = WC.WHITE8x8,
        edgeFile = WC.WHITE8x8,
        edgeSize = 1,
    })
    slider:SetBackdropColor(TRACK_BG[1], TRACK_BG[2], TRACK_BG[3], TRACK_BG[4])
    slider:SetBackdropBorderColor(TRACK_BORDER[1], TRACK_BORDER[2], TRACK_BORDER[3], TRACK_BORDER[4])

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(THUMB_TEXTURE)
    thumb:SetSize(16, 24)
    slider:SetThumbTexture(thumb)

    return slider
end

-------------------------------------------------------------------------------
-- Try the built-in template, fall back to custom
-------------------------------------------------------------------------------

local function CreateSliderFrame(parent)
    local ok, slider = pcall(CreateFrame, "Slider", nil, parent, "OptionsSliderTemplate")
    if ok and slider then
        -- Remove default template text elements that may interfere
        if slider.Text then slider.Text:Hide() end
        if slider.Low then slider.Low:Hide() end
        if slider.High then slider.High:Hide() end
        return slider
    end
    return CreateCustomSlider(parent)
end

-------------------------------------------------------------------------------
-- Update editbox display from a numeric value
-------------------------------------------------------------------------------

local function UpdateEditBoxText(editBox, value, opts)
    editBox:SetText(FormatValue(value, opts))
end

-------------------------------------------------------------------------------
-- Create the editable value input box
-------------------------------------------------------------------------------

local function CreateValueEditBox(parent, slider)
    local editBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    editBox:SetSize(EDITBOX_WIDTH, 20)
    editBox:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    editBox:SetBackdrop({
        bgFile = WC.WHITE8x8,
        edgeFile = WC.WHITE8x8,
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    editBox:SetFont(WC.FONT_PATH, VALUE_FONT_SIZE, "")
    editBox:SetTextColor(WC.WHITE_COLOR[1], WC.WHITE_COLOR[2], WC.WHITE_COLOR[3])
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(10)

    -- Suppress tab key to avoid focus issues
    editBox:SetScript("OnTabPressed", function(self)
        self:ClearFocus()
    end)

    return editBox
end

-------------------------------------------------------------------------------
-- Create the label, slider track, min/max labels, and editbox UI elements
-------------------------------------------------------------------------------

local function CreateSliderElements(frame, opts, state)
    -- Label at top
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(WC.FONT_PATH, LABEL_FONT_SIZE, "")
    label:SetTextColor(WC.WHITE_COLOR[1], WC.WHITE_COLOR[2], WC.WHITE_COLOR[3])
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetText(opts.label or "")

    -- Slider below label
    local slider = CreateSliderFrame(frame)
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    slider:SetPoint("RIGHT", frame, "RIGHT", -(EDITBOX_WIDTH + 8), 0)
    slider:SetMinMaxValues(state.minVal, state.maxVal)
    slider:SetValueStep(state.step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")

    -- Min label (bottom-left of slider)
    local minLabel = frame:CreateFontString(nil, "OVERLAY")
    minLabel:SetFont(WC.FONT_PATH, MIN_MAX_FONT_SIZE, "")
    minLabel:SetTextColor(WC.GRAY_COLOR[1], WC.GRAY_COLOR[2], WC.GRAY_COLOR[3])
    minLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
    minLabel:SetText(FormatValue(state.minVal, opts))

    -- Max label (bottom-right of slider)
    local maxLabel = frame:CreateFontString(nil, "OVERLAY")
    maxLabel:SetFont(WC.FONT_PATH, MIN_MAX_FONT_SIZE, "")
    maxLabel:SetTextColor(WC.GRAY_COLOR[1], WC.GRAY_COLOR[2], WC.GRAY_COLOR[3])
    maxLabel:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -1)
    maxLabel:SetText(FormatValue(state.maxVal, opts))

    local editBox = CreateValueEditBox(frame, slider)

    return label, slider, editBox
end

-------------------------------------------------------------------------------
-- Wire up OnValueChanged, OnEnterPressed, OnEscapePressed handlers
-------------------------------------------------------------------------------

local function SetupSliderEvents(slider, editBox, opts, state)
    slider:SetScript("OnValueChanged", function(_, value)
        local rounded = RoundToStep(value, state.step)
        state.currentValue = rounded
        if not state.isInternal then
            UpdateEditBoxText(editBox, rounded, opts)
            if opts.set then opts.set(rounded) end
        end
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        text = text:gsub("%%", "")
        local parsed = tonumber(text)
        if parsed then
            if opts.isPercent then parsed = parsed / 100 end
            parsed = Clamp(RoundToStep(parsed, state.step), state.minVal, state.maxVal)
            state.isInternal = true
            slider:SetValue(parsed)
            state.isInternal = false
            state.currentValue = parsed
            UpdateEditBoxText(editBox, parsed, opts)
            if opts.set then opts.set(parsed) end
        else
            UpdateEditBoxText(editBox, state.currentValue, opts)
        end
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        UpdateEditBoxText(editBox, state.currentValue, opts)
        self:ClearFocus()
    end)
end

-------------------------------------------------------------------------------
-- Attach public API methods to the frame (GetValue, SetValue, SetDisabled, Refresh)
-------------------------------------------------------------------------------

local function AttachSliderAPI(frame, slider, editBox, label, opts, state)
    function frame.GetValue(_)
        return state.currentValue
    end

    function frame.SetValue(_, v)
        local clamped = Clamp(RoundToStep(v, state.step), state.minVal, state.maxVal)
        state.currentValue = clamped
        state.isInternal = true
        slider:SetValue(clamped)
        state.isInternal = false
        UpdateEditBoxText(editBox, clamped, opts)
    end

    function frame.SetDisabled(_, isDisabled)
        state.disabled = isDisabled
        slider:EnableMouse(not state.disabled)
        editBox:EnableMouse(not state.disabled)
        if state.disabled then
            label:SetTextColor(WC.DISABLED_COLOR[1], WC.DISABLED_COLOR[2], WC.DISABLED_COLOR[3])
            slider:SetAlpha(0.5)
            editBox:SetAlpha(0.5)
        else
            label:SetTextColor(WC.WHITE_COLOR[1], WC.WHITE_COLOR[2], WC.WHITE_COLOR[3])
            slider:SetAlpha(1)
            editBox:SetAlpha(1)
        end
    end

    function frame.Refresh(_)
        if opts.get then
            local v = opts.get() or state.minVal
            local clamped = Clamp(RoundToStep(v, state.step), state.minVal, state.maxVal)
            state.currentValue = clamped
            state.isInternal = true
            slider:SetValue(clamped)
            state.isInternal = false
            UpdateEditBoxText(editBox, clamped, opts)
        end
    end
end

-------------------------------------------------------------------------------
-- Factory: CreateSlider
-------------------------------------------------------------------------------

function ns.Widgets.CreateSlider(parent, opts)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FRAME_HEIGHT)

    local state = {
        currentValue = (opts.get and opts.get()) or opts.min or 0,
        isInternal = false,
        disabled = false,
        minVal = opts.min or 0,
        maxVal = opts.max or 100,
        step = opts.step or 1,
    }

    local label, slider, editBox = CreateSliderElements(frame, opts, state)
    SetupSliderEvents(slider, editBox, opts, state)
    AttachSliderAPI(frame, slider, editBox, label, opts, state)

    -- Initialize slider position and editbox text
    state.isInternal = true
    slider:SetValue(state.currentValue)
    state.isInternal = false
    UpdateEditBoxText(editBox, state.currentValue, opts)

    frame._slider = slider
    frame._editBox = editBox
    frame._label = label
    frame.order = opts.order

    return frame
end
