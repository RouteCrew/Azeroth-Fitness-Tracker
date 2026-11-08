local NS,db,driver,panel,sent=...
local C=NS.Core
local test=C.New({total=123,runSeconds=456},'test-day')
assert(test.total==123 and test.runSeconds==456 and test.todayRunSeconds==0)
assert(C.RaceBase(test,'Tauren')>C.RaceBase(test,'Gnome'))
local left,need,eaten=C.Calories(test,'Human')
assert(left==2200 and need==2200 and eaten==0)
C.Add(test,'test-day',10,0.5,true)
left,need=C.Calories(test,'Human')
assert(need==2200.1 and left==need)
assert(C.Meal(test,250));left,need,eaten=C.Calories(test,'Human')
assert(eaten==250 and left==need-250)
assert(C.UndoMeal(test) and not C.UndoMeal(test))
C.Meal(test,10000);left=C.Calories(test,'Human');assert(left==0)
C.Day(test,'next');assert(test.calEaten==0 and test.calDistance==0 and test.todayRunSeconds==0)
assert(not C.UndoMeal(test))
-- Color thresholds change at the exact number reached, not before.
for _,stage in ipairs(test.stages) do
    test.today=stage[1]
    local fraction,r,g,b=C.Stage(test)
    assert(fraction>0 and fraction<=1)
    assert(math.abs(r-tonumber(stage[2]:sub(1,2),16)/255)<0.000001)
    assert(math.abs(g-tonumber(stage[2]:sub(3,4),16)/255)<0.000001)
    assert(math.abs(b-tonumber(stage[2]:sub(5,6),16)/255)<0.000001)
end
assert(C.ParseStages('20000 #3388ff\n10000 #ff9900')[1][1]==10000)
assert(not C.ParseStages('10 #ffffff\n10 #000000'))
assert(not C.ParseStages('20 invalid'))
assert(not C.ParseStages(''))
-- Goal edits cannot create duplicate awards; only new movement crossings count.
C.Day(test,'goals');test.stride=1
assert(C.SaveGoal(test,nil,'First',2))
assert(C.SaveGoal(test,nil,'Second',3))
local _,custom=C.Add(test,'goals',8,0.5,true)
assert(#custom==2)
_,custom=C.Add(test,'goals',8,0.5,true);assert(#custom==0)
local id=test.customGoals[1].id
assert(C.SaveGoal(test,id,'Renamed',9))
_,custom=C.Add(test,'goals',8,0.5,true);assert(#custom==0)
C.Day(test,'tomorrow');assert(not test.customWins[id])
assert(not C.SaveGoal(test,nil,'Bad|link',4))
-- Template validation, literal percent signs, every placeholder, UTF-8 limits.
assert(C.ValidTemplate('100% {steps} {time} {total_time} {total_steps} {goal}'))
assert(not C.ValidTemplate('{bad}'))
assert(not C.ValidTemplate('{steps'))
assert(not C.ValidTemplate('hi\nthere'))
assert(not C.ValidTemplate('|Hitem:1|h'))
test.today=123;test.total=456;test.todayRunSeconds=60;test.runSeconds=3600;test.goal=1000
local number=function(n)return tostring(math.floor(n)) end
assert(C.RenderMessage(test,'{steps}/{total_steps} {time}/{total_time} {goal}',number)=='AFT: 123/456 00:01:00/01:00:00 1000')
local long=C.RenderMessage(test,string.rep('走',200),number)
assert(#long<=255 and utf8.len(long))
local messages=C.Messages(test);messages[1]='Custom {steps}'
assert(C.Messages(C.New(test,'tomorrow'))[1]=='Custom {steps}')
-- Menu edits and preview never send a guild message.
local settings=panel.settings
settings:ShowPage(3)
local count=#sent
settings.messageInput:SetText('Test {steps} {time}')
settings.saveMessage.scripts.OnClick()
settings.previewMessage.scripts.OnClick()
assert(#sent==count and C.Messages(db)[1]=='Test {steps} {time}')
settings.messageInput:SetText('{invalid}')
settings.saveMessage.scripts.OnClick();assert(C.Messages(db)[1]=='Test {steps} {time}')
settings:ShowPage(1)
settings.goalInput:SetText('3210');settings.strideInput:SetText('2.5');settings.scaleInput:SetText('1')
settings.saveGeneral.scripts.OnClick();assert(db.goal==3210 and db.stride==2.5)
settings.goalInput:SetText('-1');settings.saveGeneral.scripts.OnClick();assert(db.goal==3210)
-- Automatic food: player only, exactly once per cast, no drinks, overrides and restrictions.
function C_SpellTestName(id) if id==433 or id==999 then return 'Food' end return 'Drink' end
C_Spell={GetSpellName=C_SpellTestName}
function GetTime()return 123 end
function UnitRace()return 'Human','Human' end
db.autoFood=true
local before=db.calEaten
driver.scripts.OnEvent(driver,'UNIT_SPELLCAST_SUCCEEDED','player','food-1',433)
assert(db.calEaten==before+db.mealCalories)
driver.scripts.OnEvent(driver,'UNIT_SPELLCAST_SUCCEEDED','player','food-1',433)
assert(db.calEaten==before+db.mealCalories)
driver.scripts.OnEvent(driver,'UNIT_SPELLCAST_SUCCEEDED','pet','food-2',433)
driver.scripts.OnEvent(driver,'UNIT_SPELLCAST_SUCCEEDED','player','drink-1',430)
assert(db.calEaten==before+db.mealCalories)
driver.scripts.OnEvent(driver,'UNIT_SPELLCAST_SUCCEEDED','player','food-3',999)
assert(db.calEaten==before+2*db.mealCalories)
db.foodSpells=C.ParseFood('1000 400\n433 0')
driver.scripts.OnEvent(driver,'UNIT_SPELLCAST_SUCCEEDED','player','food-4',1000)
assert(db.calEaten==before+2*db.mealCalories+400)
driver.scripts.OnEvent(driver,'UNIT_SPELLCAST_SUCCEEDED','player','food-5',433)
assert(db.calEaten==before+2*db.mealCalories+400)
function issecretvalue()return true end
driver.scripts.OnEvent(driver,'UNIT_SPELLCAST_SUCCEEDED','player','food-secret',1000)
assert(db.calEaten==before+2*db.mealCalories+400)
issecretvalue=nil
db.autoFood=false
driver.scripts.OnEvent(driver,'UNIT_SPELLCAST_SUCCEEDED','player','food-off',1000)
assert(db.calEaten==before+2*db.mealCalories+400)
assert(not C.ParseFood('not an id'))
print('PASS: race calories, movement demand, meals, daily reset, exact colors, custom goals, editor, UTF-8, food events')
