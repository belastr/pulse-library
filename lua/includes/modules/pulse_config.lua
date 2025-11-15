AddCSLuaFile()

require("pulse_net")
require("pulse_sql")

local pulse_config = pulse_config or {}

pnet.Define("pulse_config", {
    sc = {"Data"},
    cs = {"Data"},
    superadmin = true
})

local function encode(val)
    return util.TableToJSON({ val = val })
end

local function decode(str, default)
    if not str or str == "" then return default end
    local ok, tbl = pcall(util.JSONToTable, str)
    if not ok or not tbl then return default end
    return tbl.val
end

if SERVER then
    local db = psql("pulse_config", {
        section = "VARCHAR(255) NOT NULL",
        keyname = "VARCHAR(255) NOT NULL",
        value = "TEXT",

        constraints = {
            "PRIMARY KEY (section, keyname)"
        }
    })

    pulse_config._sections = {}

    local gconfBuilder = {}
    gconfBuilder.__index = gconfBuilder

    function gconfBuilder:AddConfig(keyname, def)
        self._configs[keyname] = def
        return self
    end

    function gconfBuilder:End()
        local section = self._name
        pulse_config._sections[section] = pulse_config._sections[section] or {}

        for keyname, def in pairs(self._configs) do
            local row = db:select({section = section, keyname = keyname})

            local value
            if istable(row[1]) then
                value = decode(row[1].value, def.default)
            else
                value = def.default
                db:insert({section = section, keyname = keyname, value = encode(def.default)})
            end

            def.value = value
            pulse_config._sections[section][keyname] = def
        end

        return self._configs
    end

    function pulse_config.Register(name)
        local builder = setmetatable({}, gconfBuilder)
        builder._name = name
        builder._configs = {}
        return builder
    end

    function pulse_config.Get(section, keyname)
        local sec = pulse_config._sections[section]
        if not sec or not sec[keyname] then return nil end
        return sec[keyname].value
    end

    local function validateType(expected, value)
        if expected == "String" then
            return isstring(value)
        elseif expected == "Float" or expected == "Int" then
            return isnumber(value)
        elseif expected == "Boolean" then
            return isbool(value)
        elseif expected == "Table" then
            return istable(value)
        end
        return false
    end

    function pulse_config.Set(section, keyname, value)
        local sec = pulse_config._sections[section]
        if not sec or not sec[keyname] then return end

        local def = sec[keyname]
        if not validateType(def.type, value) then
            ErrorNoHalt(string.format("pconf | type mismatch for %s.%s (expected %s, got %s)\n", section, keyname, def.type, type(value)))
            return
        end

        def.value = value
        db:update({value = encode(value)}, {section = section, keyname = keyname})
    end

    function pulse_config.CleanupDB()
        local registered = {}
        for sectionname, section in pairs(pulse_config._sections) do
            registered[sectionname] = {}
            for keyname, _ in pairs(section) do
                registered[sectionname][keyname] = true
            end
        end

        local rows = db:select()
        if not rows then return end

        local count = 0
        for _, row in ipairs(rows) do
            local section = row.section
            local keyname = row.keyname

            if not registered[section] or not registered[section][keyname] then
                db:delete({section = section, keyname = keyname})
                count = count + 1
            end
        end

        print(string.format("pconf | removed %s stale db entries", count))
    end

    concommand.Add("pulse_config", function(ply)
        if not IsValid(ply) then
            print("pconf | pulse_config is only available in-game")
            return
        elseif not ply:IsSuperAdmin() then
            ply:PrintMessage(HUD_PRINTCONSOLE, "You do not have access to In-game configuration.")
            return
        end

        print(string.format("pconf | Client \"%s\" has opened the In-game configuration (%s)", ply:Nick(), ply:SteamID()))
        pnet.Send("pulse_config", ply, pulse_config._sections)
    end)

    pnet.Receive("pulse_config", function(ply, data)
        local section, keyname, value = data[1], data[2], data[3]
        print(string.format("pconf | Client \"%s\" has updated %s:%s (%s)", ply:Nick(), section, keyname, ply:SteamID()))

        local sec = pulse_config._sections[section]
        if not sec or not sec[keyname] then return end

        value = decode(value)

        local t = sec[keyname].type
        if t == "Float" or t == "Int" then
            value = tonumber(value)
        elseif t == "Boolean" then
            value = tobool(value)
        end

        pulse_config.Set(section, keyname, value)
    end)
elseif CLIENT then
    local _sections

    local function OpenMenu()
        local height = ScrH() * 0.9
        local width = height / 1.125

        local frame = vgui.Create("DFrame")
        frame:SetSize(width, height)
        frame:SetSizable(true)
        frame:Center()
        frame:MakePopup()
        frame:SetTitle("In-game configuration (pulse_config)")
        frame.OnClose = function()
            _sections = nil
        end

        local left = vgui.Create("Panel", frame)
        local properties = vgui.Create("DProperties", frame)
        local help = vgui.Create("DPanel", frame)
        local categories = vgui.Create("DListView", frame)

        local helpText = vgui.Create("DLabel", help)
        helpText:Dock(FILL)
        helpText:DockMargin(4, 4, 4, 4)
        helpText:SetTextColor(color_black)
        helpText:SetText("")
        helpText:SetWrap(true)

        local hDivider = vgui.Create("DHorizontalDivider", frame)
        hDivider:Dock(FILL)
        hDivider:DockMargin(8, 8, 8, 8)
        hDivider:SetLeft(left)
        hDivider:SetRight(properties)
        hDivider:SetDividerWidth(8)
        hDivider:SetLeftMin(width * 0.1)
        hDivider:SetRightMin(width * 0.6)
        hDivider:SetLeftWidth(width * 0.25)

        local vDivider = vgui.Create("DVerticalDivider", left)
        vDivider:Dock(FILL)
        vDivider:SetTop(help)
        vDivider:SetBottom(categories)
        vDivider:SetDividerHeight(8)
        vDivider:SetTopMin(height * 0.1)
        vDivider:SetBottomMin(height * 0.6)
        vDivider:SetTopHeight(height * 0.15)

        categories:SetMultiSelect(false)
        categories:SetSortable(false)
        categories:AddColumn("Jump to Section")
        categories.OnRowSelected = function(list, _, line)
            local category = properties:GetCategory(line:GetColumnText(1))
            if IsValid(category) then properties:GetCanvas():ScrollToChild(category) end
            list:ClearSelection()
        end

        for sectionname, section in SortedPairs(_sections) do
            categories:AddLine(string.NiceName(sectionname))

            for keyname, def in SortedPairs(section) do
                local row = properties:CreateRow(string.NiceName(sectionname), string.NiceName(keyname))
                if def.type == "String" then
                    row:Setup("Generic")
                elseif def.type == "Float" or def.type == "Int" then
                    row:Setup(def.type, {min = def.min or 0, max = def.max or 100})
                elseif def.type == "Table" then
                    row:Setup("Table", def.schema)
                else
                    row:Setup(def.type)
                end
                row:SetValue(def.value)

                row.Think = function(r)
                    if helpText.helping ~= r and r:IsHovered() then
                        helpText.helping = r

                        local text = def.desc or "No description found."
                        if not istable(def.default) then
                            text = text .. "\n\nDefault: " .. def.default
                        end
                        if def.min and def.max then
                            text = text .. "\n\nMinimum: " .. def.min .. "\nMaximum: " .. def.max
                        end
                        helpText:SetText(text)
                    end
                end

                row.DataChanged = function(_, val)
                    if def.type == "Float" then
                        val = math.Truncate(val, 2)
                    elseif def.type == "Int" then
                        val = math.Truncate(val)
                    end
                    pnet.Send("pulse_config", {sectionname, keyname, encode(val)})
                end
            end
        end
    end

    pnet.Receive("pulse_config", function(sections)
        _sections = sections
        OpenMenu()
    end)
end

pconf = pulse_config