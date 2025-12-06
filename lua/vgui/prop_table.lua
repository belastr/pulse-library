local addEditRow = vgui.RegisterTable({
    Init = function(self)
        local height = ScrH() * 0.4
        local width = height / 1.125

        self:SetSize(width, height)
        self:SetSizable(true)
        self:Center()
        self:ShowCloseButton(false)
        self:MakePopup()

        self.btns = vgui.Create("Panel", self)
        self.btns:Dock(TOP)
        self.btns:DockMargin(8, 8, 8, 8)
        self.btns:SetHeight(22)

        self.cancel = vgui.Create("PButton", self.btns)
        self.cancel:SetText("Cancel")
        self.cancel:Dock(LEFT)
        self.cancel.DoClick = function()
            self:Close()
        end

        self.save = vgui.Create("PButton", self.btns)
        self.save:SetText("Save")
        self.save:Dock(RIGHT)
        self.save.DoClick = function()
            if self:GetTitle() == "Edit" then
                self.tbl:RemoveLine(self.row)
            end

            local varargs = {}
            for _, k in ipairs(self.tbl.columnTags) do
                if self.values[k] then
                    table.insert(varargs, self.values[k])
                else
                    table.insert(varargs, "")
                end
            end
            local line = self.tbl:AddLine(unpack(varargs))
            line.values = table.Copy(self.values)

            self:Close()
        end

        self.props = vgui.Create("PProperties", self)
        self.props:Dock(FILL)
        self.props:DockMargin(8, 0, 8, 8)
    end,

    Setup = function(self, schema, values)
        self.values = values or {}

        for k, def in SortedPairs(schema) do
            local row = self.props:CreateRow("Edit", string.NiceName(k))
            if def.type == "String" then
                row:Setup("Generic")
            elseif def.type == "Float" or def.type == "Int" then
                row:Setup(def.type, {min = def.min, max = def.max})
            elseif def.type == "Table" then
                row:Setup("Table", def.schema)
            else
                row:Setup(def.type)
            end

            if values and values[k] and values[k] ~= "" then
                row:SetValue(values[k])
            elseif def.default then
                row:SetValue(def.default)
                self.values[k] = def.default
            end

            row.DataChanged = function(_, val)
                if def.type == "Float" then
                    val = math.Truncate(val, 2)
                elseif def.type == "Int" then
                    val = math.Truncate(val)
                end

                self.values[k] = val
            end
        end
    end
}, "PFrame")

local PANEL = {}

function PANEL:Init()
end

function PANEL:Setup(schema)
    self:Clear()

    local height = ScrH() * 0.5
    local width = height / 0.5625

    local tblFrame = vgui.Create("PFrame")
    tblFrame:SetSize(width, height)
    tblFrame:SetSizable(true)
    tblFrame:Center()
    tblFrame:SetTitle("Edit Table")
    tblFrame:SetDeleteOnClose(false)
    tblFrame:ShowCloseButton(false)
    tblFrame:Close()

    local btns = vgui.Create("Panel", tblFrame)
    btns:Dock(BOTTOM)
    btns:DockMargin(8, 8, 8, 8)
    btns:SetHeight(22)

    local add = vgui.Create("PButton", btns)
    add:SetText("Add")
    add:Dock(LEFT)
    add:DockMargin(0, 0, 8, 0)

    local rmv = vgui.Create("PButton", btns)
    rmv:SetText("Remove")
    rmv:Dock(LEFT)

    local save = vgui.Create("PButton", btns)
    save:SetText("Save")
    save:Dock(RIGHT)
    save:DockMargin(8, 0, 0, 0)

    local cancel = vgui.Create("PButton", btns)
    cancel:SetText("Cancel")
    cancel:Dock(RIGHT)

    tblFrame.tbl = vgui.Create("PListView", tblFrame)
    tblFrame.tbl:Dock(FILL)
    tblFrame.tbl:DockMargin(8, 8, 8, 0)
    tblFrame.tbl.columnTags = {}

    for k, _ in SortedPairs(schema) do
        tblFrame.tbl:AddColumn(string.NiceName(k))
        table.insert(tblFrame.tbl.columnTags, k)
    end

    local btn = self:Add("PButton")
    btn:SetText("Edit Table")
    btn:SetHeight(15)
    btn:SetPos(0, 2)

    self.IsEditing = function()
        return tblFrame:IsVisible()
    end

    self.IsEnabled = function()
        return btn:IsEnabled()
    end
    self.SetEnabled = function(_, b)
        btn:SetEnabled(b)
    end

    self.SetValue = function(_, tbl)
        self.backup = table.Copy(tbl)

        for _, v in ipairs(tbl) do
            local varargs = {}
            for _, k in ipairs(tblFrame.tbl.columnTags) do
                if v[k] then
                    table.insert(varargs, v[k])
                else
                    table.insert(varargs, "")
                end
            end
            local line = tblFrame.tbl:AddLine(unpack(varargs))
            line.values = table.Copy(v)
        end
    end

    btn.DoClick = function()
        tblFrame:Show()
        tblFrame:MakePopup()
    end
    tblFrame.GetTable = function(slf)
        return slf.tbl
    end
    tblFrame.tbl.OnRowRightClick = function(_, _, row)
        local d = PulseMenu(false, row)
        d:AddOption("Edit", function()
            local editFrame = vgui.CreateFromTable(addEditRow)
            editFrame:SetTitle("Edit")
            editFrame.tbl = tblFrame.tbl
            editFrame.row = row:GetID()
            editFrame:Setup(schema, row.values)
        end)
        d:Open()
    end
    add.DoClick = function()
        local addFrame = vgui.CreateFromTable(addEditRow)
        addFrame:SetTitle("Add")
        addFrame.tbl = tblFrame.tbl
        addFrame:Setup(schema)
    end
    rmv.Think = function(slf)
        if not tblFrame.tbl:GetSelected()[1] then
            slf:SetEnabled(false)
        else
            slf:SetEnabled(true)
        end
    end
    rmv.DoClick = function()
        for _, l in ipairs(tblFrame.tbl:GetSelected()) do
            tblFrame.tbl:RemoveLine(l:GetID())
        end
    end
    save.DoClick = function()
        table.Empty(self.backup)
        for _, l in SortedPairs(tblFrame.tbl:GetLines()) do
            local copy = table.Copy(l.values or {})
            for k, v in pairs(copy) do
                if isstring(v) and v == "" then
                    copy[k] = nil
                end
            end
            table.insert(self.backup, copy)
        end

        self:ValueChanged(self.backup)

        tblFrame:Close()
    end
    cancel.DoClick = function()
        local tmp = self.backup

        tblFrame:Remove()
        self:Setup(schema)
        self:SetValue(tmp)
    end

    return tblFrame
end

derma.DefineControl("DProperty_Table", "", PANEL, "DProperty_Generic")