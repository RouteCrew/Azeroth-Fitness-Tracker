local NS,db,driver,panel=...
local s=panel.settings
ColorPickerFrame={shown=false}
function ColorPickerFrame:SetupColorPickerAndShow(info)
    self.info=info;self.r=info.r;self.g=info.g;self.b=info.b;self.shown=true
    info.swatchFunc()
end
function ColorPickerFrame:GetColorRGB()return self.r,self.g,self.b end
function ColorPickerFrame:GetExtraInfo()return self.info.extraInfo end
function ColorPickerFrame:Hide()self.shown=false end
s:ShowPage(2)
local original=db.stages[1][2]
s.stageSwatch.scripts.OnClick()
assert(ColorPickerFrame.shown and ColorPickerFrame.info.hasOpacity==false)
ColorPickerFrame.r=0;ColorPickerFrame.g=1;ColorPickerFrame.b=0
ColorPickerFrame.info.swatchFunc()
assert(s.stageSwatch.fill.r==0 and s.stageSwatch.fill.g==1)
assert(db.stages[1][2]==original,'picker preview must not write saved colors')
ColorPickerFrame.info.cancelFunc()
s.saveStage.scripts.OnClick()
assert(db.stages[1][2]==original,'cancel must restore the draft color')
s.stageSwatch.scripts.OnClick()
ColorPickerFrame.r=0;ColorPickerFrame.g=0;ColorPickerFrame.b=1
ColorPickerFrame.info.swatchFunc();ColorPickerFrame:Hide()
s.saveStage.scripts.OnClick()
assert(db.stages[1][2]=='0000ff' and s.stagePalette[1].fill.b==1)
assert(NS.Core.New(db,db.day).stages[1][2]=='0000ff')
s.stageNext.scripts.OnClick()
s.stageThreshold:SetText('10000');s.saveStage.scripts.OnClick()
assert(db.stages[2][1]==20000,'duplicate thresholds must not replace entries')
s.newStage.scripts.OnClick();s.stageThreshold:SetText('5000');s.saveStage.scripts.OnClick()
assert(db.stages[1][1]==5000 and #db.stages==11)
s.deleteStage.scripts.OnClick();assert(db.stages[1][1]==10000 and #db.stages==10)
-- A color picker belonging to another addon is not closed by this menu.
s.stageSwatch.scripts.OnClick()
ColorPickerFrame.info.extraInfo={other=true}
s:ShowPage(4);assert(ColorPickerFrame.shown)
-- Both visibility changes preserve calorie state and permit further tracking.
local eaten,distance=db.calEaten,db.calDistance
s.showCalories:SetChecked(false);s.showCalories.scripts.OnClick(s.showCalories)
assert(db.showCalories==false and not panel.calBar.shown and not panel.calTitle.shown and not panel.calSummary.shown)
assert(panel:GetHeight()==314 and db.calEaten==eaten)
NS.Core.Add(db,db.day,7,0.1,true);assert(db.calDistance>distance)
s:ShowPage(1);s:ShowPage(4);assert(s.showCalories:GetChecked()==false)
s.showCalories:SetChecked(true);s.showCalories.scripts.OnClick(s.showCalories)
assert(db.showCalories and panel.calBar.shown and panel:GetHeight()==386)
s:ShowPage(2);s.stageSwatch.scripts.OnClick()
local stale=ColorPickerFrame.info.swatchFunc
s:Hide();assert(not ColorPickerFrame.shown)
ColorPickerFrame.r=1;ColorPickerFrame.g=0;ColorPickerFrame.b=0;stale()
assert(db.stages[1][2]=='0000ff','hidden picker callbacks cannot alter saved state')
print('PASS: visual swatches, picker preview/cancel/save, threshold edits, ownership, calorie visibility and tracking')
