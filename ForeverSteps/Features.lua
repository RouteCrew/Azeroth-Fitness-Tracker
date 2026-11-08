local _, NS = ...
local C, L = NS.Core, NS.L
C.RaceCalories = {Human=2200,Orc=3000,Dwarf=2600,NightElf=2100,Scourge=1200,Tauren=4200,Gnome=1400,Troll=2800,Skyborne=2300,SkyborneAlliance=2300,SkyborneHorde=2400,BloodElf=2300,Draenei=3200,Worgen=3100,Goblin=1600,Pandaren=3600}
C.DefaultStages = {{10000,"ff9900"},{20000,"3388ff"},{30000,"33cc66"},{40000,"aa66ee"},{50000,"ff4444"},{60000,"ffcc33"},{70000,"33dddd"},{80000,"ff77bb"},{90000,"cccccc"},{100000,"ffd700"}}
function C.InitFeatures(db)
    db.todayRunSeconds = tonumber(db.todayRunSeconds) or 0
    db.calDistance = tonumber(db.calDistance) or 0
    db.calEaten = tonumber(db.calEaten) or 0
    db.raceCalories = db.raceCalories or {}
    db.calRate = tonumber(db.calRate) or 0.02
    db.mealCalories = tonumber(db.mealCalories) or 250
    db.foodSpells = db.foodSpells or {}
    db.customGoals = db.customGoals or {}
    db.customWins = db.customWins or {}
    db.nextGoalID = tonumber(db.nextGoalID) or 1
    db.messageSets = db.messageSets or {}
    if not db.stages then
        db.stages={}
        for i,s in ipairs(C.DefaultStages) do db.stages[i]={s[1],s[2]} end
    end
end
function C.RaceBase(db,race)
    race=race or "Unknown"
    if db.raceCalories[race] then return db.raceCalories[race] end
    if C.RaceCalories[race] then return C.RaceCalories[race] end
    -- Stable fantasy default for future client race tokens, editable in the menu.
    local hash=0; for i=1,#race do hash=(hash*31+race:byte(i))%1000 end
    return 2000+hash
end
function C.Calories(db,race)
    local need=C.RaceBase(db,race)+db.calDistance*db.calRate
    return math.max(0,need-db.calEaten),need,db.calEaten
end
function C.Meal(db,amount)
    if type(amount)~="number" or amount<=0 or amount>10000 then return false end
    db.calEaten=db.calEaten+amount; db.lastMeal=amount
    return true
end
function C.UndoMeal(db)
    if not db.lastMeal then return false end
    db.calEaten=math.max(0,db.calEaten-db.lastMeal); db.lastMeal=nil; return true
end
function C.SaveGoal(db,id,name,target)
    name=(name or ""):match("^%s*(.-)%s*$")
    if #name==0 or #name>80 or name:find("[|\r\n]") or not target or target<1 or target>10000000 or target%1~=0 then return false end
    for _,g in ipairs(db.customGoals) do
        if g.id==id then g.name=name; g.target=target; return true end
    end
    if #db.customGoals>=20 then return false end
    db.customGoals[#db.customGoals+1]={id=db.nextGoalID,name=name,target=target}
    db.nextGoalID=db.nextGoalID+1; return true
end
function C.GoalCrossings(db,before)
    local reached={}
    for _,g in ipairs(db.customGoals) do
        if before<g.target and db.today>=g.target and not db.customWins[g.id] then
            db.customWins[g.id]=true; reached[#reached+1]=g.name
        end
    end
    return reached
end
function C.ParseStages(text)
    local stages={}
    for line in (text.."\n"):gmatch("([^\n]*)\n") do
        if line:match("%S") then
            local n,hex=line:match("^%s*(%d+)%s+#?(%x%x%x%x%x%x)%s*$")
            n=tonumber(n)
            if not n or n<1 or n>10000000 then return nil end
            stages[#stages+1]={n,hex:lower()}
        end
    end
    if #stages<1 or #stages>20 then return nil end
    table.sort(stages,function(a,b)return a[1]<b[1] end)
    for i=2,#stages do if stages[i][1]==stages[i-1][1] then return nil end end
    return stages
end
function C.Stage(db)
    local previous,nextValue,hex=0,nil,"d9a33d"
    for _,s in ipairs(db.stages) do
        if db.today>=s[1] then previous=s[1]; hex=s[2] else nextValue=s[1]; break end
    end
    local progress=nextValue and math.min(db.today/nextValue,1) or 1
    return progress,tonumber(hex:sub(1,2),16)/255,tonumber(hex:sub(3,4),16)/255,tonumber(hex:sub(5,6),16)/255,nextValue
end
function C.Messages(db)
    local key=NS.locale
    if not db.messageSets[key] then
        db.messageSets[key]={}
        for i=1,4 do db.messageSets[key][i]=L["JOKE"..i]:gsub("%%s","{steps}") end
    end
    return db.messageSets[key]
end
local allowed={steps=true,total_steps=true,time=true,total_time=true,goal=true}
function C.ValidTemplate(text)
    if not text or not text:match("%S") or #text>500 or text:find("[|\r\n]") then return false end
    local valid=true
    local rest=text:gsub("{([^{}]+)}",function(key) if not allowed[key] then valid=false end; return "" end)
    return valid and not rest:find("[{}]")
end
function C.RenderMessage(db,template,number)
    local values={steps=number(db.today),total_steps=number(db.total),time=C.FormatTime(db.todayRunSeconds),total_time=C.FormatTime(db.runSeconds),goal=number(db.goal)}
    local text="AFT: "..template:gsub("{([^{}]+)}",function(key)return values[key] or ("{"..key.."}") end)
    if #text>255 then
        local cut=252
        while cut>0 and text:byte(cut+1)>=128 and text:byte(cut+1)<=191 do cut=cut-1 end
        text=text:sub(1,cut).."..."
    end
    return text
end
function C.ParseFood(text)
    local spells={}
    for line in (text.."\n"):gmatch("([^\n]*)\n") do
        if line:match("%S") then
            local id,kcal=line:match("^%s*(%d+)%s+(%d+)%s*$")
            id,kcal=tonumber(id),tonumber(kcal)
            if not id or id<1 or id>10000000 or not kcal or kcal>10000 then return nil end
            spells[id]=kcal
        end
    end
    return spells
end
function C.FoodCalories(db,spellID)
    if db.foodSpells[spellID]~=nil then return db.foodSpells[spellID] end
    if spellID==433 or spellID==434 or spellID==435 then return db.mealCalories end
    if C_Spell and C_Spell.GetSpellName then
        local name,reference=C_Spell.GetSpellName(spellID),C_Spell.GetSpellName(433)
        if issecretvalue and (issecretvalue(name) or issecretvalue(reference)) then return nil end
        if name and reference and name==reference then return db.mealCalories end
    end
end
