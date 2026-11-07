import ctypes, ctypes.util
from pathlib import Path
lib=ctypes.CDLL(ctypes.util.find_library('lua5.4'))
lib.luaL_newstate.restype=ctypes.c_void_p
L=lib.luaL_newstate()
lib.luaL_openlibs.argtypes=[ctypes.c_void_p]; lib.luaL_openlibs(L)
lib.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lib.lua_tolstring.restype=ctypes.c_char_p
code='''
local NS={}
assert(loadfile('ForeverSteps/Core.lua'))('ForeverSteps',NS)
local c=NS.Core
local db=c.New(nil,'2026-11-07')
for i=1,100 do c.Add(db,'2026-11-07',7,0.1,true) end
assert(math.abs(db.total-28)<0.00001)
assert(math.abs(db.today-28)<0.00001)
c.Add(db,'2026-11-07',7,0.1,false)
c.Add(db,'2026-11-07',7,2,true)
c.Add(db,'2026-11-07',0,0.1,true)
assert(math.abs(db.total-28)<0.00001)
c.Add(db,'2026-11-08',5,0.5,true)
assert(db.today==1 and math.abs(db.total-29)<0.00001)
assert(c.New(db,'2026-11-08').today==1)
assert(c.New(db,'2026-11-09').today==0)
assert(math.abs(db.total-29)<0.00001)
assert(loadfile('ForeverSteps/ForeverSteps.lua'))
-- Minimal UI/event harness: load, login, hidden tracking, mount, restricted speed, reload.
local frames={}
local function noop() end
local methods={}
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:SetHeight(h) self.height=h end
function methods:GetHeight() return self.height end
function methods:GetWidth() return self.width end
function methods:GetFrameLevel() return 1 end
function methods:GetFont() return 'font',12,'' end
function methods:SetFont(f,size,flags) self.font=f end
function methods:SetAlpha(a) self.alpha=a end
function methods:IsShown() return self.shown end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:SetScale(n) self.scale=n end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:GetLeft() return 100 end
function methods:GetTop() return 800 end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetPoint() return 'CENTER',nil,'CENTER',0,0 end
function methods:CreateFontString() return setmetatable({scripts={}}, {__index=methods}) end
methods.CreateTexture=methods.CreateFontString
setmetatable(methods,{__index=function(_,k) if k:match("^[A-Z]") then return noop end end})
local named={}
function CreateFrame(kind,name) local f=setmetatable({scripts={}}, {__index=methods}); frames[#frames+1]=f; if name then named[name]=f end; return f end
UIParent={}; SlashCmdList={}; STANDARD_TEXT_FONT='font'
function date() return '2026-11-07' end
local mounted=false
function IsMounted() return mounted end
function GetUnitSpeed() return 7 end
assert(loadfile('ForeverSteps/ForeverSteps.lua'))('ForeverSteps',NS)
local d=frames[1]
d.scripts.OnEvent(d,'ADDON_LOADED','ForeverSteps')
d.scripts.OnEvent(d,'PLAYER_ENTERING_WORLD')
d.scripts.OnUpdate(d,0.1)
assert(ForeverStepsDB.total>0)
local before=ForeverStepsDB.total
mounted=true; d.scripts.OnUpdate(d,0.1); assert(ForeverStepsDB.total==before)
mounted=false
function issecretvalue() return true end
d.scripts.OnUpdate(d,0.1); assert(ForeverStepsDB.total==before)
issecretvalue=nil
SlashCmdList.FOREVERSTEPS('ausblenden'); d.scripts.OnUpdate(d,0.1)
assert(ForeverStepsDB.total>before)
SlashCmdList.FOREVERSTEPS('ziel 5000'); assert(ForeverStepsDB.goal==5000)
SlashCmdList.FOREVERSTEPS('schrittlaenge 1,5'); assert(ForeverStepsDB.stride==1.5)
d.scripts.OnEvent(d,'PLAYER_LEAVING_WORLD'); before=ForeverStepsDB.total
d.scripts.OnUpdate(d,0.1); assert(ForeverStepsDB.total==before)
local awards=c.New(nil,'day1')
for i=1,100 do
    c.Day(awards,'day'..i); awards.today=awards.goal
    assert(c.Complete(awards)==true)
    assert(c.Complete(awards)==false)
end
assert(awards.goalDays==100)
for _, m in ipairs(c.Milestones) do assert(awards.achievements[m[1]]) end
local sent={}
function IsInGuild() return true end
C_ChatInfo={SendChatMessage=function(msg,channel) sent[#sent+1]={msg,channel} end}
d.scripts.OnEvent(d,'PLAYER_ENTERING_WORLD')
ForeverStepsDB.goal=1; ForeverStepsDB.today=0.5
d.scripts.OnUpdate(d,0.25)
assert(#sent==1 and sent[1][2]=='GUILD' and sent[1][1]:sub(1,5)=='AFT: ')
assert(ForeverStepsDB.goalDays==1)
d.scripts.OnUpdate(d,0.25); assert(#sent==1)
d.scripts.OnEvent(d,'ADDON_LOADED','ForeverSteps')
d.scripts.OnUpdate(d,0.25); assert(#sent==1)
ForeverStepsDB.goal=0.5; d.scripts.OnUpdate(d,0.25); assert(#sent==1)
function date() return '2026-11-08' end
SlashCmdList.FOREVERSTEPS('gilde')
d.scripts.OnUpdate(d,0.25)
ForeverStepsDB.today=0; d.scripts.OnUpdate(d,0.25)
assert(#sent==1 and ForeverStepsDB.goalDays==2)
-- A new day with an already fulfilled goal must not announce on login or movement.
SlashCmdList.FOREVERSTEPS('gilde')
function date() return '2026-11-09' end
ForeverStepsDB.goal=100
d.scripts.OnUpdate(d,0.25)
ForeverStepsDB.goal=1; ForeverStepsDB.today=5
local wins=ForeverStepsDB.goalDays
d.scripts.OnEvent(d,'ADDON_LOADED','ForeverSteps')
d.scripts.OnUpdate(d,0.25)
assert(#sent==1 and ForeverStepsDB.goalDays==wins)
SlashCmdList.FOREVERSTEPS('ziel 2'); d.scripts.OnUpdate(d,0.25)
assert(#sent==1 and ForeverStepsDB.goalDays==wins)
SlashCmdList.FOREVERSTEPS('ziel 10')
ForeverStepsDB.today=9.5; d.scripts.OnUpdate(d,0.25)
assert(#sent==2 and ForeverStepsDB.goalDays==wins+1)
print('PASS: crossing only, no login or lowered-goal message, daily deduplication')
local panel=named.ForeverStepsFrame
SlashCmdList.FOREVERSTEPS('zeigen')
assert(panel.shown)
panel.scripts.OnDragStart(panel); assert(panel.moving)
panel.scripts.OnMouseUp(panel,'RightButton')
assert(ForeverStepsDB.locked and not panel.moving)
panel.scripts.OnDragStart(panel); assert(not panel.moving)
local old=ForeverStepsDB.scale
SlashCmdList.FOREVERSTEPS('groesse 1.5'); assert(ForeverStepsDB.scale==old)
panel.scripts.OnMouseUp(panel,'RightButton')
local cx,cy,down=500,400,true
function GetCursorPosition() return cx,cy end
function IsMouseButtonDown() return down end
local grip=panel.grip
grip.scripts.OnMouseDown(grip,'LeftButton')
cx=600; cy=300; grip.scripts.OnUpdate(grip)
assert(ForeverStepsDB.scale>1)
cx=300; cy=600; grip.scripts.OnUpdate(grip)
assert(ForeverStepsDB.scale<1)
d.scripts.OnEvent(d,'PLAYER_REGEN_DISABLED'); assert(not panel.shown)
old=ForeverStepsDB.scale; cx=900; grip.scripts.OnUpdate(grip)
assert(ForeverStepsDB.scale==old)
SlashCmdList.FOREVERSTEPS('zeigen'); assert(not panel.shown)
d.scripts.OnEvent(d,'PLAYER_REGEN_ENABLED'); assert(panel.shown)
SlashCmdList.FOREVERSTEPS('ausblenden')
d.scripts.OnEvent(d,'PLAYER_REGEN_DISABLED')
d.scripts.OnEvent(d,'PLAYER_REGEN_ENABLED'); assert(not panel.shown)
print('PASS: corner scaling, lock, drag cancellation, combat and manual visibility')
SlashCmdList.FOREVERSTEPS('zeigen')
assert(panel:GetHeight()==282)
assert(not panel.badges[1].shown)
panel.achToggle.scripts.OnClick()
assert(panel:GetHeight()==402 and panel.badges[1].shown)
panel.achToggle.scripts.OnClick()
assert(panel:GetHeight()==282 and not panel.badges[1].shown)
panel.gear.scripts.OnClick(); assert(panel.settings.shown)
local options=panel.settings
options.opacity.scripts.OnValueChanged(options.opacity,50)
assert(panel.alpha==0.5 and ForeverStepsDB.transparency==50)
options.fontButton.scripts.OnClick(options.fontButton)
assert(ForeverStepsDB.fontStyle==2 and panel.today.font:find('ARIALN',1,true))
options.borderButton.scripts.OnClick(options.borderButton)
assert(ForeverStepsDB.borderStyle==2)
options.totalButton.scripts.OnClick(); assert(not panel.total.shown and not panel.totalLabel.shown)
options.totalButton.scripts.OnClick(); assert(panel.total.shown and panel.totalLabel.shown)
d.scripts.OnEvent(d,'PLAYER_REGEN_DISABLED'); assert(not options.shown)
d.scripts.OnEvent(d,'PLAYER_REGEN_ENABLED'); assert(not options.shown)
d.scripts.OnEvent(d,'ADDON_LOADED','ForeverSteps')
panel=named.ForeverStepsFrame
assert(panel:GetHeight()==282 and panel.alpha==0.5)
assert(ForeverStepsDB.fontStyle==2 and ForeverStepsDB.borderStyle==2)
print('PASS: collapse, settings, fonts, opacity, total visibility, persistence')
SlashCmdList.FOREVERSTEPS('ausblenden')
local sameSettings=panel.settings
SlashCmdList.AZEROTHFITNESSTRACKER()
assert(panel.shown and panel.settings==sameSettings and sameSettings.shown)
SlashCmdList.AZEROTHFITNESSTRACKER()
assert(panel.settings==sameSettings and sameSettings.shown)
d.scripts.OnEvent(d,'PLAYER_REGEN_DISABLED')
SlashCmdList.AZEROTHFITNESSTRACKER()
assert(not panel.shown and not sameSettings.shown)
d.scripts.OnEvent(d,'PLAYER_REGEN_ENABLED')
assert(SLASH_AZEROTHFITNESSTRACKER1=='/aft')
print('PASS: AFT prefix, /aft reuses settings, hidden and combat behavior')
local timeDB=c.New({total=1234,today=456},'2026-11-07')
assert(timeDB.total==1234 and timeDB.runSeconds==0)
c.Add(timeDB,'2026-11-07',7,0.5,true)
c.Add(timeDB,'2026-11-07',3.5,0.5,true)
assert(timeDB.runSeconds==1)
for _, args in ipairs({{0,0.5,true},{7,0.5,false},{7,2,true},{7,0,true}}) do
    c.Add(timeDB,'2026-11-07',args[1],args[2],args[3])
end
assert(timeDB.runSeconds==1)
timeDB.stride=1
c.Add(timeDB,'2026-11-08',14,0.25,true)
assert(timeDB.runSeconds==1.25)
assert(c.New(timeDB,'2026-11-09').runSeconds==1.25)
assert(c.FormatTime(0)=='00:00:00')
assert(c.FormatTime(59.9)=='00:00:59')
assert(c.FormatTime(3600)=='01:00:00')
assert(c.FormatTime(90061)=='1d 01:01:01')
assert(panel.twr~=nil)
print('PASS: TWR migration, speed changes, exclusions, stride independence, persistence, formatting')
print('PASS: core cases, syntax, UI/event mocks, exclusions, secrets, commands')
'''
err=lib.luaL_loadstring(L,code.encode()) or lib.lua_pcallk(L,0,0,0,0,None)
if err: raise RuntimeError(lib.lua_tolstring(L,-1,None).decode())
