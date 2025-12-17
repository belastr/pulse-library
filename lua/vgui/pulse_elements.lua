surface.CreateFont("PulseDefault", {
    font = "Roboto",
    size = 13,
    weight = 500,
    extended = true
})
surface.CreateFont("PulseDefaultBold", {
    font = "Roboto",
    size = 13,
    weight = 800,
    extended = true
})
surface.CreateFont("PulseHudDefault", {
    font = "Roboto",
    size = 20,
    weight = 900,
    antialias = true
})

local blur = Material("pp/blurscreen")

local PANEL

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PBinder", "Pulse Library DBinder", PANEL, "DBinder")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PButton", "Pulse Library DButton", PANEL, "DButton")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PCategoryList", "Pulse Library DCategoryList", PANEL, "DCategoryList")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PCheckBox", "Pulse Library DCheckBox", PANEL, "DCheckBox")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PCheckBoxLabel", "Pulse Library DCheckBoxLabel", PANEL, "DCheckBoxLabel")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PCollapsibleCategory", "Pulse Library DCollapsibleCategory", PANEL, "DCollapsibleCategory")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PColumnSheet", "Pulse Library DColumnSheet", PANEL, "DColumnSheet")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PComboBox", "Pulse Library DComboBox", PANEL, "DComboBox")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PDrawer", "Pulse Library DDrawer", PANEL, "DDrawer")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PFileBrowser", "Pulse Library DFileBrowser", PANEL, "DFileBrowser")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PForm", "Pulse Library DForm", PANEL, "DForm")

PANEL = {}
function PANEL:Init()
    self:SetSkin("Pulse")
    self.btnMaxim:Hide()
    self.btnMinim:Hide()
    self.lblTitle:SetFont("PulseDefaultBold")
end
function PANEL:Paint(w, h)
    local x, y = self:LocalToScreen(0, 0)

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)

    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * 4)
        blur:Recompute()
        render.UpdateScreenEffectTexture()

        render.SetScissorRect(x, y, x + w, y + h, true)
            surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    derma.SkinHook("Paint", "Frame", self, w, h)
	return true
end
function PANEL:PerformLayout(w)
    self.btnClose:SetPos(w - 31, 0)
    self.btnClose:SetSize(31, 24)

    self.lblTitle:SetPos(8, 2)
	self.lblTitle:SetSize(w - 25, 20)
end
derma.DefineControl("PFrame", "Pulse Library DFrame", PANEL, "DFrame")

PANEL = {}
function PANEL:Init()
    self:SetSkin("Pulse")
    self:SetHideButtons(true)
end
derma.DefineControl("PHScrollBar", "Pulse Library DHScrollBar", PANEL, "DHScrollBar")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PIconLayout", "Pulse Library DIconLayout", PANEL, "DIconLayout")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PLabel", "Pulse Library DLabel", PANEL, "DLabel")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PLabelEditable", "Pulse Library DLabelEditable", PANEL, "DLabelEditable")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PLabelURL", "Pulse Library DLabelURL", PANEL, "DLabelURL")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
function PANEL:AddColumn(strName, iPosition)
    if iPosition and (iPosition <= 0 or IsValid(self.Columns[iPosition])) then return end

    local pColumn = nil
    if self.m_bSortable then
        pColumn = vgui.Create("DListView_Column", self)
    else
        pColumn = vgui.Create("DListView_ColumnPlain", self)
    end

    pColumn.DraggerBar:SetFont("PulseDefault")
    pColumn:SetName(strName)
    pColumn:SetZPos(10)

    if iPosition then
        table.insert(self.Columns, iPosition, pColumn)

        local i = 1
        for _, pnl in pairs(self.Columns) do
            pnl:SetColumnID(i)
            i = i + 1
        end
    else
        local i = table.insert(self.Columns, pColumn)
        pColumn:SetColumnID(i)
    end

    self:InvalidateLayout()
    return pColumn
end
function PANEL:AddLine(...)
    self:SetDirty(true)
    self:InvalidateLayout()

    local pLine = vgui.Create("DListView_Line", self.pnlCanvas)
    local i = table.insert(self.Lines, pLine)
    pLine:SetListView(self)
    pLine:SetID(i)

    for c, _ in pairs(self.Columns) do
        pLine:SetColumnText(c, "")
        pLine.Columns[c]:SetFont("PulseDefault")
        pLine.Columns[c]:SetTextColor(color_white)
    end
    for c, s in pairs({...}) do
        pLine:SetColumnText(c, s)
    end

    local r = table.insert(self.Sorted, pLine)
    if r % 2 == 1 then
        pLine:SetAltLine(true)
    end

    return pLine
end
derma.DefineControl("PListView", "Pulse Library DListView", PANEL, "DListView")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
function PANEL:AddOption(strText, funcFunction)
    local pnl = vgui.Create("PMenuOption", self)
    pnl:SetMenu(self)
    pnl:SetText(strText)
    if funcFunction then pnl.DoClick = funcFunction end

    self:AddPanel(pnl)

    return pnl
end
function PANEL:AddCVar(strText, convar, on, off, funcFunction)
    local pnl = vgui.Create("DMenuOptionCVar", self)
    pnl:SetMenu(self)
    pnl:SetFont("PulseDefault")
    pnl:SetText(strText)
    if funcFunction then pnl.DoClick = funcFunction end

    pnl:SetConvar(convar)
    pnl:SetValueOn(on)
    pnl:SetValueOff(off)

    self:AddPanel(pnl)

    return pnl
end
derma.DefineControl("PMenu", "Pulse Library DMenu", PANEL, "DMenu")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
function PANEL:AddSubMenu()
    local SubMenu = PulseMenu(true, self)
    SubMenu:SetVisible(false)
    SubMenu:SetParent(self)

    self:SetSubMenu(SubMenu)

    return SubMenu
end
derma.DefineControl("PMenuOption", "Pulse Library DMenuOption", PANEL, "DMenuOption")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PNumberScratch", "Pulse Library DNumberScratch", PANEL, "DNumberScratch")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PNumberWang", "Pulse Library DNumberWang", PANEL, "DNumberWang")

PANEL = {}
function PANEL:Init()
    self:SetSkin("Pulse")
    self.TextArea:SetFont("PulseDefault")
    self.Label:SetFont("PulseDefault")
end
derma.DefineControl("PNumSlider", "Pulse Library DNumSlider", PANEL, "DNumSlider")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PPanel", "Pulse Library DPanel", PANEL, "DPanel")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
derma.DefineControl("PProgress", "Pulse Library DProgress", PANEL, "DProgress")

local tblRow = vgui.RegisterTable({
	Init = function(self)
		self:Dock(TOP)

		self.Label = self:Add("DLabel")
		self.Label:Dock(LEFT)
		self.Label:DockMargin(4, 4, 2, 4)
        self.Label:SetFont("PulseDefaultBold")

		self.Container = self:Add("Panel")
		self.Container:Dock(FILL)
	end,
	PerformLayout = function(self)
		self:SetTall(20)
		self.Label:SetWide(self:GetWide() * 0.45)
	end,
	Setup = function(self, rowType, vars)
		self.Container:Clear()

		local Name = "DProperty_" .. rowType
		if not vgui.GetControlTable(Name) then
			if rowType == "Bool" then rowType = "Boolean" end
			if rowType == "Vector" then rowType = "Generic" end
			if rowType == "Angle" then rowType = "Generic" end
			if rowType == "String" then rowType = "Generic" end

			Name = "DProperty_" .. rowType
		end

		if vgui.GetControlTable(Name) then self.Inner = self.Container:Add(Name) end
		if not IsValid(self.Inner) then self.Inner = self.Container:Add("DProperty_Generic") end

		self.Inner:SetRow(self)
		self.Inner:Dock(FILL)
		self.Inner:Setup(vars)
		self.Inner:SetEnabled(self:IsEnabled())

        for _, prop in pairs(self.Inner:GetChildren()) do
            if prop.SetFont then prop:SetFont("PulseDefault") end
            if prop.TextArea then
                prop.TextArea:SetFont("PulseDefault")
                prop.TextArea:SetTextColor(color_white)
            end
            if prop.Label then prop.Label:SetFont("PulseDefault") end
        end

		self.IsEnabled = function(slf)
			return slf.Inner:IsEnabled()
		end
		self.SetEnabled = function(slf, b)
			slf.Inner:SetEnabled(b)
		end

		if vars && vars.readonly then
			self:SetEnabled(false)
		end
	end,
	SetValue = function(self, val)
		if self.CacheValue && self.CacheValue == val then return end
		self.CacheValue = val

		if IsValid(self.Inner) then
			self.Inner:SetValue(val)
		end
	end,
	Paint = function(self, w, h)
		if not IsValid(self.Inner) then return end

		local Skin = self:GetSkin()
		local editing = self.Inner:IsEditing()
		local disabled = not self.Inner:IsEnabled() or not self:IsEnabled()

		if editing then
			surface.SetDrawColor(202, 188, 115)
			surface.DrawRect(0, 0, w, h)
		end

		if disabled then
			self.Label:SetTextColor(Skin.Colours.Properties.Label_Disabled)
		elseif editing then
			self.Label:SetTextColor(Skin.Colours.Properties.Label_Selected)
		else
			self.Label:SetTextColor(Skin.Colours.Properties.Label_Normal)
		end
	end
}, "Panel")

local tblCategory = vgui.RegisterTable({
	Init = function(self)
		self:Dock(TOP)
		self.Rows = {}

		self.Header = self:Add("Panel")

		self.Label = self.Header:Add("DLabel")
		self.Label:Dock(FILL)
		self.Label:SetContentAlignment(4)
        self.Label:SetFont("PulseDefaultBold")

		self.Expand = self.Header:Add("DExpandButton")
		self.Expand:Dock(LEFT)
		self.Expand:SetSize(16, 16)
		self.Expand:DockMargin(0, 5, 0, 5)
		self.Expand:SetExpanded(true)
		self.Expand.DoClick = function()
			self.Container:SetVisible(not self.Container:IsVisible())
			self.Expand:SetExpanded(self.Container:IsVisible())
			self:InvalidateLayout()
		end

		self.Header:Dock(TOP)

		self.Container = self:Add("Panel")
		self.Container:Dock(TOP)
		self.Container:DockMargin(16, 0, 0, 0)
	end,
	PerformLayout = function(self)
		self.Container:SizeToChildren(false, true)
		self:SizeToChildren(false, true)

		local Skin = self:GetSkin()
		self.Label:SetTextColor(Skin.Colours.Properties.Title)
		self.Label:DockMargin(4, 0, 0, 0)
	end,
	GetRow = function( self, name, bCreate )
		if IsValid(self.Rows[name]) then return self.Rows[name] end
		if not bCreate then return end

		local row = self.Container:Add(tblRow)
		row.Label:SetText(name)
		self.Rows[name] = row
		return row
	end,
	Paint = function(self, w, h)
		local skinColor = self:GetSkin().Colours.Properties.Border
		surface.SetDrawColor(skinColor.r, skinColor.g, skinColor.b, skinColor.a)
		surface.DrawRect(0, 0, w, h)
	end
}, "Panel")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
function PANEL:GetCanvas()
    if not IsValid(self.Canvas) then
        self.Canvas = self:Add("PScrollPanel")
        self.Canvas:Dock(FILL)
    end

    return self.Canvas
end
function PANEL:GetCategory(name, bCreate)
	local cat = self.Categories[name]
	if IsValid(cat) then return cat end
	if not bCreate then return end

	cat = self:GetCanvas():Add(tblCategory)
	cat.Label:SetText(name)
	self.Categories[name] = cat
	return cat
end
derma.DefineControl("PProperties", "Pulse Library DProperties", PANEL, "DProperties")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") end
function PANEL:AddSheet(label, panel, material, NoStretchX, NoStretchY, Tooltip)
    if not IsValid(panel) then return end

    local Sheet = {}
    Sheet.Name = label
    Sheet.Tab = vgui.Create("DTab", self)
    Sheet.Tab:SetTooltip(Tooltip)
    Sheet.Tab:Setup(label, self, panel, material)
    Sheet.Tab:SetFont("PulseDefault")
    Sheet.Panel = panel
    Sheet.Panel.NoStretchX = NoStretchX
    Sheet.Panel.NoStretchY = NoStretchY
    Sheet.Panel:SetPos(self:GetPadding(), 20 + self:GetPadding())
    Sheet.Panel:SetVisible(false)
    panel:SetParent(self)
    table.insert(self.Items, Sheet)

    if not self:GetActiveTab() then
        self:SetActiveTab(Sheet.Tab)
        Sheet.Panel:SetVisible(true)
    end

    self.tabScroller:AddPanel(Sheet.Tab)

    return Sheet
end
derma.DefineControl("PPropertySheet", "Pulse Library DPropertySheet", PANEL, "DPropertySheet")

PANEL = {}
function PANEL:Init()
    self:SetSkin("Pulse")
    self.VBar:SetHideButtons(true)
end
derma.DefineControl("PScrollPanel", "Pulse Library DScrollPanel", PANEL, "DScrollPanel")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PTextEntry", "Pulse Library DTextEntry", PANEL, "DTextEntry")

PANEL = {}
function PANEL:Init() self:SetSkin("Pulse") self:SetFont("PulseDefault") end
derma.DefineControl("PTooltip", "Pulse Library DTooltip", PANEL, "DTooltip")

PANEL = {}
function PANEL:Init()
    self:SetSkin("Pulse")
    self.RootNode.Label:SetFont("PulseDefault")
end
function PANEL:AddNode(strName, strIcon)
    local node = self.RootNode:AddNode(strName, strIcon)
    node.Label:SetFont("PulseDefault")
	return node
end
derma.DefineControl("PTree", "Pulse Library DTree", PANEL, "DTree")

PANEL = {}
function PANEL:Init()
    self:SetSkin("Pulse")
    self:SetHideButtons(true)
end
derma.DefineControl("PVScrollBar", "Pulse Library DVScrollBar", PANEL, "DVScrollBar")