function Derma_NumberRequest(strTitle, strText, nDefault, nMin, nMax, fnEnter, fnCancel, strCommitText, strCancelText)
    nMin = nMin or 0
    nMax = nMax or 1

	local frame = vgui.Create("DFrame")
	frame:SetTitle(strTitle or "Message Title (First Parameter)")
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:SetDrawOnTop(true)

	local panel = vgui.Create("DPanel", frame)
	panel:SetPaintBackground(false)

	local label = vgui.Create("DLabel", panel)
	label:SetText(strText or "Message Text (Second Parameter)")
	label:SizeToContents()
	label:SetContentAlignment(5)
	label:SetTextColor(color_white)

    local entry = vgui.Create("DNumberWang", panel)
    entry:SetValue(nDefault)
    entry:SetMinMax(nMin, nMax)
    entry.OnChange = function(slf)
        local val = tonumber(slf:GetValue())
        if not val then
            slf:SetText(nDefault)
            return
        end

        if val < nMin then
            slf:SetText(nMin)
        elseif val > nMax then
            slf:SetText(nMax)
        end
    end

	local btns = vgui.Create("DPanel", frame)
	btns:SetTall(30)
	btns:SetPaintBackground(false)

	local commit = vgui.Create("DButton", btns)
	commit:SetText(strCommitText or "OK")
	commit:SizeToContents()
	commit:SetTall(20)
	commit:SetWide(commit:GetWide() + 20)
	commit:SetPos(5, 5)
	commit.DoClick = function()
        frame:Close()
        fnEnter(tonumber(entry:GetValue()))
    end

	local cancel = vgui.Create("DButton", btns)
	cancel:SetText(strCancelText or "Cancel")
	cancel:SizeToContents()
	cancel:SetTall(20)
	cancel:SetWide(commit:GetWide() + 20)
	cancel:SetPos(5, 5)
	cancel:MoveRightOf(commit, 5)
	cancel.DoClick = function()
        frame:Close()
        if fnCancel then
            fnCancel(entry:GetValue())
        end
    end

	btns:SetWide(commit:GetWide() + 5 + cancel:GetWide() + 10)

	local w, h = label:GetSize()
	w = math.max(w, 150)

	frame:SetSize(w + 50, h + 25 + 75 + 10)
	frame:Center()

	panel:StretchToParent(5, 25, 5, 45)

	label:StretchToParent(5, 5, 5, 35)

	entry:StretchToParent(75, nil, 75, nil)
	entry:AlignBottom(5)

	entry:RequestFocus()
	entry:SelectAllText(true)

	btns:CenterHorizontal()
	btns:AlignBottom(8)

	frame:MakePopup()
	frame:DoModal()

	return frame
end