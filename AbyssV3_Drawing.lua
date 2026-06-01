-- Abyss V3 | Drawing Library UI
-- Compatible with Delta Executor (Mobile)
-- Font: Drawing.Fonts.Plex | Scale: 0.78

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------------------------------
-- SCALE & THEME
------------------------------------------------------------------------
local SCALE = 0.78

local function s(n) return math.floor(n * SCALE) end

-- Window base (unscaled)
local WIN_X     = 80
local WIN_Y     = 60
local WIN_W     = 490
local WIN_H     = 500
local COL_W     = 238

-- Colors
local C_BG         = {20/255,  22/255,  25/255,  1}
local C_BG_MID     = {28/255,  30/255,  35/255,  1}
local C_BORDER     = {55/255,  60/255,  68/255,  1}
local C_BORDER2    = {45/255,  48/255,  56/255,  1}
local C_TEXT       = Color3.fromRGB(180, 185, 195)
local C_TEXT_B     = Color3.fromRGB(210, 215, 225)
local C_ACCENT     = Color3.fromRGB(40,  120, 220)
local C_ACCENT2    = Color3.fromRGB(30,  80,  160)
local C_SLIDER_BG  = Color3.fromRGB(40,  44,  52)
local C_DROP_BG    = Color3.fromRGB(32,  35,  42)
local C_TAB_ACT    = Color3.fromRGB(35,  38,  44)
local C_TAB_IN     = Color3.fromRGB(24,  26,  30)
local C_GREEN      = Color3.fromRGB(80,  180, 80)
local C_RED        = Color3.fromRGB(180, 80,  80)
local C_CHECK_ON   = Color3.fromRGB(40,  120, 220)
local C_CHECK_OFF  = Color3.fromRGB(50,  55,  65)

local FONT   = Drawing.Fonts.Plex
local FSIZE  = s(11)
local FSIZEB = s(12)

------------------------------------------------------------------------
-- DRAWING HELPERS
------------------------------------------------------------------------
local drawings = {}

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    table.insert(drawings, d)
    return d
end

local function rect(x, y, w, h, color, filled, thickness)
    return newDrawing("Square", {
        Position = Vector2.new(s(x), s(y)),
        Size     = Vector2.new(s(w), s(h)),
        Color    = color or Color3.fromRGB(28,30,35),
        Filled   = filled ~= false,
        Thickness = thickness or 1,
        Visible  = true,
    })
end

local function outline(x, y, w, h, color, thickness)
    return rect(x, y, w, h, color or Color3.fromRGB(55,60,68), false, thickness or 1)
end

local function text(str, x, y, size, color, bold)
    return newDrawing("Text", {
        Text      = str,
        Position  = Vector2.new(s(x), s(y)),
        Size      = size or FSIZE,
        Color     = color or C_TEXT,
        Font      = FONT,
        Bold      = bold or false,
        Outline   = false,
        Visible   = true,
    })
end

local function line(x1, y1, x2, y2, color, thickness)
    return newDrawing("Line", {
        From      = Vector2.new(s(x1), s(y1)),
        To        = Vector2.new(s(x2), s(y2)),
        Color     = color or Color3.fromRGB(55,60,68),
        Thickness = thickness or 1,
        Visible   = true,
    })
end

------------------------------------------------------------------------
-- STATE
------------------------------------------------------------------------
local menuVisible = true
local menuDrawings = {}  -- all drawings that belong to the menu (togglable)

local function menuDrawing(class, props)
    local d = newDrawing(class, props)
    table.insert(menuDrawings, d)
    return d
end

local function mRect(x, y, w, h, color, filled, thickness)
    return menuDrawing("Square", {
        Position = Vector2.new(s(x), s(y)),
        Size     = Vector2.new(s(w), s(h)),
        Color    = color or Color3.fromRGB(28,30,35),
        Filled   = filled ~= false,
        Thickness = thickness or 1,
        Visible  = true,
    })
end

local function mOutline(x, y, w, h, color, thickness)
    return mRect(x, y, w, h, color or Color3.fromRGB(55,60,68), false, thickness or 1)
end

local function mText(str, x, y, size, color, bold)
    return menuDrawing("Text", {
        Text      = str,
        Position  = Vector2.new(s(x), s(y)),
        Size      = size or FSIZE,
        Color     = color or C_TEXT,
        Font      = FONT,
        Bold      = bold or false,
        Outline   = false,
        Visible   = true,
    })
end

local function mLine(x1, y1, x2, y2, color, thickness)
    return menuDrawing("Line", {
        From      = Vector2.new(s(x1), s(y1)),
        To        = Vector2.new(s(x2), s(y2)),
        Color     = color or Color3.fromRGB(55,60,68),
        Thickness = thickness or 1,
        Visible   = true,
    })
end

------------------------------------------------------------------------
-- INTERACTION TRACKING
------------------------------------------------------------------------
local sliders    = {}  -- {fillRect, track{x,y,w,h}, valueText, maxVal, currentVal}
local checkboxes = {}  -- {box, state, label}
local toggles    = {}  -- {label, state, textObj}

------------------------------------------------------------------------
-- BUILD MENU
------------------------------------------------------------------------
local function buildMenu()
    menuDrawings = {}
    sliders    = {}
    checkboxes = {}
    toggles    = {}

    local wx = WIN_X
    local wy = WIN_Y
    local ww = WIN_W
    local wh = WIN_H

    -- Outer window bg
    mRect(wx, wy, ww, wh, Color3.fromRGB(20,22,25))
    mOutline(wx, wy, ww, wh, Color3.fromRGB(55,60,68))

    -- Title bar
    mRect(wx, wy, ww, 22, Color3.fromRGB(28,30,35))
    mOutline(wx, wy, ww, 22, Color3.fromRGB(55,60,68))
    mText("Abyss V3", wx+8, wy+5, FSIZEB, C_TEXT_B, true)

    -- Tab bar
    local tabs = {"Main","Rage","Visuals","Misc","Settings"}
    local tw = math.floor(ww / #tabs)
    mRect(wx, wy+22, ww, 22, Color3.fromRGB(24,26,30))
    for i, name in ipairs(tabs) do
        local tx = wx + tw*(i-1)
        local isActive = (name == "Main")
        mRect(tx, wy+22, tw, 22, isActive and Color3.fromRGB(35,38,44) or Color3.fromRGB(24,26,30))
        mOutline(tx, wy+22, tw, 22, Color3.fromRGB(55,60,68))
        mText(name, tx + math.floor(tw/2) - s(#name*3), wy+27, FSIZE, isActive and C_TEXT_B or C_TEXT, isActive)
        if isActive then
            mRect(tx, wy+22+20, tw, 2, C_ACCENT)
        end
    end

    -- Column divider
    mLine(wx + COL_W, wy+44, wx + COL_W, wy+wh, Color3.fromRGB(55,60,68))

    -- Content bounds
    local lx = wx + 6
    local rx = wx + COL_W + 6
    local cy = wy + 50

    ------------------------------------------------------------
    -- HELPERS (positioned)
    ------------------------------------------------------------
    local function sectionLabel(col, y, txt)
        mText(txt, col, y, FSIZE, C_TEXT_B, false)
        return y + 14
    end

    local function enabledToggle(col, y, txt, on)
        local statusColor = on and C_GREEN or C_RED
        local statusTxt = on and "Enabled" or "Disabled"
        local tObj = mText("  " .. statusTxt, col, y, FSIZE, statusColor, false)
        local entry = {textObj=tObj, state=on, x=s(col), y=s(y), w=s(100), h=s(12)}
        table.insert(toggles, entry)
        return y + 16
    end

    local function slider(col, y, labelTxt, val, maxV)
        mText(labelTxt, col, y, FSIZE, C_TEXT, false)
        local sw = COL_W - 14
        local sy = y + 14
        -- track bg
        mRect(col, sy, sw, 12, C_SLIDER_BG)
        mOutline(col, sy, sw, 12, Color3.fromRGB(55,60,68))
        -- fill
        local pct = math.clamp(val/maxV, 0, 1)
        local fw = math.floor(sw * pct)
        local fillR = mRect(col, sy, fw, 12, C_ACCENT)
        -- value text
        local valT = mText(tostring(val).."/"..tostring(maxV), col + math.floor(sw/2) - s(12), sy+1, FSIZE-1, C_TEXT_B, false)
        -- register slider
        table.insert(sliders, {
            fillRect  = fillR,
            valText   = valT,
            tx = col, ty = sy, tw = sw, th = 12,
            maxVal    = maxV,
            currentVal= val,
        })
        return y + 32
    end

    local function dropdown(col, y, labelTxt, selected)
        local hasLabel = labelTxt ~= ""
        if hasLabel then
            mText(labelTxt, col, y, FSIZE, C_TEXT, false)
        end
        local dy = hasLabel and y+14 or y
        local dw = COL_W - 14
        mRect(col, dy, dw, 18, C_DROP_BG)
        mOutline(col, dy, dw, 18, Color3.fromRGB(55,60,68))
        mText(selected or "Head", col+4, dy+3, FSIZE, C_TEXT_B, false)
        mText("+", col+dw-14, dy+3, FSIZE, C_TEXT, false)
        return dy + 22
    end

    local function checkbox(col, y, labelTxt, checked)
        -- box
        local boxColor = checked and C_CHECK_ON or C_CHECK_OFF
        local boxR = mRect(col+2, y, 12, 12, boxColor)
        mOutline(col+2, y, 12, 12, Color3.fromRGB(55,60,68))
        if checked then
            mText("v", col+3, y, FSIZE-1, Color3.fromRGB(255,255,255), true)
        end
        mText(labelTxt, col+18, y, FSIZE, C_TEXT, false)
        local entry = {boxRect=boxR, state=checked, x=s(col+2), y=s(y), w=s(12), h=s(12)}
        table.insert(checkboxes, entry)
        return y + 18
    end

    local function divider(col, y)
        mLine(col, y, col+COL_W-14, y, Color3.fromRGB(55,60,68))
        return y + 6
    end

    ------------------------------------------------------------
    -- LEFT COLUMN
    ------------------------------------------------------------
    local ly = cy

    ly = sectionLabel(lx, ly, "Aim Assist")
    ly = enabledToggle(lx, ly, "Enabled", true)
    ly = slider(lx, ly, "Aimbot FOV", 100, 250)
    ly = slider(lx, ly, "Aimbot FOV", 100, 250)
    ly = slider(lx, ly, "Smoothing", 5, 10)
    ly = sectionLabel(lx, ly, "Smoothing Type")
    ly = dropdown(lx, ly, "", "Linear")
    ly = slider(lx, ly, "Randomization", 5, 20)
    ly = slider(lx, ly, "Deadzone FOV", 1, 10)
    ly = sectionLabel(lx, ly, "Aimbot Key")
    ly = dropdown(lx, ly, "", "Mouse 1")
    ly = sectionLabel(lx, ly, "Hitscan Priority")
    ly = dropdown(lx, ly, "", "Head")
    ly = sectionLabel(lx, ly, "Hitscan Points")
    ly = dropdown(lx, ly, "", "Head")
    ly = checkbox(lx, ly, "Adjust for Bullet Drop", false)
    ly = checkbox(lx, ly, "Target Prediction", false)
    ly = slider(lx, ly, "Enlarge Enemy Hitboxes", 0, 100)
    ly = divider(lx, ly)
    ly = sectionLabel(lx, ly, "Recoil Control")
    ly = checkbox(lx, ly, "  Weapon RCS", false)
    ly = slider(lx, ly, "Recoil Control X", 10, 100)
    ly = slider(lx, ly, "Recoil Control Y", 10, 100)

    ------------------------------------------------------------
    -- RIGHT COLUMN
    ------------------------------------------------------------
    local ry = cy

    ry = sectionLabel(rx, ry, "Trigger Bot")
    ry = enabledToggle(rx, ry, "Enabled", true)
    ry = sectionLabel(rx, ry, "Trigger Bot Hitboxes")
    ry = dropdown(rx, ry, "", "Head")
    ry = checkbox(rx, ry, "  Trigger When Aiming", false)
    ry = slider(rx, ry, "Aim Percentage", 1, 100)
    ry = sectionLabel(rx, ry, "Bullet Redirection")
    ry = checkbox(rx, ry, "  Silent Aim", false)
    ry = slider(rx, ry, "Silent Aim FOV", 100, 250)
    ry = slider(rx, ry, "Hit Chance", 30, 100)
    ry = slider(rx, ry, "Accuracy", 90, 100)
    ry = sectionLabel(rx, ry, "Hitscan Priority")
    ry = dropdown(rx, ry, "", "Head")
    ry = sectionLabel(rx, ry, "Hitscan Points")
    ry = dropdown(rx, ry, "", "Head")
end

------------------------------------------------------------------------
-- FLOATING TOGGLE BUTTON (Roblox Instance — draggable)
------------------------------------------------------------------------
local AbyssUI = Instance.new("ScreenGui")
AbyssUI.Name = "AbyssToggle"
AbyssUI.ResetOnSpawn = false
AbyssUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
AbyssUI.Parent = playerGui

local FloatingToggle = Instance.new("TextButton")
FloatingToggle.Size = UDim2.new(0, 85, 0, 24)
FloatingToggle.Position = UDim2.new(0, 15, 0, 15)
FloatingToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
FloatingToggle.BorderColor3 = Color3.fromRGB(45, 45, 48)
FloatingToggle.BorderSizePixel = 1
FloatingToggle.Text = "[x] TOGGLE"
FloatingToggle.TextColor3 = Color3.fromRGB(240, 240, 240)
FloatingToggle.Font = Enum.Font.Arcade
FloatingToggle.TextSize = 12
FloatingToggle.Parent = AbyssUI

local ToggleScale = Instance.new("UIScale")
ToggleScale.Scale = 1.0
ToggleScale.Parent = FloatingToggle

-- Dragging logic for FloatingToggle
local draggingToggle = false
local dragStartPos, dragStartInput

FloatingToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingToggle = true
        dragStartPos  = FloatingToggle.Position
        dragStartInput = input.Position
    end
end)

FloatingToggle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingToggle = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingToggle and (input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartInput
        FloatingToggle.Position = UDim2.new(
            dragStartPos.X.Scale,
            dragStartPos.X.Offset + delta.X,
            dragStartPos.Y.Scale,
            dragStartPos.Y.Offset + delta.Y
        )
    end
end)

------------------------------------------------------------------------
-- TOGGLE MENU VISIBILITY
------------------------------------------------------------------------
local function setMenuVisible(v)
    menuVisible = v
    for _, d in ipairs(menuDrawings) do
        d.Visible = v
    end
    FloatingToggle.Text = menuVisible and "[x] TOGGLE" or "[ ] TOGGLE"
end

FloatingToggle.MouseButton1Click:Connect(function()
    setMenuVisible(not menuVisible)
end)

------------------------------------------------------------------------
-- SLIDER INTERACTION
------------------------------------------------------------------------
local activeSlider = nil

UserInputService.InputBegan:Connect(function(input)
    if not menuVisible then return end
    if input.UserInputType ~= Enum.UserInputType.Touch and
       input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local pos = input.UserInputType == Enum.UserInputType.Touch
        and input.Position or input.Position

    -- Check sliders
    for _, sl in ipairs(sliders) do
        local sx = s(sl.tx); local sy2 = s(sl.ty)
        local sw = s(sl.tw); local sh = s(sl.th)
        if pos.X >= sx and pos.X <= sx+sw and pos.Y >= sy2 and pos.Y <= sy2+sh then
            activeSlider = sl
            break
        end
    end

    -- Check checkboxes
    for _, cb in ipairs(checkboxes) do
        if pos.X >= cb.x and pos.X <= cb.x+cb.w and
           pos.Y >= cb.y and pos.Y <= cb.y+cb.h then
            cb.state = not cb.state
            cb.boxRect.Color = cb.state and C_CHECK_ON or C_CHECK_OFF
        end
    end

    -- Check toggles
    for _, tg in ipairs(toggles) do
        if pos.X >= tg.x and pos.X <= tg.x+tg.w and
           pos.Y >= tg.y and pos.Y <= tg.y+tg.h then
            tg.state = not tg.state
            tg.textObj.Text  = tg.state and "  Enabled" or "  Disabled"
            tg.textObj.Color = tg.state and C_GREEN or C_RED
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        activeSlider = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if activeSlider == nil then return end
    if input.UserInputType ~= Enum.UserInputType.Touch and
       input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    local pos = input.Position
    local sx  = s(activeSlider.tx)
    local sw  = s(activeSlider.tw)
    local pct = math.clamp((pos.X - sx) / sw, 0, 1)
    local newVal = math.floor(pct * activeSlider.maxVal)

    activeSlider.currentVal = newVal
    activeSlider.fillRect.Size = Vector2.new(math.floor(sw * pct), s(activeSlider.th))
    activeSlider.valText.Text  = tostring(newVal).."/"..tostring(activeSlider.maxVal)
end)

------------------------------------------------------------------------
-- INIT
------------------------------------------------------------------------
buildMenu()
setMenuVisible(true)

print("Abyss V3 Drawing UI loaded | Scale: " .. SCALE)
