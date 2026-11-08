-- Super Speed for Cyberpunk 2077
-- Requires Cyber Engine Tweaks (CET).
--
-- Two effects, each can be turned on or off:
--   1. Slow world: everything except V slows down (the same game system the
--      Sandevistan uses). V keeps moving at normal speed, so next to everyone
--      else V is very fast.
--   2. Fast legs: V's top running speed is multiplied.
-- Together V moves (runSpeed / worldSpeed) times faster than everyone else.
-- With the defaults that is 2.0 / 0.2 = 10x.
--
-- The settings below are the starting values. While playing you can change
-- them with the sliders in the CET overlay; slider changes last until you
-- quit the game.

local settings = {
    worldSpeed = 0.2,      -- world speed while active (1.0 = normal, 0.2 = 20%)
    runSpeed = 2.0,        -- multiplier on V's top speed (1.0 = normal)
    slowWorld = true,      -- use the slow-world effect
    fastLegs = true,       -- use the faster-running effect
    offInVehicles = true,  -- pause slow-world while driving (cars are part of the world and would crawl)
}

local REASON = "SuperSpeedMod"   -- name our time change is filed under, so we only undo our own
local RECHECK_SECONDS = 0.25     -- how often to re-check vehicles, save loads, etc.

local state = {
    active = false,        -- player wants super speed on
    worldApplied = false,  -- slow-world is currently on
    legs = nil,            -- { id = statsId, mods = {...}, before = number } while fast legs are on
    reapply = false,       -- set when a save loads, so we re-add everything to the new V
    overlayOpen = false,
    timer = 0,
    lastMessage = "",
    speedReadout = "",
}

local function log(msg)
    print("[SuperSpeed] " .. msg)
    state.lastMessage = msg
end

local function getPlayer()
    local ok, player = pcall(function() return Game.GetPlayer() end)
    if ok and player then return player end
    return nil
end

local function inVehicle(player)
    local ok, vehicle = pcall(function() return Game.GetMountedVehicle(player) end)
    return ok and vehicle ~= nil
end

---------------------------------------------------------------------------
-- Slow world
---------------------------------------------------------------------------

local function applyWorld()
    local ok, err = pcall(function()
        local ts = Game.GetTimeSystem()
        -- Clear our previous value first so a slider change replaces it.
        ts:UnsetTimeDilation(CName.new(REASON))
        ts:SetTimeDilation(CName.new(REASON), settings.worldSpeed)
        ts:SetIgnoreTimeDilationOnLocalPlayerZero(true)
    end)
    if ok then
        state.worldApplied = true
    else
        log("Could not slow the world: " .. tostring(err))
    end
end

local function removeWorld()
    pcall(function()
        local ts = Game.GetTimeSystem()
        ts:UnsetTimeDilation(CName.new(REASON))
        ts:SetIgnoreTimeDilationOnLocalPlayerZero(false)
    end)
    state.worldApplied = false
end

---------------------------------------------------------------------------
-- Fast legs
---------------------------------------------------------------------------

-- The stat system identifies V by a "stats ID". Build the current-format one
-- first; fall back to the plain entity ID that older game versions accepted.
local function statsIdCandidates(player)
    local list = {}
    local ok, sid = pcall(function()
        local s = StatsObjectID.new()
        s.entityHash = player:GetEntityID().hash
        s.idType = gameStatIDType.EntityID
        return s
    end)
    if ok and sid then table.insert(list, sid) end
    table.insert(list, player:GetEntityID())
    return list
end

local function readMaxSpeed(id)
    local ok, value = pcall(function()
        return Game.GetStatsSystem():GetStatValue(id, gamedataStatType.MaxSpeed)
    end)
    if ok and value then return value end
    return nil
end

local function makeModifiers()
    return {
        RPGManager.CreateStatModifier(gamedataStatType.MaxSpeed, gameStatModifierType.Multiplier, settings.runSpeed),
        RPGManager.CreateStatModifier(gamedataStatType.Acceleration, gameStatModifierType.Multiplier, settings.runSpeed),
    }
end

local function applyLegs(player)
    local ss = Game.GetStatsSystem()
    local okMods, mods = pcall(makeModifiers)
    if not okMods then
        log("Could not create speed modifiers: " .. tostring(mods))
        return
    end

    for _, id in ipairs(statsIdCandidates(player)) do
        local before = readMaxSpeed(id)
        local ok = pcall(function() ss:AddModifier(id, mods[1]) end)
        if ok then
            pcall(function() ss:AddModifier(id, mods[2]) end)
            state.legs = { id = id, mods = mods, before = before }
            log("Fast legs on")
            return
        end
    end
    log("Could not boost run speed (the game rejected the speed change)")
end

-- Shown in the window so we can tell whether the boost reaches V's speed.
local function updateSpeedReadout()
    if not state.legs then
        state.speedReadout = ""
        return
    end
    local now = readMaxSpeed(state.legs.id)
    local before = state.legs.before
    state.speedReadout = string.format("Top speed stat: %s (was %s)",
        now and string.format("%.2f", now) or "?",
        before and string.format("%.2f", before) or "?")
end

local function removeLegs()
    if not state.legs then return end
    local ss = Game.GetStatsSystem()
    for _, mod in ipairs(state.legs.mods) do
        pcall(function() ss:RemoveModifier(state.legs.id, mod) end)
    end
    state.legs = nil
    state.speedReadout = ""
end

---------------------------------------------------------------------------
-- On / off
---------------------------------------------------------------------------

local function turnOn()
    local player = getPlayer()
    if not player then
        log("Load into the game first")
        return
    end
    state.active = true
    if settings.slowWorld and not (settings.offInVehicles and inVehicle(player)) then
        applyWorld()
    end
    if settings.fastLegs then
        applyLegs(player)
    end
    log("Super speed ON")
end

local function turnOff()
    state.active = false
    removeWorld()
    removeLegs()
    log("Super speed OFF")
end

local function toggle()
    if state.active then turnOff() else turnOn() end
end

-- Forget everything without calling the game (used when the game is back at
-- the main menu: the old V and its speed changes are already gone).
local function forgetAll()
    state.active = false
    state.worldApplied = false
    state.legs = nil
    state.speedReadout = ""
end

---------------------------------------------------------------------------
-- Key bindings (set the keys in the CET overlay -> Bindings)
---------------------------------------------------------------------------

registerHotkey("SuperSpeedToggle", "Toggle super speed", toggle)

registerInput("SuperSpeedHold", "Hold for super speed", function(isDown)
    if isDown and not state.active then
        turnOn()
    elseif not isDown and state.active then
        turnOff()
    end
end)

---------------------------------------------------------------------------
-- Game events
---------------------------------------------------------------------------

registerForEvent("onInit", function()
    -- Loading a save creates a new V, so speed changes on the old one are lost.
    local ok, err = pcall(function()
        Observe("PlayerPuppet", "OnGameAttached", function()
            if state.active then state.reapply = true end
        end)
    end)
    if not ok then log("Save-load watcher not available: " .. tostring(err)) end
    log("Loaded. Bind your keys in the CET overlay -> Bindings.")
end)

registerForEvent("onUpdate", function(delta)
    if not state.active then return end

    state.timer = state.timer + delta
    if state.timer < RECHECK_SECONDS then return end
    state.timer = 0

    local player = getPlayer()
    if not player then
        -- Main menu or loading screen.
        removeWorld()
        forgetAll()
        return
    end

    -- A save was loaded while super speed was on: put it back on the new V.
    if state.reapply then
        state.reapply = false
        removeWorld()
        removeLegs()
        turnOn()
        return
    end

    -- Slow world: pause it while driving, bring it back on foot.
    local wantWorld = settings.slowWorld and not (settings.offInVehicles and inVehicle(player))
    if wantWorld and not state.worldApplied then
        applyWorld()
    elseif not wantWorld and state.worldApplied then
        removeWorld()
    elseif state.worldApplied then
        -- Other effects (e.g. a real Sandevistan ending) can switch V back to
        -- following world time. Keep V at full speed.
        pcall(function() Game.GetTimeSystem():SetIgnoreTimeDilationOnLocalPlayerZero(true) end)
    end

    -- Fast legs: add or remove if the checkbox changed.
    if settings.fastLegs and not state.legs then
        applyLegs(player)
    elseif not settings.fastLegs and state.legs then
        removeLegs()
    end
    updateSpeedReadout()
end)

registerForEvent("onShutdown", function()
    -- "Reload all mods" or quitting: undo everything we changed.
    if state.active then turnOff() end
end)

registerForEvent("onOverlayOpen", function() state.overlayOpen = true end)
registerForEvent("onOverlayClose", function() state.overlayOpen = false end)

---------------------------------------------------------------------------
-- Settings window (shown while the CET overlay is open)
---------------------------------------------------------------------------

registerForEvent("onDraw", function()
    if not state.overlayOpen then return end

    if ImGui.Begin("Super Speed", ImGuiWindowFlags.AlwaysAutoResize) then
        if ImGui.Button(state.active and "Turn OFF" or "Turn ON", 160, 0) then
            toggle()
        end
        ImGui.SameLine()
        ImGui.Text(state.active and "Status: ON" or "Status: OFF")

        ImGui.Separator()

        local changed
        settings.slowWorld, changed = ImGui.Checkbox("Slow world", settings.slowWorld)
        if changed and state.active and not settings.slowWorld then removeWorld() end

        settings.worldSpeed, changed = ImGui.SliderFloat("World speed", settings.worldSpeed, 0.05, 1.0, "%.2f")
        if changed and state.worldApplied then applyWorld() end

        settings.fastLegs, changed = ImGui.Checkbox("Fast legs", settings.fastLegs)

        settings.runSpeed, changed = ImGui.SliderFloat("Run speed", settings.runSpeed, 1.0, 5.0, "%.1fx")
        if changed and state.legs then
            -- Swap the old boost for one at the new strength.
            local player = getPlayer()
            removeLegs()
            if player then applyLegs(player) end
        end

        settings.offInVehicles = ImGui.Checkbox("Normal world speed while driving", settings.offInVehicles)

        ImGui.Separator()
        ImGui.Text(string.format("V vs world: about %.0fx faster",
            (settings.fastLegs and settings.runSpeed or 1.0) / (settings.slowWorld and settings.worldSpeed or 1.0)))
        if state.speedReadout ~= "" then ImGui.Text(state.speedReadout) end
        if state.lastMessage ~= "" then ImGui.TextWrapped(state.lastMessage) end
    end
    ImGui.End()
end)
