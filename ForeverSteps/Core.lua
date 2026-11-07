local _, NS = ...
NS.Core = {}
local C = NS.Core
function C.New(db, day)
    db = type(db) == "table" and db or {}
    db.total = tonumber(db.total) or 0
    db.today = tonumber(db.today) or 0
    db.stride = tonumber(db.stride) or 2.5
    if db.stride < 0.5 or db.stride > 5 then db.stride = 2.5 end
    db.goal = tonumber(db.goal) or 10000
    if db.goal < 1 then db.goal = 10000 end
    db.transparency = math.max(0, math.min(75,tonumber(db.transparency) or 0))
    if not db.fontStyle or db.fontStyle < 1 or db.fontStyle > 3 then db.fontStyle=1 end
    if not db.borderStyle or db.borderStyle < 1 or db.borderStyle > 3 then db.borderStyle=1 end
    db.wins = db.wins or {}
    db.achievements = db.achievements or {}
    db.goalDays = tonumber(db.goalDays) or 0
    C.Day(db, day)
    return db
end
function C.Day(db, day)
    if db.day ~= day then db.day = day; db.today = 0 end
end
function C.Add(db, day, speed, elapsed, eligible)
    C.Day(db, day)
    -- Ignore stalls / loading gaps rather than inventing movement.
    if not eligible or elapsed <= 0 or elapsed > 0.5 or speed <= 0 then return end
    local before = db.today
    local steps = speed * elapsed / db.stride
    db.today = db.today + steps
    db.total = db.total + steps
    return before < db.goal and db.today >= db.goal
end

C.Milestones = {
    {1, "Der erste Schweiß"}, {3, "Sohlen statt Portale"},
    {7, "Eine Woche Waden"}, {14, "Mount hat Urlaub"},
    {30, "Azeroths Lauflegende"}, {100, "Die Sohlen des Schicksals"},
}
function C.Complete(db)
    if db.today < db.goal or db.wins[db.day] then return false, {} end
    db.wins[db.day] = db.goal
    db.goalDays = db.goalDays + 1
    local unlocked = {}
    for _, milestone in ipairs(C.Milestones) do
        local count, title = milestone[1], milestone[2]
        if db.goalDays >= count and not db.achievements[count] then
            db.achievements[count] = db.day
            unlocked[#unlocked+1] = title
        end
    end
    return true, unlocked
end
