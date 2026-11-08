local _, NS = ...
local C,L=NS.Core,NS.L
function NS.CreateSettings(parent,db,api)
    local f=CreateFrame("Frame","AFTSettingsFrame",UIParent,"BackdropTemplate")
    f:SetSize(620,620); f:SetPoint("CENTER"); f:SetClampedToScreen(true)
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    if w and h then f:SetScale(math.min(1,w/640,h/640)) end
    f:SetFrameStrata("DIALOG"); f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self)self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)self:StopMovingOrSizing() end)
    f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,insets={left=6,right=6,top=6,bottom=6}})
    f:SetBackdropColor(0.05,0.04,0.025,1)
    local function text(p,x,y,width,value,font)
        local t=p:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
        t:SetPoint("TOPLEFT",x,y); t:SetWidth(width); t:SetJustifyH("LEFT"); t:SetText(value)
        return t
    end
    text(f,22,-20,550,"Azeroth Fitness Tracker — "..L.SETTINGS,"GameFontNormalLarge")
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-5,-5)
    close:SetScript("OnClick",function()f:Hide() end)
    local note=text(f,24,-584,570,"")
    local function feedback(ok) note:SetText(ok and L.SAVED or L.INVALID); api.refresh() end
    local function button(p,x,y,width,value,fn)
        local b=CreateFrame("Button",nil,p,"UIPanelButtonTemplate")
        b:SetPoint("TOPLEFT",x,y); b:SetSize(width,26); b:SetText(value); b:SetScript("OnClick",fn)
        return b
    end
    local function edit(p,x,y,width,height,multi)
        local e
        if multi then
            local sf=CreateFrame("ScrollFrame",nil,p,"UIPanelScrollFrameTemplate")
            sf:SetPoint("TOPLEFT",x,y); sf:SetSize(width-26,height)
            e=CreateFrame("EditBox",nil,sf)
            e:SetMultiLine(true); e:SetSize(width-32,height); e:SetFontObject("ChatFontNormal")
            sf:SetScrollChild(e)
        else
            e=CreateFrame("EditBox",nil,p,"InputBoxTemplate")
            e:SetPoint("TOPLEFT",x,y); e:SetSize(width,height)
        end
        e:SetAutoFocus(false); e:SetMaxLetters(multi and 4000 or 120)
        e:SetScript("OnEscapePressed",function(self)self:ClearFocus() end)
        if not multi then e:SetScript("OnEnterPressed",function(self)self:ClearFocus() end) end
        return e
    end
    local function numeric(p,x,y,width,title)
        text(p,x,y,width,title,"GameFontNormalSmall")
        return edit(p,x+5,y-24,width-10,24,false)
    end
    local function value(e) return tonumber((e:GetText():gsub(",","."))) end
    f.pages={}; f.tabs={}
    for i,title in ipairs({L.GENERAL,L.GOALS,L.MESSAGES,L.CALORIES}) do
        local p=CreateFrame("Frame",nil,f); p:SetPoint("TOPLEFT",20,-92); p:SetSize(580,482); p:Hide(); f.pages[i]=p
        f.tabs[i]=button(f,22+(i-1)*144,-53,140,title,function() f:ShowPage(i) end)
    end
    function f:ShowPage(index)
        note:SetText("")
        for i,p in ipairs(self.pages) do
            if i==index then p:Show(); if p.sync then p.sync() end else p:Hide() end
        end
        self.page=index
    end
    -- General controls, including every existing tracker setting.
    local p=f.pages[1]
    local toggles={}
    local function toggle(y,title,get,set)
        local b
        local function sync()b:SetText((get() and "[+] " or "[-] ")..title) end
        b=button(p,294,y,280,"",function()set(not get());sync();api.refresh() end)
        toggles[#toggles+1]=sync; return b
    end
    f.totalButton=toggle(0,L.TOTAL_OPTION,function()return db.showTotal~=false end,function(v)db.showTotal=v;api.appearance() end)
    toggle(-32,L.SHOW_TWR,function()return db.showTWR~=false end,function(v)db.showTWR=v;api.appearance() end)
    toggle(-64,L.SHOW_CAL,function()return db.showCalories~=false end,function(v)db.showCalories=v;api.layout() end)
    toggle(-96,L.GUILD_TOGGLE,function()return db.guildMessages~=false end,function(v)db.guildMessages=v end)
    toggle(-128,L.PAUSE_TOGGLE,function()return db.paused end,function(v)db.paused=v end)
    toggle(-160,L.LOCK_TOGGLE,function()return db.locked end,function()api.lock() end)
    toggle(-192,L.COLLAPSE,function()return db.achCollapsed~=false end,function(v)db.achCollapsed=v;api.layout() end)
    local goal=numeric(p,0,0,270,L.DAILY_GOAL.."(1–1,000,000)")
    local stride=numeric(p,0,-65,270,L.STRIDE.."(0.5–5)")
    local scale=numeric(p,0,-130,270,L.SCALE)
    f.goalInput=goal; f.strideInput=stride; f.scaleInput=scale
    f.saveGeneral=button(p,0,-192,270,L.SAVE,function()
        local a,b,c=value(goal),value(stride),value(scale)
        if not a or a<1 or a>1000000 or not b or b<0.5 or b>5 or not c or c<0.6 or c>2 then feedback(false);return end
        if db.locked and c~=(db.scale or 1) then feedback(false);return end
        db.goal=math.floor(a);db.stride=b;api.scale(c);feedback(true)
    end)
    local opacityLabel=text(p,0,-242,270,"")
    f.opacity=CreateFrame("Slider",nil,p,"BackdropTemplate")
    f.opacity:SetPoint("TOPLEFT",5,-271);f.opacity:SetSize(260,18);f.opacity:SetOrientation("HORIZONTAL")
    f.opacity:SetMinMaxValues(0,75);f.opacity:SetValueStep(5);f.opacity:SetObeyStepOnDrag(true)
    f.opacity:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});f.opacity:SetBackdropColor(0.2,0.15,0.08,1)
    f.opacity:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    f.opacity:SetScript("OnValueChanged",function(_,v)db.transparency=math.floor(v+0.5);opacityLabel:SetText(L.TRANSPARENCY..db.transparency.." %");api.appearance() end)
    f.fontButton=button(p,0,-315,270,"",function(self)
        db.fontStyle=(db.fontStyle or 1)%#api.fonts+1;self:SetText(L.FONT..api.fonts[db.fontStyle][1]);api.appearance()
    end)
    f.borderButton=button(p,0,-349,270,"",function(self)
        db.borderStyle=(db.borderStyle or 1)%#api.borders+1;self:SetText(L.BORDER..api.borders[db.borderStyle]);api.appearance()
    end)
    button(p,294,-242,280,L.POSITION_RESET,function()api.center() end)
    text(p,0,-410,570,L.SAVED_HINT,"GameFontDisableSmall")
    p.sync=function()
        goal:SetText(tostring(db.goal));stride:SetText(tostring(db.stride));scale:SetText(tostring(db.scale or 1))
        f.opacity:SetValue(db.transparency or 0);opacityLabel:SetText(L.TRANSPARENCY..(db.transparency or 0).." %")
        f.fontButton:SetText(L.FONT..(api.fonts[db.fontStyle or 1] or api.fonts[1])[1]);f.borderButton:SetText(L.BORDER..api.borders[db.borderStyle or 1])
        for _,fn in ipairs(toggles) do fn() end
    end
    -- Custom daily goals plus an editable threshold/color table.
    p=f.pages[2]
    text(p,0,0,570,L.GOAL_NOTE,"GameFontHighlightSmall")
    local goalIndex=0
    local selected=text(p,48,-48,480,"")
    local name=numeric(p,0,-88,280,L.GOAL_NAME)
    local target=numeric(p,300,-88,274,L.STEPS_TARGET)
    local function selectGoal(i)
        goalIndex=math.max(0,math.min(#db.customGoals,i))
        local g=db.customGoals[goalIndex]
        selected:SetText(g and (goalIndex.."/"..#db.customGoals.."  "..g.name.."  "..api.number(db.today).." / "..api.number(g.target)) or L.NEW)
        name:SetText(g and g.name or "");target:SetText(g and tostring(g.target) or "10000")
    end
    button(p,0,-42,40,"<",function()selectGoal(goalIndex-1) end)
    button(p,534,-42,40,">",function()selectGoal(goalIndex+1) end)
    button(p,0,-152,175,L.NEW,function()selectGoal(0) end)
    button(p,196,-152,175,L.SAVE,function()
        local g=db.customGoals[goalIndex]
        local ok=C.SaveGoal(db,g and g.id,name:GetText(),value(target))
        if ok then selectGoal(g and goalIndex or #db.customGoals) end;feedback(ok)
    end)
    button(p,392,-152,182,L.DELETE,function()
        if db.customGoals[goalIndex] then table.remove(db.customGoals,goalIndex);selectGoal(0);feedback(true) end
    end)
    text(p,0,-203,570,L.STAGE_FORMAT,"GameFontHighlightSmall")
    local stageEdit=edit(p,5,-246,560,150,true);f.stageInput=stageEdit
    local function stagesText()
        local lines={};for _,s in ipairs(db.stages) do lines[#lines+1]=s[1].." #"..s[2] end
        stageEdit:SetText(table.concat(lines,"\n"))
    end
    button(p,0,-424,280,L.SAVE,function()
        local parsed=C.ParseStages(stageEdit:GetText());if parsed then db.stages=parsed end;feedback(parsed~=nil)
    end)
    button(p,294,-424,280,L.RESET,function()db.stages=nil;C.InitFeatures(db);stagesText();feedback(true) end)
    p.sync=function()selectGoal(goalIndex);stagesText() end
    -- Message editor. No chat sends occur from this page.
    p=f.pages[3]
    text(p,0,0,570,L.MESSAGE_NOTE,"GameFontHighlightSmall")
    local messageIndex=1
    local count=text(p,48,-49,480,"")
    local messageEdit=edit(p,5,-88,560,100,true);f.messageInput=messageEdit
    text(p,0,-243,570,L.TOKENS,"GameFontHighlightSmall")
    text(p,0,-307,570,L.MESSAGE_LIMIT,"GameFontDisableSmall")
    local preview=text(p,0,-400,570,"","GameFontHighlightSmall")
    local function selectMessage(i)
        local messages=C.Messages(db);messageIndex=math.max(1,math.min(#messages+1,i))
        count:SetText(messageIndex.." / "..#messages)
        messageEdit:SetText(messages[messageIndex] or "");preview:SetText("")
    end
    button(p,0,-42,40,"<",function()selectMessage(messageIndex-1) end)
    button(p,534,-42,40,">",function()selectMessage(messageIndex+1) end)
    button(p,0,-203,130,L.NEW,function()selectMessage(#C.Messages(db)+1) end)
    f.saveMessage=button(p,144,-203,130,L.SAVE,function()
        local t=messageEdit:GetText();local messages=C.Messages(db)
        if not C.ValidTemplate(t) or messageIndex>30 then feedback(false);return end
        messages[messageIndex]=t;selectMessage(messageIndex);feedback(true)
    end)
    button(p,288,-203,130,L.DELETE,function()
        local messages=C.Messages(db)
        if #messages>1 and messages[messageIndex] then table.remove(messages,messageIndex);selectMessage(1);feedback(true) else feedback(false) end
    end)
    button(p,432,-203,142,L.RESET,function()
        messageEdit:SetText((L["JOKE"..((messageIndex-1)%4+1)]:gsub("%%s","{steps}")))
    end)
    f.previewMessage=button(p,0,-357,280,L.PREVIEW,function()
        if not C.ValidTemplate(messageEdit:GetText()) then feedback(false);return end
        preview:SetText(C.RenderMessage(db,messageEdit:GetText(),api.number))
    end)
    p.sync=function()selectMessage(messageIndex) end
    -- Fantasy calorie model and explicit food overrides.
    p=f.pages[4]
    text(p,0,0,570,L.CAL_NOTE,"GameFontHighlightSmall")
    local raceLabel=text(p,0,-47,570,"")
    local base=numeric(p,0,-72,280,L.RACE_BASE)
    local rate=numeric(p,300,-72,274,L.MOVE_RATE)
    local meal=numeric(p,0,-136,280,L.MEAL_VALUE)
    local auto=button(p,300,-160,274,"",function(self)
        db.autoFood=db.autoFood==false;self:SetText((db.autoFood~=false and "[+] " or "[-] ")..L.AUTO_FOOD)
    end)
    f.saveCalories=button(p,0,-201,175,L.SAVE,function()
        local a,b,c=value(base),value(rate),value(meal)
        if not a or a<100 or a>20000 or not b or b<0 or b>1 or not c or c<1 or c>10000 then feedback(false);return end
        db.raceCalories[api.race()]=a;db.calRate=b;db.mealCalories=c;feedback(true)
    end)
    button(p,196,-201,175,L.LOG_MEAL,function()C.Day(db,api.day());C.Meal(db,db.mealCalories);feedback(true) end)
    button(p,392,-201,182,L.UNDO_MEAL,function()C.Day(db,api.day());feedback(C.UndoMeal(db)) end)
    text(p,0,-244,570,L.FOOD_MAP,"GameFontHighlightSmall")
    local food=edit(p,5,-280,560,80,true);f.foodInput=food
    button(p,0,-370,175,L.SAVE,function()
        local parsed=C.ParseFood(food:GetText());if parsed then db.foodSpells=parsed end;feedback(parsed~=nil)
    end)
    local last=text(p,196,-377,378,"","GameFontHighlightSmall")
    text(p,0,-416,570,L.FOOD_NOTE,"GameFontDisableSmall")
    f.UpdateLive=function()
        if f.page==2 then
            local g=db.customGoals[goalIndex]
            if g then selected:SetText(goalIndex.."/"..#db.customGoals.."  "..g.name.."  "..api.number(db.today).." / "..api.number(g.target)) end
        elseif f.page==4 then last:SetText(L.LAST_SPELL..tostring(api.lastSpell() or "-")) end
    end
    p.sync=function()
        local race,raceName=api.race();raceLabel:SetText(raceName.."  ("..race..")")
        base:SetText(tostring(C.RaceBase(db,race)));rate:SetText(tostring(db.calRate));meal:SetText(tostring(db.mealCalories))
        auto:SetText((db.autoFood~=false and "[+] " or "[-] ")..L.AUTO_FOOD)
        local keys={};for id in pairs(db.foodSpells) do keys[#keys+1]=id end;table.sort(keys)
        local lines={};for _,id in ipairs(keys) do lines[#lines+1]=id.." "..db.foodSpells[id] end;food:SetText(table.concat(lines,"\n"))
        last:SetText(L.LAST_SPELL..tostring(api.lastSpell() or "-"))
    end
    f:SetScript("OnShow",function(self)self:ShowPage(self.page or 1) end)
    f:SetScript("OnHide",function(self)self:StopMovingOrSizing() end)
    f:ShowPage(1);f:Hide()
    return f
end
