local addon, NS = ...
local C, db, panel = NS.Core
local active, status, clock, cachedDay = false, "Bereit", 0
local driver = CreateFrame("Frame")
local inCombat = false
local resize
local function day() return date("%Y-%m-%d") end
local function number(n)
    local s = tostring(math.floor(n))
    while true do
        local changed
        s, changed = s:gsub("^(%d+)(%d%d%d)", "%1.%2")
        if changed == 0 then return s end
    end
end
local function say(s) print("|cffffd27fAFT:|r " .. s) end
local function label(parent, font, x, y, text)
    local f = parent:CreateFontString(nil, "OVERLAY", font)
    f:SetPoint("TOPLEFT", x, y); f:SetText(text)
    parent.fitnessFonts = parent.fitnessFonts or {}
    parent.fitnessFonts[#parent.fitnessFonts+1] = f
    return f
end
local function savePosition()
    local point, _, relative, x, y = panel:GetPoint()
    db.position = {point=point, relative=relative, x=x, y=y}
end
local function stopInteraction()
    if not panel then return end
    panel:StopMovingOrSizing()
    resize = nil
    savePosition()
end
local function visibility()
    if not panel then return end
    if db.hidden or inCombat then panel:Hide() else panel:Show() end
end
local function toggleLock()
    stopInteraction()
    db.locked = not db.locked
    panel.grip:SetAlpha(db.locked and 0.25 or 1)
    panel.hint:SetText(db.locked and "Gesperrt · Rechtsklick zum Entsperren" or "Rechtsklick: sperren · Ecke: Größe")
    say(db.locked and "Fenster gesperrt." or "Fenster verschiebbar und skalierbar.")
end
local function applyScale(value)
    if db.locked or inCombat then return end
    -- Preserve the physical top-left corner while scaling the entire UI.
    local effective = panel:GetEffectiveScale()
    local left, top = panel:GetLeft()*effective, panel:GetTop()*effective
    db.scale = math.max(0.6, math.min(2,value))
    panel:SetScale(db.scale)
    effective = panel:GetEffectiveScale()
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left/effective,top/effective)
    savePosition()
end
local fonts = {
    {"WoW Standard", STANDARD_TEXT_FONT},
    {"Arial", "Fonts\\ARIALN.TTF"},
    {"Morpheus", "Fonts\\MORPHEUS.TTF"},
}
local borders = {"Gold", "Schlicht", "Ohne Rahmen"}
local function appearance()
    local style = db.borderStyle or 1
    local edge = style == 1 and "Interface\\DialogFrame\\UI-DialogBox-Border"
        or style == 2 and "Interface\\Tooltips\\UI-Tooltip-Border" or nil
    panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile=edge,
        tile=true,tileSize=32,edgeSize=style==1 and 24 or 12,insets={left=6,right=6,top=6,bottom=6}})
    panel:SetBackdropColor(0.06,0.045,0.025,0.96)
    panel:SetBackdropBorderColor(0.85,0.68,0.37)
    panel:SetAlpha(1-(db.transparency or 0)/100)
    local font = fonts[db.fontStyle or 1] or fonts[1]
    for _, text in ipairs(panel.fitnessFonts or {}) do
        local _, size, flags = text:GetFont()
        text:SetFont(font[2],size or 12,flags or "")
    end
    panel.total:SetShown(db.showTotal ~= false)
    panel.totalLabel:SetShown(db.showTotal ~= false)
end
local function layoutAchievements()
    stopInteraction()
    local effective=panel:GetEffectiveScale()
    local left,top=panel:GetLeft()*effective,panel:GetTop()*effective
    local collapsed=db.achCollapsed ~= false
    panel:SetHeight(collapsed and 282 or 402)
    for _, text in ipairs(panel.badges) do text:SetShown(not collapsed) end
    panel.achToggle:SetText(collapsed and "+" or "-")
    panel.hint:ClearAllPoints()
    panel.hint:SetPoint("BOTTOMLEFT",22,15)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left/effective,top/effective)
    savePosition()
end
local function buildSettings()
    local settings=CreateFrame("Frame",nil,panel,"BackdropTemplate")
    panel.settings=settings
    settings:SetSize(278,284); settings:SetPoint("TOP",panel,"TOP",0,-45)
    settings:SetFrameLevel(panel:GetFrameLevel()+20)
    settings:SetClampedToScreen(true); settings:EnableMouse(true)
    settings:SetIgnoreParentAlpha(true)
    settings:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,insets={left=6,right=6,top=6,bottom=6}})
    settings:SetBackdropColor(0.07,0.05,0.025,1)
    label(settings,"GameFontNormalLarge",18,-20,"Einstellungen")
    local close=CreateFrame("Button",nil,settings,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() settings:Hide() end)
    local opacityLabel=label(settings,"GameFontNormal",20,-55,"")
    local slider=CreateFrame("Slider",nil,settings,"BackdropTemplate")
    settings.opacity=slider
    slider:SetOrientation("HORIZONTAL"); slider:SetPoint("TOPLEFT",22,-80); slider:SetSize(234,16)
    slider:SetMinMaxValues(0,75); slider:SetValueStep(5); slider:SetObeyStepOnDrag(true)
    slider:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
    slider:SetBackdropColor(0.25,0.2,0.12,1)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    opacityLabel:SetText("Transparenz: "..(db.transparency or 0).." %")
    slider:SetValue(db.transparency or 0)
    slider:SetScript("OnValueChanged",function(_,value)
        db.transparency=math.floor(value+0.5)
        opacityLabel:SetText("Transparenz: "..db.transparency.." %")
        appearance()
    end)
    local function button(y)
        local b=CreateFrame("Button",nil,settings,"UIPanelButtonTemplate")
        b:SetPoint("TOPLEFT",20,y); b:SetSize(238,28)
        return b
    end
    local fontButton=button(-117); settings.fontButton=fontButton
    fontButton:SetText("Schrift: "..fonts[db.fontStyle or 1][1])
    fontButton:SetScript("OnClick",function(self)
        db.fontStyle=(db.fontStyle or 1)%#fonts+1
        self:SetText("Schrift: "..fonts[db.fontStyle][1]); appearance()
    end)
    local borderButton=button(-153); settings.borderButton=borderButton
    borderButton:SetText("Rahmen: "..borders[db.borderStyle or 1])
    borderButton:SetScript("OnClick",function(self)
        db.borderStyle=(db.borderStyle or 1)%#borders+1
        self:SetText("Rahmen: "..borders[db.borderStyle]); appearance()
    end)
    local totalButton=button(-189); settings.totalButton=totalButton
    local function totalText() totalButton:SetText("Gesamtschritte: "..(db.showTotal ~= false and "An" or "Aus")) end
    totalText()
    totalButton:SetScript("OnClick",function()
        db.showTotal=db.showTotal == false
        totalText(); appearance()
    end)
    label(settings,"GameFontDisableSmall",20,-237,"Schrift und Rahmen per Klick wechseln.")
    label(settings,"GameFontDisableSmall",20,-253,"Änderungen werden sofort gespeichert.")
    settings:Hide()
end
local function refresh()
    if not panel then return end
    panel.today:SetText(number(db.today))
    panel.total:SetText(number(db.total))
    panel.progress:SetValue(math.min(db.today / db.goal, 1))
    panel.goal:SetText("Tagesziel  " .. number(db.goal) .. "  ·  " .. math.floor(db.today / db.goal * 100) .. "%")
    panel.status:SetText(status)
    panel.twr:SetText(C.FormatTime(db.runSeconds))
    if panel.badges then
        for i, milestone in ipairs(C.Milestones) do
            local earned = db.achievements[milestone[1]]
            panel.badges[i]:SetText((earned and "|cffffd27f+ " or "|cff888888- ") .. milestone[2] .. "  (" .. milestone[1] .. ")|r")
        end
        panel.achTitle:SetText("ERFOLGE  ·  " .. db.goalDays .. " Tagesziele")
    end
end
local function celebrate()
    local completed, unlocked = C.Complete(db)
    if not completed then return end
    say("Tagesziel geschafft! Deine Stiefel bitten um bezahlten Urlaub.")
    for _, title in ipairs(unlocked) do
        say("Erfolg freigeschaltet: " .. title)
        if UIErrorsFrame then UIErrorsFrame:AddMessage("AFT: " .. title, 1, 0.82, 0.3, 1) end
    end
    if db.guildMessages ~= false and IsInGuild and IsInGuild() then
        local jokes = {
            "Tagesziel geschafft: %s Schritte! Mein Mount hat jetzt Verlustängste.",
            "%s Schritte heute! Ich tanke jetzt nur noch Wasser. Und vielleicht einen Raid.",
            "%s Schritte! Meine Stiefel sind episch, der Muskelkater ist legendär.",
            "Tagesziel: %s Schritte! Habe Ausdauer geskillt. Mein Sofa ist jetzt mein Erzfeind.",
        }
        local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
        if send then
            local ok = pcall(send, "AFT: " .. string.format(jokes[math.random(#jokes)], number(db.today)), "GUILD")
            if not ok then say("Gildennachricht vom Client blockiert; kein erneuter Sendeversuch.") end
        else say("Gildenchat-API nicht verfügbar.") end
    end
end
local function buildUI()
    panel = CreateFrame("Frame", "ForeverStepsFrame", UIParent, "BackdropTemplate")
    panel:SetSize(300, 402)
    panel:SetClampedToScreen(true); panel:SetMovable(true); panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=24, insets={left=6,right=6,top=6,bottom=6}})
    panel:SetBackdropColor(0.06, 0.045, 0.025, 0.96)
    panel:SetBackdropBorderColor(0.85, 0.68, 0.37)
    panel:SetScale(db.scale or 1)
    if db.position then
        panel:SetPoint(db.position.point, UIParent, db.position.relative, db.position.x, db.position.y)
    else panel:SetPoint("CENTER", UIParent, "CENTER", 320, 0) end
    panel:SetScript("OnDragStart", function(self) if not db.locked and not inCombat then resize=nil; self:StartMoving() end end)
    panel:SetScript("OnDragStop", stopInteraction)
    panel:SetScript("OnHide", function() stopInteraction(); if panel.settings then panel.settings:Hide() end end)
    panel:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then toggleLock() end
    end)
    local icon = panel:CreateTexture(nil, "ARTWORK")
    icon:SetSize(30,30); icon:SetPoint("TOPLEFT", 18,-17)
    icon:SetTexture("Interface\\Icons\\Ability_Rogue_Sprint")
    label(panel, "GameFontNormalLarge", 58,-18,"AZEROTH")
    label(panel, "GameFontDisableSmall", 59,-38,"FITNESS TRACKER")
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4,-4)
    close:SetScript("OnClick", function() db.hidden=true; visibility() end)
    label(panel, "GameFontNormal", 22,-66,"HEUTE")
    panel.today = label(panel, "GameFontHighlightHuge", 22,-85,"0")
    panel.today:SetFont(STANDARD_TEXT_FONT, 32, "OUTLINE")
    panel.totalLabel = label(panel, "GameFontDisableSmall", 178,-72,"GESAMT")
    panel.total = label(panel, "GameFontHighlightLarge", 178,-94,"0")
    panel.total:SetWidth(100); panel.total:SetJustifyH("LEFT")
    panel.progress = CreateFrame("StatusBar", nil, panel)
    panel.progress:SetPoint("TOPLEFT",22,-137); panel.progress:SetSize(256,12)
    panel.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    panel.progress:SetStatusBarColor(0.85,0.64,0.24); panel.progress:SetMinMaxValues(0,1)
    local bg = panel.progress:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0.18,0.14,0.08,1)
    panel.goal = label(panel,"GameFontNormalSmall",22,-158,"")
    panel.status = label(panel,"GameFontHighlightSmall",22,-181,"")
    label(panel,"GameFontNormalSmall",22,-207,"TWR · Gesamtlaufzeit")
    panel.twr = label(panel,"GameFontHighlightSmall",158,-207,"00:00:00")
    panel.twr:SetWidth(120); panel.twr:SetJustifyH("RIGHT")
    local twrInfo=CreateFrame("Frame",nil,panel)
    twrInfo:SetPoint("TOPLEFT",20,-201); twrInfo:SetSize(260,24); twrInfo:EnableMouse(true)
    twrInfo:RegisterForDrag("LeftButton")
    twrInfo:SetScript("OnDragStart",function()
        if not db.locked and not inCombat then resize=nil; panel:StartMoving() end
    end)
    twrInfo:SetScript("OnDragStop",stopInteraction)
    twrInfo:SetScript("OnMouseUp",function(_,button) if button=="RightButton" then toggleLock() end end)
    twrInfo:SetScript("OnEnter",function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_TOP")
            GameTooltip:SetText("Time wasted Running (TWR)")
            GameTooltip:AddLine("Gesamtlaufzeit seit Version 1.4.0. Je Wegstück: Strecke / aktuelle Geschwindigkeit.",1,1,1,true)
            GameTooltip:AddLine("Nur gemessene Bewegung zu Fuß; keine Standzeit. Format: Tage + Stunden:Minuten:Sekunden.",1,1,1,true)
            GameTooltip:Show()
        end
    end)
    twrInfo:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    twrInfo:SetScript("OnHide",function() if GameTooltip then GameTooltip:Hide() end end)
    panel.achTitle = label(panel,"GameFontNormal",44,-238,"ERFOLGE")
    panel.achToggle=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    panel.achToggle:SetSize(20,20); panel.achToggle:SetPoint("TOPLEFT",20,-233)
    panel.achToggle:SetScript("OnClick",function()
        db.achCollapsed=db.achCollapsed == false
        layoutAchievements()
    end)
    panel.badges = {}
    for i in ipairs(C.Milestones) do
        panel.badges[i] = label(panel,"GameFontHighlightSmall",22,-242-i*18,"")
    end
    panel.hint = label(panel,"GameFontDisableSmall",22,-378,"")
    panel.hint:SetText(db.locked and "Gesperrt · Rechtsklick zum Entsperren" or "Rechtsklick: sperren · Ecke: Größe")
    local grip = CreateFrame("Button", nil, panel)
    panel.grip = grip
    grip:SetSize(22,22); grip:SetPoint("BOTTOMRIGHT",-5,5)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetAlpha(db.locked and 0.25 or 1)
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or db.locked or inCombat then return end
        stopInteraction()
        local x,y = GetCursorPosition()
        local effective = panel:GetEffectiveScale()
        resize = {x=x,y=y,scale=db.scale or 1,w=panel:GetWidth()*effective,h=panel:GetHeight()*effective}
    end)
    grip:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then toggleLock() else stopInteraction() end
    end)
    grip:SetScript("OnUpdate", function()
        if not resize then return end
        if db.locked or inCombat or not IsMouseButtonDown("LeftButton") then stopInteraction(); return end
        local x,y = GetCursorPosition()
        local r = resize
        local ratio = 1 + ((x-r.x)*r.w - (y-r.y)*r.h)/(r.w*r.w+r.h*r.h)
        applyScale(r.scale * ratio)
    end)
    buildSettings()
    local gear=CreateFrame("Button",nil,panel)
    panel.gear=gear
    gear:SetSize(22,22); gear:SetPoint("TOPRIGHT",-35,-8)
    gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    gear:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    gear:SetScript("OnEnter",function(self)
        if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText("Azeroth Fitness Tracker – Einstellungen"); GameTooltip:Show() end
    end)
    gear:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    gear:SetScript("OnClick",function()
        stopInteraction()
        panel.settings:SetShown(not panel.settings:IsShown())
    end)
    layoutAchievements()
    appearance()
    visibility()
    refresh()
end
local function sample()
    if db.paused then return 0,false,"Pausiert" end
    -- Secret values must never be compared or used in arithmetic.
    local function flag(fn, ...)
        if not fn then return false end
        local value = fn(...)
        if issecretvalue and issecretvalue(value) then error("restricted") end
        return value
    end
    if flag(UnitIsDeadOrGhost,"player") then return 0,false,"Tot / Geist" end
    if flag(IsMounted) or flag(UnitOnTaxi,"player") or flag(UnitInVehicle,"player") then return 0,false,"Unterwegs ohne Schritte" end
    if flag(IsFlying) or flag(IsSwimming) or flag(IsFalling) then return 0,false,"Keine Bodenschritte" end
    local speed = GetUnitSpeed("player")
    if issecretvalue and issecretvalue(speed) then return 0,false,"Messung durch Client gesperrt" end
    if type(speed) ~= "number" then return 0,false,"Bewegungsdaten fehlen" end
    return speed,true,speed > 0 and "Zu Fuß unterwegs" or "Bereit für dein Abenteuer"
end
driver:SetScript("OnUpdate", function(_, elapsed)
    if not db or not active then return end
    clock = clock + elapsed
    if clock >= 0.25 then cachedDay = day() end
    local ok, speed, eligible, state = pcall(sample)
    if not ok then speed,eligible,state = 0,false,"Messung nicht verfügbar" end
    status = state
    local reached = C.Add(db,cachedDay,speed,elapsed,eligible)
    if reached then celebrate() end
    if clock >= 0.25 then clock=0; refresh() end
end)
driver:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addon then
        cachedDay=day(); db=C.New(ForeverStepsDB,cachedDay); ForeverStepsDB=db
        inCombat = InCombatLockdown and InCombatLockdown() or false
        buildUI()
    elseif event == "PLAYER_ENTERING_WORLD" then
        active=true; cachedDay=day(); clock=0
        inCombat = InCombatLockdown and InCombatLockdown() or false
        visibility()
    elseif event == "PLAYER_REGEN_DISABLED" then inCombat=true; visibility()
    elseif event == "PLAYER_REGEN_ENABLED" then inCombat=false; visibility()
    elseif event == "PLAYER_LEAVING_WORLD" then active=false; stopInteraction() end
end)
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_LEAVING_WORLD")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
SLASH_FOREVERSTEPS1="/schritte"
SLASH_FOREVERSTEPS2="/fsteps"
SLASH_FOREVERSTEPS3="/fitness"
SlashCmdList.FOREVERSTEPS=function(input)
    if not db then return end
    local cmd,arg = input:lower():match("^%s*(%S*)%s*(.-)%s*$")
    local n=tonumber((arg:gsub(",",".")))
    if cmd=="" or cmd=="zeigen" then db.hidden=false; visibility()
    elseif cmd=="ausblenden" then db.hidden=true; visibility()
    elseif cmd=="sperren" then toggleLock()
    elseif cmd=="pause" then db.paused=not db.paused; say(db.paused and "Zähler pausiert." or "Zähler aktiv.")
    elseif cmd=="ziel" and n and n>=1 and n<=1000000 then db.goal=math.floor(n)
    elseif cmd=="schrittlaenge" and n and n>=0.5 and n<=5 then db.stride=n; say("Schrittlänge: "..n.." Yards. Gilt für neue Schritte.")
    elseif cmd=="groesse" and n and n>=0.6 and n<=2 then applyScale(n)
    elseif cmd=="gilde" then
        db.guildMessages = db.guildMessages == false
        say(db.guildMessages and "Gildennachrichten an." or "Gildennachrichten aus.")
    elseif cmd=="erfolge" then
        say(db.goalDays .. " Tagesziele erreicht (nicht zwingend in Folge).")
        for _, m in ipairs(C.Milestones) do say((db.achievements[m[1]] and "[Geschafft] " or "[Offen] ") .. m[2] .. " - " .. m[1] .. " Tage") end
    elseif cmd=="position" then
        if not db.locked and not inCombat then stopInteraction(); db.position=nil; panel:ClearAllPoints(); panel:SetPoint("CENTER") end
    else say("/schritte [zeigen | ausblenden | sperren | pause | position | gilde | erfolge]"); say("/schritte ziel 10000 · groesse 1 · schrittlaenge 2,5 (Yards)") end
    refresh()
end

-- Open the existing settings panel, including when the tracker was hidden.
SLASH_AZEROTHFITNESSTRACKER1="/aft"
SlashCmdList.AZEROTHFITNESSTRACKER=function()
    if not db or not panel then return end
    if inCombat then say("Die Einstellungen sind nach dem Kampf verfügbar."); return end
    stopInteraction()
    db.hidden=false
    visibility()
    panel.settings:Show()
end
