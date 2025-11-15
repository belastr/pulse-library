AddCSLuaFile()

if SERVER then return end

local pulse_hud = pulse_hud or {}
pulse_hud._elements = pulse_hud._elements or {}
pulse_hud._isEditing = false
pulse_hud._editFrames = {}

function pulse_hud.AddElement(id, data)
    if not data or not isfunction(data.draw) then return end
    pulse_hud._elements[id] = {
        draw = data.draw,
        w = data.w,
        h = data.h,
        r = data.w / data.h,
        f = data.fonts,
        defaults = table.Copy(data.defaults or {
            x = 0, y = 0, scale = 1, visible = true
        }),
        settings = table.Copy(data.defaults or {
            x = 0, y = 0, scale = 1, visible = true
        })
    }
    if istable(data.fonts) then
        for n, d in pairs(data.fonts) do
            local fontData = table.Copy(d)
            fontData.size = fontData.size * pulse_hud._elements[id].settings.scale

            surface.CreateFont(id .. "_" .. n, fontData)
        end
    end
end

local W, H = ScrW(), ScrH()
hook.Add("HUDPaint", "pulse_hud", function()
    for _, element in pairs(pulse_hud._elements) do
        local s = element.settings
        if s.visible then
            element.draw(W * s.x, H * s.y, s.scale)
        end
    end
end)

hook.Add("OnScreenSizeChanged", "pulse_hud", function(_, _, newWidth, newHeight)
    W, H = newWidth, newHeight
end)

hook.Add("InitPostEntity", "pulse_hud", function()
    pulse_hud.Load(true)
    pulse_hud.EditMode(false)
end)

concommand.Add("pulse_hud", function()
    pulse_hud.EditMode(not pulse_hud._isEditing)
end)

function pulse_hud.EditMode(state, nosave)
    pulse_hud._isEditing = state

    if state then
        pulse_hud._backup = table.Copy(pulse_hud._elements)

        pulse_hud.OpenEditors()
    else
        pulse_hud.CloseEditors()

        if nosave then
            pulse_hud._elements = table.Copy(pulse_hud._backup)
            table.Empty(pulse_hud._backup)
            return
        else
            for id, element in pairs(pulse_hud._elements) do
                if istable(element.f) then
                    for n, d in pairs(element.f) do
                        local fontData = table.Copy(d)
                        fontData.size = fontData.size * element.settings.scale

                        surface.CreateFont(id .. "_" .. n, fontData)
                    end
                end
            end
        end

        pulse_hud.Save()
    end
end

local textColor = Color(0, 125, 255)
function pulse_hud.OpenEditors()
    for id, element in pairs(pulse_hud._elements) do
        local s = element.settings

        local frame = vgui.Create("DFrame")
        frame:SetTitle("")
        frame:SetSize(element.w * s.scale + 6, element.h * s.scale + 6)
        frame:SetPos(W * s.x - 3, H * s.y - 3)
        frame:ShowCloseButton(false)
        frame:SetVisible(s.visible)
        frame.Think = function(slf)
            local mousex = math.Clamp(gui.MouseX(), 1, W - 1)
	        local mousey = math.Clamp(gui.MouseY(), 1, H - 1)

            if slf.Dragging then
                local x = mousex - slf.Dragging[1]
                local y = mousey - slf.Dragging[2]

                x = math.Clamp(x, -3, W + 3 - slf:GetWide())
                y = math.Clamp(y, -3, H + 3 - slf:GetTall())

                s.x = math.Truncate((x + 3) / W, 2)
                s.y = math.Truncate((y + 3) / H, 2)
                slf:SetPos(W * s.x - 3, H * s.y - 3)
            end

            if slf.Sizing then
                local x = mousex - slf.Sizing[1]
                local y = mousey - slf.Sizing[2]
                local px, py = slf:GetPos()

                if math.abs(x / y - element.r) > 0.001 then y = x / element.r end
                if x < 100 then x = 100 elseif x > W - px then x = W - px end
                if y < 100 then y = 100 elseif y > H - py then y = H - py end

                s.scale = math.Truncate((x - 6) / element.w, 2)

                slf:SetSize(element.w * s.scale + 6, element.h * s.scale + 6)
                slf:SetCursor("sizenwse")
                return
            end

            local screenX, screenY = slf:LocalToScreen(0, 0)

            if slf.Hovered and mousex > screenX + slf:GetWide() - 20 && mousey > screenY + slf:GetTall() - 20 then
                slf:SetCursor("sizenwse")
                return
            end

            if slf.Hovered then
                slf:SetCursor("sizeall")
                return
            end

            slf:SetCursor("arrow")

            if slf.y < -3 then
                slf:SetPos(slf.x, -3)
            end
        end
        frame.Paint = function(slf, w, h)
            if slf.Hovered or slf.Dragging or slf.Sizing then
                surface.SetDrawColor(0, 125, 255, 25)
                surface.DrawRect(3, 3, w - 6, h - 6)

                draw.SimpleText(id, "DermaDefault", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            surface.SetDrawColor(0, 125, 255, 225)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
        frame.OnMousePressed = function(slf)
            local screenX, screenY = slf:LocalToScreen(0, 0)

            if gui.MouseX() > screenX + slf:GetWide() - 24 and gui.MouseY() > screenY + slf:GetTall() - 24 then
                slf.Sizing = {gui.MouseX() - slf:GetWide(), gui.MouseY() - slf:GetTall()}
            else
                slf.Dragging = {gui.MouseX() - slf.x, gui.MouseY() - slf.y}
            end

            slf:MouseCapture(true)
        end

        pulse_hud._editFrames[id] = frame
    end

    gui.EnableScreenClicker(true)

    local height = H * 0.35
    local width = height / 1.125

    local frame = vgui.Create("DFrame")
    frame:SetSize(width, height)
    frame:Center()
    frame:SetTitle("Edit HUD (Notice: Texts rescale on save)")
    frame:MakePopup()
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)

    local btns = vgui.Create("Panel", frame)
    btns:Dock(BOTTOM)
    btns:DockMargin(8, 8, 8, 8)
    btns:SetHeight(22)

    local cancel = vgui.Create("DButton", btns)
    cancel:SetText("Cancel")
    cancel:Dock(LEFT)
    cancel.DoClick = function()
        pulse_hud.EditMode(false, true)
        frame:Close()
    end

    local save = vgui.Create("DButton", btns)
    save:SetText("Save")
    save:Dock(RIGHT)
    save.DoClick = function()
        pulse_hud.EditMode(false)
        frame:Close()
    end

    local reset = vgui.Create("DButton", btns)
    reset:SetText("Reset to Default")
    reset:Dock(BOTTOM)
    reset:DockMargin(8, 0, 8, 0)
    reset.DoClick = function()
        for _, element in pairs(pulse_hud._elements) do
            element.settings = table.Copy(element.defaults)
        end
        frame:Close()
        pulse_hud.CloseEditors()
        pulse_hud.OpenEditors()
    end

    local elements = vgui.Create("DScrollPanel", frame)
    elements:Dock(FILL)
    elements:DockMargin(8, 8, 8, 0)
    for id, element in SortedPairs(pulse_hud._elements) do
        local panel = elements:Add("Panel")
        panel:Dock(TOP)
        panel:DockMargin(0, 0, 0, 4)
        panel:SetTall(15)

        panel.Button = vgui.Create("DCheckBox", panel)
        panel.Button:Dock(RIGHT)
        panel.Button:DockMargin(4, 0, 0, 0)
        panel.Button:SetTall(15)
        panel.Button:SetChecked(element.settings.visible)
        panel.Button.OnChange = function(_, val)
            element.settings.visible = val
            pulse_hud._editFrames[id]:SetVisible(val)
        end

        panel.Label = vgui.Create("DLabel", panel)
        panel.Label:Dock(FILL)
        panel.Label:SetText(id)
        panel.Label:SetMouseInputEnabled(true)
        panel.Label.DoClick = function() panel.Button:Toggle() end
    end
end

function pulse_hud.CloseEditors()
    for _, frame in pairs(pulse_hud._editFrames) do
        if IsValid(frame) then
            frame:Remove()
        end
    end

    gui.EnableScreenClicker(false)
    pulse_hud._editFrames = {}
end

function pulse_hud.Load(bFillTable)
    if not file.Exists("ghud_settings.json", "DATA") then return {} end
    local data, ok = file.Read("ghud_settings.json", "DATA")

    ok, data = pcall(util.JSONToTable, data)
    if not ok then return {} end

    if bFillTable then
        for id, element in pairs(pulse_hud._elements) do
            element.settings = data[id]
        end
    end

    return data
end

function pulse_hud.Save()
    local data = pulse_hud.Load()

    for id, element in pairs(pulse_hud._elements) do
        data[id] = element.settings
    end

    data = util.TableToJSON(data, true)
    file.Write("ghud_settings.json", data)
end

phud = pulse_hud