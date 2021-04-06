-- RemoveOrKeepSection v1 (6 April 2021)

-- original code made by IceDynamix on a phone and posted on the Quaver Discord
--
-- (kloi34) added current buttons, spruced up the UI, made the "remove section" option, and added
--    the option to remove SVs and timing points

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

START_OFFSET = 0
END_OFFSET = 0
REMOVE_NOTES = true
REMOVE_TIMING_POINTS = false
REMOVE_SVS = false

---------------------------------------------------------------------------------------------------
-- Global constants
---------------------------------------------------------------------------------------------------

SAMELINE_SPACING = 5               -- value determining spacing between GUI items on the same row
DEFAULT_WIDGET_HEIGHT = 26         -- value determining the height of GUI widgets
BUTTON_WIDGET_WIDTH = 60           -- value determining the width of buttons

---------------------------------------------------------------------------------------------------
-- Plugin and GUI
---------------------------------------------------------------------------------------------------

-- Creates the plugin window
function draw()
    applyStyle()
    menu()
end

-- Configures GUI visual settings
function applyStyle()
    -- Plugin Styles
    local rounding = 5
    
    imgui.PushStyleVar( imgui_style_var.WindowPadding,      { 8, 8 } )
    imgui.PushStyleVar( imgui_style_var.FramePadding,       { 8, 5 }   )
    imgui.PushStyleVar( imgui_style_var.ItemSpacing,        { DEFAULT_WIDGET_HEIGHT / 2 - 1, 4 })
    imgui.PushStyleVar( imgui_style_var.ItemInnerSpacing,   { SAMELINE_SPACING, 6 })
    imgui.PushStyleVar( imgui_style_var.WindowBorderSize,   0          )
    imgui.PushStyleVar( imgui_style_var.WindowRounding,     rounding   )
    imgui.PushStyleVar( imgui_style_var.FrameRounding,      rounding   )
end

-- Creates the plugin menu
function menu()
    imgui.Begin("RemoveOrKeepSection", imgui_window_flags.AlwaysAutoResize)
    state.IsWindowHovered = imgui.IsWindowHovered()
    imgui.PushItemWidth(200)
    
    if imgui.Button("Current", {BUTTON_WIDGET_WIDTH, DEFAULT_WIDGET_HEIGHT}) then
        START_OFFSET = state.SongTime
    end
    imgui.SameLine(0, SAMELINE_SPACING)
    _, START_OFFSET = imgui.InputInt("Start", START_OFFSET)
    
    if imgui.Button(" Current ", {BUTTON_WIDGET_WIDTH, DEFAULT_WIDGET_HEIGHT}) then
        END_OFFSET = state.SongTime
    end
    imgui.SameLine(0, SAMELINE_SPACING)
    _, END_OFFSET = imgui.InputInt("End", END_OFFSET)
    
    imgui.PopItemWidth()
    
    _, REMOVE_NOTES = imgui.Checkbox("Remove Notes", REMOVE_NOTES)
    _, REMOVE_TIMING_POINTS = imgui.Checkbox("Remove Timing Points", REMOVE_TIMING_POINTS)
    _, REMOVE_SVS = imgui.Checkbox("Remove SVs", REMOVE_SVS)
    
    imgui.Dummy({0, 1})
    imgui.Separator()
    imgui.Dummy({0, 1})
    
    if imgui.Button("Remove Section", {2 * BUTTON_WIDGET_WIDTH, DEFAULT_WIDGET_HEIGHT}) then
        removeStuff(REMOVE_NOTES, REMOVE_TIMING_POINTS, REMOVE_SVS, START_OFFSET, END_OFFSET, false)
    end
    
    imgui.SameLine(0, 5 * SAMELINE_SPACING)
    
    if imgui.Button("Keep Section", {2 * BUTTON_WIDGET_WIDTH, DEFAULT_WIDGET_HEIGHT}) then
        removeStuff(REMOVE_NOTES, REMOVE_TIMING_POINTS, REMOVE_SVS, START_OFFSET, END_OFFSET, true)
    end
end

---------------------------------------------------------------------------------------------------
-- Calculation/helper functions
---------------------------------------------------------------------------------------------------

-- Removes notes, timing points, and/or SVs that are inside or outside a certain section
-- Parameters
--    removeNotes        : whether or not to remove notes (Boolean)
--    removeTimingPoints : whether or not to remove timing points (Boolean)
--    removeSVs          : whether or not to remove svs (Boolean)
--    startOffset        : the start time in millseconds of the section (Int)
--    endOffset          : the end time in millseconds of the section (Int)
--    keepsection        : whether or not to keep the section and delete everything else (Boolean)
function removeStuff(removeNotes, removeTimingPoints, removeSVs, startOffset, endOffset, keepSection)
    if removeNotes then
        local hitObjectsToDelete = thingsToRemove(startOffset, endOffset, keepSection, map.HitObjects)
        actions.RemoveHitObjectBatch(hitObjectsToDelete)
    end
    
    if removeTimingPoints then
        local timingPointsToDelete = thingsToRemove(startOffset, endOffset, keepSection, map.TimingPoints)
        -- if we want to keep a section and there are timing points outside the section
        if keepSection and #timingPointsToDelete > 0 then
            -- don't delete the last timing point outside the section
            table.remove(timingPointsToDelete, #timingPointsToDelete)
        end
        actions.RemoveTimingPointBatch(timingPointsToDelete)
    end
    
    if removeSVs then
        local SVsToDelete = thingsToRemove(startOffset, endOffset, keepSection, map.ScrollVelocities)
        actions.RemoveScrollVelocityBatch(SVsToDelete)
    end
end

-- Returns a list of things (SVs, timing points, or hitObjects) to remove
-- Parameters
--    startOffset : start time in millseconds of the section (Int)
--    endOffset   : end time in millseconds of the section (Int)
--    keepsection : whether or not to keep the section and delete everything else (Boolean)
--    list        : list of all of map's things of single type (Table)
function thingsToRemove(startOffset, endOffset, keepSection, list)
    local thingsToRemove = {}
    for i, thing in pairs(list) do
        if keepSection and isOutOfRange(thing.StartTime, startOffset, endOffset) then
            table.insert(thingsToRemove, thing)
        elseif (not keepSection) and isWithinRange(thing.StartTime, startOffset, endOffset) then
            table.insert(thingsToRemove, thing)
        end
    end
    return thingsToRemove
end

-- Returns whether a number is within a given range
-- Parameters
--    x          : number in question
--    lowerBound : upper bound of the range
--    upperBound : lower bound of the range
function isWithinRange(x, lowerBound, upperBound)
    return x >= lowerBound and x <= upperBound
end

-- Returns whether a number is outside a given range
-- Parameters
--    x          : number in question
--    lowerBound : upper bound of the range
--    upperBound : lower bound of the range
function isOutOfRange(x, lowerBound, upperBound)
    return not isWithinRange(x, lowerBound, upperBound)
end