local addon, NS = ...
local L = NS.L
local C, db, panel = NS.Core
local active, status, clock, cachedDay = false, L.READY, 0
local driver = CreateFrame("Frame")
local inCombat = false
local resize
local refresh
local lastSpell
local recentFood,foodOrder={},{}
local knownRace,knownRaceName="Unknown","Unknown"
local function race()
    if UnitRace then
        local ok,name,key=pcall(UnitRace,"player")
        if ok and not (issecretvalue and (issecretvalue(name) or issecretvalue(key))) then
            if type(key)=="string" then knownRace=key end
            if type(name)=="string" then knownRaceName=name end
        end
    end
    return knownRace,knownRaceName
end
local function day() return date("%Y-%m-%d") end
local function number(n)
    local s = tostring(math.floor(n))
    while true do
        local changed
        s, changed = s:gsub("^(%d+)(%d%d%d)", "%1" .. NS.groupSeparator .. "%2")
        if changed == 0 then return s end
    end
end
local function say(s) print("|cffffd27fAFT:|r " .. s) end
local function fitText(f)
    local path,size,flags=f:GetFont()
    if not path then return end
    f.aftBaseSize=f.aftBaseSize or size
    size=f.aftBaseSize
    f:SetFont(path,size,flags or "")
    local width=f:GetUnboundedStringWidth()
    if width and width>f.aftMaxWidth then
        f:SetFont(path,math.max(8,size*f.aftMaxWidth/width),flags or "")
    end
end
local function fitLabels(parent)
    for _, f in ipairs(parent.fitnessFonts or {}) do fitText(f) end
end
local function label(parent, font, x, y, text)
    local f = parent:CreateFontString(nil, "OVERLAY", font)
    f:SetPoint("TOPLEFT", x, y); f:SetText(text)
    f.aftMaxWidth=parent:GetWidth()-x-22
    f:SetWidth(f.aftMaxWidth); f:SetWordWrap(false)
    f:SetJustifyH("LEFT")
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
    panel.hint:SetText(db.locked and L.LOCK_HINT or L.UNLOCK_HINT)
    fitText(panel.hint)
    say(db.locked and L.LOCKED or L.UNLOCKED)
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
    {L.DEFAULT_FONT, STANDARD_TEXT_FONT},
    {"Arial", "Fonts\\ARIALN.TTF"},
    {"Morpheus", "Fonts\\MORPHEUS.TTF"},
}
if NS.nativeFontOnly then fonts = {{L.DEFAULT_FONT, STANDARD_TEXT_FONT}} end
local borders = {L.GOLD, L.PLAIN, L.NO_BORDER}
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
        text:SetFont(font[2],text.aftBaseSize or size or 12,flags or "")
    end
    panel.total:SetShown(db.showTotal ~= false)
    panel.totalLabel:SetShown(db.showTotal ~= false)
    panel.twr:SetShown(db.showTWR~=false);panel.twrLabel:SetShown(db.showTWR~=false);panel.twrInfo:SetShown(db.showTWR~=false)
    fitLabels(panel)
end
local function layoutAchievements()
    stopInteraction()
    local effective=panel:GetEffectiveScale()
    local left,top=panel:GetLeft()*effective,panel:GetTop()*effective
    local collapsed=db.achCollapsed ~= false
    local header=270+(db.showCalories~=false and 72 or 0)
    panel:SetHeight(header+(collapsed and 44 or 164))
    panel.achTitle:ClearAllPoints();panel.achTitle:SetPoint("TOPLEFT",44,-header)
    panel.achToggle:ClearAllPoints();panel.achToggle:SetPoint("TOPLEFT",20,-header+5)
    for i,t in ipairs(panel.badges) do t:ClearAllPoints();t:SetPoint("TOPLEFT",22,-header-4-i*18) end
    panel.calTitle:SetShown(db.showCalories~=false);panel.calBar:SetShown(db.showCalories~=false);panel.calSummary:SetShown(db.showCalories~=false)

    for _, text in ipairs(panel.badges) do text:SetShown(not collapsed) end
    panel.achToggle:SetText(collapsed and "+" or "-")
    panel.hint:ClearAllPoints()
    panel.hint:SetPoint("BOTTOMLEFT",22,15)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left/effective,top/effective)
    savePosition()
end
local function buildSettings()
    panel.settings=NS.CreateSettings(panel,db,{
        fonts=fonts,borders=borders,number=number,day=day,race=race,lastSpell=function()return lastSpell end,
        appearance=appearance,layout=layoutAchievements,lock=toggleLock,scale=applyScale,
        refresh=function()refresh() end,
        center=function()if not db.locked and not inCombat then stopInteraction();db.position=nil;panel:ClearAllPoints();panel:SetPoint("CENTER") end end,
    })
end
refresh=function()
    if not panel then return end
    panel.today:SetText(number(db.today))
    panel.total:SetText(number(db.total))
    local fraction,r,g,b,nextValue=C.Stage(db)
    panel.progress:SetValue(fraction);panel.progress:SetStatusBarColor(r,g,b)
    panel.stage:SetText(nextValue and (L.STAGE_NEXT..number(nextValue)) or L.STAGE_DONE)
    local left,need,eaten=C.Calories(db,race())
    panel.calTitle:SetText(L.CAL_LEFT..": "..number(left).." kcal")
    panel.calBar:SetValue(need>0 and left/need or 0)
    panel.calSummary:SetText(L.CAL_SUMMARY..number(need).." / "..number(eaten).." kcal")
    panel.goal:SetText(L.DAILY_GOAL .. number(db.goal) .. "  ·  " .. math.floor(db.today / db.goal * 100) .. "%")
    panel.status:SetText(status)
    panel.twr:SetText(C.FormatTime(db.runSeconds))
    if panel.settings and panel.settings.UpdateLive then panel.settings.UpdateLive() end
    if panel.badges then
        for i, milestone in ipairs(C.Milestones) do
            local earned = db.achievements[milestone[1]]
            panel.badges[i]:SetText((earned and "|cffffd27f+ " or "|cff888888- ") .. milestone[2] .. "  (" .. milestone[1] .. ")|r")
        end
        panel.achTitle:SetText(L.ACH_HEADER .. db.goalDays .. L.GOALS_SUFFIX)
    end
    fitLabels(panel)
end
local function celebrate()
    local completed, unlocked = C.Complete(db)
    if not completed then return end
    say(L.GOAL_DONE)
    for _, title in ipairs(unlocked) do
        say(L.ACH_UNLOCKED .. title)
        if UIErrorsFrame then UIErrorsFrame:AddMessage("AFT: " .. title, 1, 0.82, 0.3, 1) end
    end
    if db.guildMessages ~= false and IsInGuild and IsInGuild() then
        local jokes = C.Messages(db)
        local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
        if send then
            local ok = pcall(send, C.RenderMessage(db,jokes[math.random(#jokes)],number), "GUILD")
            if not ok then say(L.CHAT_BLOCKED) end
        else say(L.CHAT_MISSING) end
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
    local title = label(panel, "GameFontNormalLarge", 58,-18,"AZEROTH")
    title.aftMaxWidth=175; title:SetWidth(175)
    label(panel, "GameFontDisableSmall", 59,-38,"FITNESS TRACKER")
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4,-4)
    close:SetScript("OnClick", function() db.hidden=true; visibility() end)
    label(panel, "GameFontNormal", 22,-66,L.TODAY)
    panel.today = label(panel, "GameFontHighlightHuge", 22,-85,"0")
    panel.today:SetFont(STANDARD_TEXT_FONT, 32, "OUTLINE")
    panel.today.aftMaxWidth=146; panel.today:SetWidth(146)
    panel.totalLabel = label(panel, "GameFontDisableSmall", 178,-72,L.TOTAL)
    panel.total = label(panel, "GameFontHighlightLarge", 178,-94,"0")
    panel.total.aftMaxWidth=100; panel.total:SetWidth(100); panel.total:SetJustifyH("LEFT")
    panel.progress = CreateFrame("StatusBar", nil, panel)
    panel.progress:SetPoint("TOPLEFT",22,-137); panel.progress:SetSize(256,12)
    panel.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    panel.progress:SetStatusBarColor(0.85,0.64,0.24); panel.progress:SetMinMaxValues(0,1)
    local bg = panel.progress:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0.18,0.14,0.08,1)
    panel.goal = label(panel,"GameFontNormalSmall",22,-158,"")
    panel.stage = label(panel,"GameFontNormalSmall",22,-177,"")
    panel.status = label(panel,"GameFontHighlightSmall",22,-198,"")
    local twrLabel=label(panel,"GameFontNormalSmall",22,-223,L.TWR_LABEL)
    panel.twrLabel=twrLabel
    twrLabel.aftMaxWidth=132; twrLabel:SetWidth(132)
    panel.twr = label(panel,"GameFontHighlightSmall",158,-223,"00:00:00")
    panel.twr.aftMaxWidth=120; panel.twr:SetWidth(120); panel.twr:SetJustifyH("RIGHT")
    local twrInfo=CreateFrame("Frame",nil,panel)
    panel.twrInfo=twrInfo
    twrInfo:SetPoint("TOPLEFT",20,-217); twrInfo:SetSize(260,24); twrInfo:EnableMouse(true)
    twrInfo:RegisterForDrag("LeftButton")
    twrInfo:SetScript("OnDragStart",function()
        if not db.locked and not inCombat then resize=nil; panel:StartMoving() end
    end)
    twrInfo:SetScript("OnDragStop",stopInteraction)
    twrInfo:SetScript("OnMouseUp",function(_,button) if button=="RightButton" then toggleLock() end end)
    twrInfo:SetScript("OnEnter",function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_TOP")
            GameTooltip:SetText(L.TWR_TITLE)
            GameTooltip:AddLine(L.TWR_DESC,1,1,1,true)
            GameTooltip:AddLine(L.TWR_FORMAT,1,1,1,true)
            GameTooltip:Show()
        end
    end)
    twrInfo:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    twrInfo:SetScript("OnHide",function() if GameTooltip then GameTooltip:Hide() end end)
    panel.calTitle=label(panel,"GameFontNormalSmall",22,-250,"")
    panel.calBar=CreateFrame("StatusBar",nil,panel)
    panel.calBar:SetPoint("TOPLEFT",22,-272);panel.calBar:SetSize(256,12)
    panel.calBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    panel.calBar:SetStatusBarColor(0.8,0.35,0.65);panel.calBar:SetMinMaxValues(0,1)
    local calBG=panel.calBar:CreateTexture(nil,"BACKGROUND");calBG:SetAllPoints();calBG:SetColorTexture(0.18,0.12,0.15,1)
    panel.calSummary=label(panel,"GameFontDisableSmall",22,-294,"")
    panel.achTitle = label(panel,"GameFontNormal",44,-238,L.ACHIEVEMENTS)
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
    panel.hint:SetText(db.locked and L.LOCK_HINT or L.UNLOCK_HINT)
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
        if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(L.SETTINGS_TITLE); GameTooltip:Show() end
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
    if db.paused then return 0,false,L.PAUSED end
    -- Secret values must never be compared or used in arithmetic.
    local function flag(fn, ...)
        if not fn then return false end
        local value = fn(...)
        if issecretvalue and issecretvalue(value) then error("restricted") end
        return value
    end
    if flag(UnitIsDeadOrGhost,"player") then return 0,false,L.DEAD end
    if flag(IsMounted) or flag(UnitOnTaxi,"player") or flag(UnitInVehicle,"player") then return 0,false,L.NO_STEPS end
    if flag(IsFlying) or flag(IsSwimming) or flag(IsFalling) then return 0,false,L.NOT_GROUND end
    local speed = GetUnitSpeed("player")
    if issecretvalue and issecretvalue(speed) then return 0,false,L.RESTRICTED end
    if type(speed) ~= "number" then return 0,false,L.NO_DATA end
    return speed,true,speed > 0 and L.WALKING or L.IDLE
end
driver:SetScript("OnUpdate", function(_, elapsed)
    if not db or not active then return end
    clock = clock + elapsed
    if clock >= 0.25 then cachedDay = day() end
    local ok, speed, eligible, state = pcall(sample)
    if not ok then speed,eligible,state = 0,false,L.UNAVAILABLE end
    status = state
    local reached,custom = C.Add(db,cachedDay,speed,elapsed,eligible)
    for _,name in ipairs(custom or {}) do say(L.CUSTOM_DONE..name) end
    if reached then celebrate() end
    if clock >= 0.25 then clock=0; refresh() end
end)
driver:SetScript("OnEvent", function(_, event, name, castGUID, spellID)
    if event == "ADDON_LOADED" and name == addon then
        cachedDay=day(); db=C.New(ForeverStepsDB,cachedDay); ForeverStepsDB=db
        inCombat = InCombatLockdown and InCombatLockdown() or false
        buildUI()
    elseif event == "PLAYER_ENTERING_WORLD" then
        active=true; cachedDay=day(); clock=0
        inCombat = InCombatLockdown and InCombatLockdown() or false
        visibility()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not db or not active or db.autoFood==false then return end
        if issecretvalue and (issecretvalue(name) or issecretvalue(spellID) or issecretvalue(castGUID)) then return end
        if name~="player" or type(spellID)~="number" then return end
        lastSpell=spellID
        local ok,kcal=pcall(C.FoodCalories,db,spellID)
        if not ok or not kcal or kcal<=0 then return end
        local key=castGUID
        if not key then key=tostring(spellID)..":"..math.floor(GetTime()) end
        if recentFood[key] or db.lastFoodGUID==key then return end
        recentFood[key]=true;foodOrder[#foodOrder+1]=key
        if #foodOrder>64 then recentFood[table.remove(foodOrder,1)]=nil end
        db.lastFoodGUID=key
        C.Day(db,day());C.Meal(db,kcal);refresh()
    elseif event == "PLAYER_REGEN_DISABLED" then inCombat=true; visibility()
    elseif event == "PLAYER_REGEN_ENABLED" then inCombat=false; visibility()
    elseif event == "PLAYER_LEAVING_WORLD" then active=false; stopInteraction() end
end)
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_LEAVING_WORLD")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player")
SLASH_FOREVERSTEPS1="/schritte"
SLASH_FOREVERSTEPS2="/fsteps"
SLASH_FOREVERSTEPS3="/fitness"
SlashCmdList.FOREVERSTEPS=function(input)
    if not db then return end
    local cmd,arg = input:lower():match("^%s*(%S*)%s*(.-)%s*$")
    local aliases={show="zeigen",hide="ausblenden",lock="sperren",goal="ziel",stride="schrittlaenge",size="groesse",guild="gilde",achievements="erfolge",help="hilfe"}
    cmd=aliases[cmd] or cmd
    local n=tonumber((arg:gsub(",",".")))
    if cmd=="" or cmd=="zeigen" then db.hidden=false; visibility()
    elseif cmd=="ausblenden" then db.hidden=true; visibility()
    elseif cmd=="sperren" then toggleLock()
    elseif cmd=="pause" then db.paused=not db.paused; say(db.paused and L.COUNTER_PAUSED or L.COUNTER_ACTIVE)
    elseif cmd=="ziel" and n and n>=1 and n<=1000000 then db.goal=math.floor(n)
    elseif cmd=="schrittlaenge" and n and n>=0.5 and n<=5 then db.stride=n; say(L.STRIDE..n..L.STRIDE_SUFFIX)
    elseif cmd=="groesse" and n and n>=0.6 and n<=2 then applyScale(n)
    elseif cmd=="gilde" then
        db.guildMessages = db.guildMessages == false
        say(db.guildMessages and L.GUILD_ON or L.GUILD_OFF)
    elseif cmd=="erfolge" then
        say(db.goalDays .. L.GOALS_DONE)
        for _, m in ipairs(C.Milestones) do say((db.achievements[m[1]] and L.EARNED or L.PENDING) .. m[2] .. " - " .. m[1] .. L.DAYS) end
    elseif cmd=="position" then
        if not db.locked and not inCombat then stopInteraction(); db.position=nil; panel:ClearAllPoints(); panel:SetPoint("CENTER") end
    else say(L.HELP1); say(L.HELP2) end
    refresh()
end

-- Open the existing settings panel, including when the tracker was hidden.
SLASH_AZEROTHFITNESSTRACKER1="/aft"
SlashCmdList.AZEROTHFITNESSTRACKER=function()
    if not db or not panel then return end
    if inCombat then say(L.COMBAT_SETTINGS); return end
    stopInteraction()
    db.hidden=false
    visibility()
    panel.settings:Show()
end
