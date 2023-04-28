-----------------------------------------------------------------------------------------------------------------------
-- Addon Meta Information
-----------------------------------------------------------------------------------------------------------------------
local addonName = "RaidTables"
local author = "Owleé-Blackmoore"

-----------------------------------------------------------------------------------------------------------------------
-- Setup Tables And Variables for Easy Access
-----------------------------------------------------------------------------------------------------------------------
local addonDB = {}
addonDB.Widgets = {}
addonDB.Config = {}
addonDB.Widgets.Setups = {}
addonDB.Widgets.FreeSetups = {}
addonDB.Widgets.FreePlayers = {}
addonDB.Widgets.Dialogs = {}
addonDB.Options = {}
addonDB.Options.TierItems = {}
addonDB.Options.RareItems = {}
local widgets = addonDB.Widgets
local configs = addonDB.Config
local setups = widgets.Setups

addonDB.Tracking = {}
addonDB.Tracking.Active = false
addonDB.Tracking.Name = nil
addonDB.Testing = true

-----------------------------------------------------------------------------------------------------------------------
-- Rare Items
-----------------------------------------------------------------------------------------------------------------------
local RareItems = {
    195480,
    194301,
    195526,
    195527,
}

-----------------------------------------------------------------------------------------------------------------------
-- Tier Items
-----------------------------------------------------------------------------------------------------------------------
local TierItems = {
    196488,
    196598,
    196603,
    196593,

    196587,
    196597,
    196602,
    196592,

    196586,
    196596,
    196601,
    196591,

    196589,
    196599,
    196604,
    196594,

    196590,
    196600,
    196605,
    196595,
}

-----------------------------------------------------------------------------------------------------------------------
-- Create Whitespace String
-----------------------------------------------------------------------------------------------------------------------
local function Ws(num)
    local s = ""
    for i=0,num do
        s = s .. " "
    end
    return s
end

-----------------------------------------------------------------------------------------------------------------------
-- Dump Table into String
-----------------------------------------------------------------------------------------------------------------------
local function DumpValue(name, value, depth)
    local depth = depth or 0
    if type(value) == "table" then
        print(Ws(2*depth) .. name .. " = " .. "{")
        for k, v in pairs(value) do
            DumpValue(k, v, depth + 1)
        end
        print(Ws(2*depth) .. "}")
    else
        print(Ws(2*depth) .. name .. " = " .. value)
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Load libraries
-----------------------------------------------------------------------------------------------------------------------
local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

-----------------------------------------------------------------------------------------------------------------------
-- Wrap CreateFrame for Debugging
-----------------------------------------------------------------------------------------------------------------------
local createdFrameCount = 0
local nativeCreateFrame = CreateFrame
local function CreateFrame(frame, name, parent, flags)
    createdFrameCount = createdFrameCount + 1
    local newFrame = nativeCreateFrame(frame, name, parent, flags)
    return newFrame 
end

-----------------------------------------------------------------------------------------------------------------------
-- GUI Color Map
-----------------------------------------------------------------------------------------------------------------------
local color = {
    ["White"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 },
    ["LightGray"] = { ["r"] = 0.2, ["g"] = 0.2, ["b"] = 0.2, ["a"] = 1 },
    ["MidGray"] = { ["r"] = 0.2, ["g"] = 0.2, ["b"] = 0.2, ["a"] = 1 },
    ["DarkGray"] = { ["r"] = 0.1, ["g"] = 0.1, ["b"] = 0.1, ["a"] = 1 },
    ["Highlight"] = { ["r"] = 0.5, ["g"] = 0, ["b"] = 0.0, ["a"] = 1 },
    ["Active"] = { ["r"] = 0.5, ["g"] = 0, ["b"] = 0.0, ["a"] = 1 },
    ["Attention"] = { ["r"] = 1, ["g"] = 0, ["b"] = 0.0, ["a"] = 1 },
    ["Black"] = { ["r"] = 0, ["g"] = 0, ["b"] = 0, ["a"] = 1 },
    ["Gold"] = { ["r"] = 1, ["g"] = 0.8, ["b"] = 0, ["a"] = 1 },
    ["Green"] = { ["r"] = 0, ["g"] = 0.8, ["b"] = 0, ["a"] = 1 },
    ["Red"] = { ["r"] = 0.8, ["g"] = 0, ["b"] = 0, ["a"] = 1 },
}

-----------------------------------------------------------------------------------------------------------------------
-- Class Color Map
-----------------------------------------------------------------------------------------------------------------------
local classColor = {
    ["DEATHKNIGHT"] = {r = 0.77, g = 0.12, b = 0.23},
    ["DEMONHUNTER"] = {r = 0.64, g = 0.19, b = 0.79},
    ["DRUID"] = {r = 1.00, g = 0.49, b = 0.04},
    ["EVOKER"] = {r = 51/255, g = 147/255, b = 127/255},
    ["HUNTER"] = {r = 0.67, g = 0.83, b = 0.45},
    ["MAGE"] = {r = 0.25, g = 0.78, b = 0.92},
    ["MONK"] = {r = 0.00, g = 1.00, b = 0.59},
    ["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73},
    ["PRIEST"] = {r = 1.00, g = 1.00, b = 1.00},
    ["ROGUE"] = {r = 1.00, g = 0.96, b = 0.41},
    ["SHAMAN"] = {r = 0.00, g = 0.44, b = 0.87},
    ["WARLOCK"] = {r = 0.53, g = 0.53, b = 0.93},
    ["WARRIOR"] = {r = 0.78, g = 0.61, b = 0.43},
}

-----------------------------------------------------------------------------------------------------------------------
-- Order Configuration (Label and Sort-Callback)
-----------------------------------------------------------------------------------------------------------------------
local orderConfigs = { 
    { 
        ["Name"] = "Name A-Z", 
        ["Callback"] = function(a, b) 
            return a.PlayerName < b.PlayerName 
            or (a.PlayerName == b.PlayerName and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) < (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())))
            or (a.PlayerName == b.PlayerName and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) < (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())))
            or (a.PlayerName == b.PlayerName and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) < (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())))
        end 
    }, 
    { 
        ["Name"] = "Name Z-A", 
        ["Callback"] = function(a, b) 
            return a.PlayerName > b.PlayerName 
            or (a.PlayerName == b.PlayerName and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) > (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())))
            or (a.PlayerName == b.PlayerName and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) > (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())))
            or (a.PlayerName == b.PlayerName and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) > (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())))
        end 
    }, 
    { 
        ["Name"] = "Rare High", 
        ["Callback"] = function(a, b) 
            return (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText()))  > (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) 
               or ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) >  (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())))
               or ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) >  (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())))
               or ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) == (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) and a.PlayerName > b.PlayerName)
        end 
    }, 
    { 
        ["Name"] = "Rare Low", 
        ["Callback"] = function(a, b) 
            return (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText()))  < (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) 
               or ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) <  (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())))
               or ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) <  (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())))
               or ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) == (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) and a.PlayerName < b.PlayerName)
        end 
    }, 
    { 
        ["Name"] = "Tier High", 
        ["Callback"] = function(a, b) 
            return (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText()))  > (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) 
               or ((tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) >  (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())))
               or ((tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) >  (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())))
               or ((tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) == (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) and a.PlayerName > b.PlayerName)
        end 
    }, 
    { 
        ["Name"] = "Tier Low", 
        ["Callback"] = function(a, b) 
            return (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText()))  < (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) 
               or ((tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) <  (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())))
               or ((tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) <  (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())))
               or ((tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText())) == (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText())) and (tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) == (tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) and (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) == (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) and a.PlayerName < b.PlayerName)
        end 
    }, 
    { 
        ["Name"] = "Normal High", 
        ["Callback"] = function(a, b) 
            return (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText()))  > (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) 
               or ((tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) == (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) and ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) + (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText()))) > ((tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) + (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText()))))
               or ((tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) == (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) and ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) + (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText()))) == ((tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) + (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText()))) and a.PlayerName > b.PlayerName)
        end 
    }, 
    { 
        ["Name"] = "Normal Low", 
        ["Callback"] = function(a, b) 
            return (tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText()))  < (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) 
               or ((tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) == (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) and ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) + (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText()))) < ((tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) + (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText()))))
               or ((tonumber(a.NormalText:GetText()) + tonumber(a.NormalDiffText:GetText())) == (tonumber(b.NormalText:GetText()) + tonumber(b.NormalDiffText:GetText())) and ((tonumber(a.RareText:GetText()) + tonumber(a.RareDiffText:GetText())) + (tonumber(a.TierText:GetText()) + tonumber(a.TierDiffText:GetText()))) == ((tonumber(b.RareText:GetText()) + tonumber(b.RareDiffText:GetText())) + (tonumber(b.TierText:GetText()) + tonumber(b.TierDiffText:GetText()))) and a.PlayerName < b.PlayerName)
        end 
    }, 
}

-----------------------------------------------------------------------------------------------------------------------
-- Check if Dialog is Shown
-----------------------------------------------------------------------------------------------------------------------
local function IsDialogShown()
    for k, v in pairs(widgets.Dialogs) do
        if v.Frame:IsShown() then
            return true
        end
    end
    return false
end

-----------------------------------------------------------------------------------------------------------------------
-- Check if value is in Array
-----------------------------------------------------------------------------------------------------------------------
local function IsInArray(array, value)
    for _, v in pairs(array) do
        if (v - value) == 0 then
            return true
        end
    end
    return false
end

-----------------------------------------------------------------------------------------------------------------------
-- Check if Roll is Shown
-----------------------------------------------------------------------------------------------------------------------
local function IsRollShown()
    return widgets.Dialogs.Roll.Frame:IsShown()
end

-----------------------------------------------------------------------------------------------------------------------
-- Split String on Seperator
-----------------------------------------------------------------------------------------------------------------------
local function SplitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-----------------------------------------------------------------------------------------------------------------------
-- Get item id from item link
-----------------------------------------------------------------------------------------------------------------------
local function GetIdFromLink(itemLink)
    local match = SplitString(itemLink, ":")
    return match[2]
end

-----------------------------------------------------------------------------------------------------------------------
-- Check if Player is Already Known
-----------------------------------------------------------------------------------------------------------------------
local function PlayerKnown(player, setup)
    for k, v in pairs(setup.Players) do
        if v.PlayerName == player then
            return true
        end
    end
    return false
end

-----------------------------------------------------------------------------------------------------------------------
-- Create String from Array
-----------------------------------------------------------------------------------------------------------------------
local function ArrayToString(array)
    local first = true
    local str= ""
    for _, v in pairs(array) do
        if not first then
            str = str .. ", "
        end
        str = str .. v 
        first = false
    end
    return str
end

-----------------------------------------------------------------------------------------------------------------------
-- Get a List of All Unregistered Units
-----------------------------------------------------------------------------------------------------------------------
local function GetUnregisteredPlayers(setup)
    local names = {}
    local player_name, realm = UnitFullName("player")
    if PlayerKnown(player_name.."-"..realm, setup) == false then
        table.insert(names, { ["Name"] = player_name.."-"..realm, ["Class"] = select(2, UnitClass(player_name))})
    end
    if IsInRaid() then
        for i=0,40 do
            if UnitExists("raid"..i) then
                local unit_name, unit_realm = UnitName("raid"..i)
                if PlayerKnown(unit_name.."-"..(unit_realm or realm), setup) == false then
                    local fullName = unit_name
                    if unit_realm then
                        fullName = fullName .. "-" .. unit_realm
                    end
                    table.insert(names, { ["Name"] = unit_name.."-"..(unit_realm or realm), ["Class"] = select(2, UnitClass(fullName))})
                end
            end
        end
    elseif IsInGroup() then
        for i=0, 5 do
            if UnitExists("party"..i) then
                local unit_name, unit_realm = UnitName("party"..i)
                if PlayerKnown(unit_name.."-"..(unit_realm or realm), setup) == false then
                    local fullName = unit_name
                    if unit_realm then
                        fullName = fullName .. "-" .. unit_realm
                    end
                    table.insert(names, { ["Name"] = unit_name.."-"..(unit_realm or realm), ["Class"] = select(2, UnitClass(fullName))})
                end
            end
        end
    end
    return names
end

-----------------------------------------------------------------------------------------------------------------------
-- Create Button
-----------------------------------------------------------------------------------------------------------------------
local function CreateButton(parent, label, width, height, colorBackground, colorBorder, textColor)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    button:SetBackdropColor(colorBackground.r, colorBackground.g, colorBackground.b, colorBackground.a)
    button:SetBackdropBorderColor(colorBorder.r, colorBorder.g, colorBorder.b, colorBorder.a)

    local buttonText = button:CreateFontString(nil, "ARTWORK")
    buttonText:SetPoint("CENTER")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 12, "BOLD")
    if textColor then
        buttonText:SetTextColor(textColor.r, textColor.g, textColor.b)
    else
        buttonText:SetTextColor(1, 0.8, 0) 
    end
    buttonText:SetText(label)

    button:SetSize(width, height)
    button:SetFontString(buttonText)

    return button, buttonText 
end

-----------------------------------------------------------------------------------------------------------------------
-- Create Line
-----------------------------------------------------------------------------------------------------------------------
local function CreateLine(width, parent, x, y, colour)
    local line = parent:CreateTexture(nil, "ARTWORK")
    local c = colour or color.Gold
    line:SetColorTexture(c.r, c.g, c.b) -- set the color of the line to white
    line:SetHeight(1) -- set the height of the line
    line:SetWidth(width)
    line:SetPoint("TOPLEFT", x, y)
    return line
end

-----------------------------------------------------------------------------------------------------------------------
-- Create Label 
-----------------------------------------------------------------------------------------------------------------------
local function CreateLabel(label, parent, x, y, colour, anchor, fontSize)
    local c = colour or color.Gold
    local labelString = parent:CreateFontString(nil, "ARTWORK")
    labelString:SetFont("Fonts\\FRIZQT__.TTF", fontSize or 12, "NONE")
    labelString:SetTextColor(c.r, c.g, c.b)
    labelString:SetText(label)
    if x ~= nil and y ~= nil then
        labelString:SetPoint(anchor or "TOPLEFT", x, y)
    end
    return labelString
end

-----------------------------------------------------------------------------------------------------------------------
-- Create Heading
-----------------------------------------------------------------------------------------------------------------------
local function CreateHeading(label, width, parent, x, y, noLine, fontSize)
    local labelString = CreateLabel(label, parent, x, y, color.Gold, nil, fontSize)
    local labelWidth = labelString:GetWidth()
    local lineWidth = (width - labelWidth - 10) * 0.5
    local yOffset = ((fontSize or 12) - 12) / 2

    labelString:SetPoint("TOPLEFT", x + lineWidth + 5, y)

    if not noLine then
        local leftLine = CreateLine(lineWidth, parent, x, y - 5 - yOffset, color.White)
        local rightLine = CreateLine(lineWidth, parent, x + lineWidth + labelWidth + 10, y - 5 - yOffset, color.White)
        return leftLine, labelString, rightLine
    end

    return labelString
end

-----------------------------------------------------------------------------------------------------------------------
-- Create Heading
-----------------------------------------------------------------------------------------------------------------------
function HandleLootAssignment() 
    -- If summary is active, wait until closed
    if widgets.Summary.Frame:IsShown() then
        return
    end
    -- If items are ready to be rolled
    if #widgets.Dialogs.Roll.Items > 0 then
        -- If items is actively rolled on, roll dialog is shown, skip for now
        if widgets.Dialogs.Roll.ActiveItemLink then
            return
        end
        for k, v in pairs(widgets.Dialogs.Roll.Items) do
            -- Update Item Icon
            widgets.Dialogs.Roll.ActiveItemLink = v
            local itemTexture = select(10, GetItemInfo(widgets.Dialogs.Roll.ActiveItemLink))
            local itemId = GetIdFromLink(widgets.Dialogs.Roll.ActiveItemLink)

            if IsInArray(addonDB.Options.TierItems, itemId) then
                widgets.Dialogs.Roll.Tier.Button.pushed = true
                widgets.Dialogs.Roll.Tier.Button:Disable()
                widgets.Dialogs.Roll.TypeSelection = "Tier"
                widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
            elseif IsInArray(addonDB.Options.RareItems, itemId) then
                widgets.Dialogs.Roll.Rare.Button.pushed = true
                widgets.Dialogs.Roll.Rare.Button:Disable()
                widgets.Dialogs.Roll.TypeSelection = "Rare"
                widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
            else
                widgets.Dialogs.Roll.Normal.Button.pushed = true
                widgets.Dialogs.Roll.Normal.Button:Disable()
                widgets.Dialogs.Roll.TypeSelection = "Normal"
                widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
            end

            widgets.Dialogs.Roll.ItemTexture:SetTexture(itemTexture)
            widgets.Dialogs.Roll.ItemIcon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(widgets.Dialogs.Roll.ActiveItemLink)
                GameTooltip:Show()
            end)
            widgets.Dialogs.Roll.ItemIcon:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            table.remove(widgets.Dialogs.Roll.Items, k)

            -- Show Roll Frame
            if not widgets.Addon:IsShown() then
                widgets.Addon:Show()
            end
            if not widgets.Dialogs.Roll.Frame:IsShown() then
                widgets.Dialogs.Roll.Frame:Show()
            end
            break
        end
    else
        if widgets.Dialogs.Roll.Frame:IsShown() then
            widgets.Dialogs.Roll.Frame:Hide()
        end
        if #widgets.Dialogs.Roll.AssignmentList > 0 then
            local yOffset = -30
            for _, assignment in pairs(widgets.Dialogs.Roll.AssignmentList) do
                local item = nil
                -- Setup items in summary view
                if #widgets.Summary.FreeItems > 0 then
                    for k, v in pairs(widgets.Summary.FreeItems) do
                        item = v
                        table.remove(widgets.Summary.FreeItems, k)
                        break
                    end
                else
                    item = {}

                    -- Setup frame
                    item.Frame = CreateFrame("Frame", nil, widgets.Summary.Frame, "BackdropTemplate")
                    item.Frame:SetSize(widgets.Summary.Frame:GetWidth() - 20, 84)
                    item.Frame:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 2,
                    })
                    item.Frame:SetBackdropColor(0, 0, 0, 1)
                    item.Frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

                    -- Setup item icon
                    item.ItemIcon = CreateFrame("Frame", nil, item.Frame, "BackdropTemplate")
                    item.ItemIcon:SetSize(64, 64)
                    item.ItemIcon:SetPoint("TOPLEFT", 40, -10)
                    item.ItemIcon:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 2,
                    })
                    item.ItemIcon:SetBackdropColor(0, 0, 0, 1)
                    item.ItemIcon:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

                    item.ItemTexture = item.ItemIcon:CreateTexture(nil, "ARTWORK")
                    item.ItemTexture:SetAllPoints()

                    -- Setup Player Label
                    item.PlayerLabel = CreateLabel("", item.Frame, 150, 0, color.Gold, "LEFT", 14)

                    -- Insert
                    table.insert(widgets.Summary.Items, item)
                end

                -- Update frame
                item.Frame:Show()

                -- Update icon
                local itemTexture = select(10, GetItemInfo(assignment.ItemLink))
                item.ItemTexture:SetTexture(itemTexture)
                item.ItemIcon:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(assignment.ItemLink)
                    GameTooltip:Show()
                end)
                widgets.Dialogs.Roll.ItemIcon:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                -- Update Player Label
                item.PlayerLabel:SetText(assignment.PlayerName)
                local c = classColor[assignment.Class]
                item.PlayerLabel:SetTextColor(c.r, c.g, c.b, c.a)

                -- Update position
                item.Frame:SetPoint("TOPLEFT", 10, yOffset)
                yOffset = yOffset - 86
            end
            widgets.Summary.Frame:SetHeight(-yOffset + 50)
            
            if widgets.Addon:IsShown() then
                widgets.Summary.Frame:ClearAllPoints()
                widgets.Summary.Frame:SetPoint("TOPLEFT", widgets.Addon, "TOPRIGHT", 10, 0)
            else
                widgets.Summary.Frame:ClearAllPoints()
                widgets.Summary.Frame:SetPoint("CENTER", 0, 0)
            end
            widgets.Summary.Frame:Show()
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Function to Create a Player Row Frame for the Table View
-----------------------------------------------------------------------------------------------------------------------
local function CreatePlayerFrame(player, config, setup, widgets, parent, playerInfo, width, x, y)
    -------------------------------------------------------------------------------------------------------------------
    -- Setup Locals
    -------------------------------------------------------------------------------------------------------------------
    local colorBackground, colorBorder = color.DarkGray, color.LightGray
    local name, colour, rare, tier, normal = playerInfo.Name, classColor[playerInfo.Class], playerInfo.Rare, playerInfo.Tier, playerInfo.Normal

    player.PlayerName = name

    -------------------------------------------------------------------------------------------------------------------
    -- Create Player Container
    -------------------------------------------------------------------------------------------------------------------
    if player.Container == nil then
        player.Container = CreateFrame("Button", nil, parent, "BackdropTemplate")
        player.Container:SetWidth(width)
        player.Container:SetHeight(34)
        player.Container:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
        player.Container:SetBackdropColor(colorBackground.r, colorBackground.g, colorBackground.b, colorBackground.a)
        player.Container:SetBackdropBorderColor(colorBorder.r, colorBorder.g, colorBorder.b, colorBorder.a)
    end
    player.Container:SetPoint("TOPLEFT", x, y)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Remove Button
    -------------------------------------------------------------------------------------------------------------------
    if player.Remove == nil then
        player.Remove = {}
        player.Remove.Button, player.Remove.Text = CreateButton(player.Container, "X", 30, 28, color.DarkGray, color.DarkGray, color.Gold)
        player.Remove.Button:SetPoint("TOPLEFT", 15, -3)
        player.Remove.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.Remove.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end
    player.Remove.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        for k, v in pairs(setup.Players) do
            if v == player then
                v.Container:Hide()
                -- Remove player from config
                for idx, p in pairs(config.PlayerInfos) do
                    if v.PlayerName == p.Name then
                        table.remove(config.PlayerInfos, idx)
                        break
                    end
                end
                -- Move entry to storage for later reuse
                table.insert(widgets.FreePlayers, v)
                table.remove(setup.Players, k)
                -- Rearrange frames
                local vOffset = 0
                for p, q in pairs(setup.Players) do
                    q.Container:SetPoint("TOPLEFT", 0, vOffset)
                    vOffset = vOffset - 32
                end
                setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)
                break
            end
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Player Name Label 
    -------------------------------------------------------------------------------------------------------------------
    if player.NameText then
        player.NameText:SetText(name)
        player.NameText:SetTextColor(colour.r, colour.g, colour.b)
    else
        player.NameText = CreateLabel(name, player.Container, 75, -10, colour)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Rare Count Label
    -------------------------------------------------------------------------------------------------------------------
    if player.RareText then
        player.RareText:SetText(rare)
    else
        player.RareText = CreateLabel(rare, player.Container, 450, -10, color.White)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Rare Diff Label
    -------------------------------------------------------------------------------------------------------------------
    if player.RareDiffText then
        player.RareDiffText:SetText(0)
    else
        player.RareDiffText = CreateLabel(0, player.Container, 510, -10, color.White)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Rare Add Button
    -------------------------------------------------------------------------------------------------------------------
    if player.RareAdd == nil then
        player.RareAdd = {}
        player.RareAdd.Button, player.RareAdd.Text = CreateButton(player.Container, "Add", 50, 28, color.DarkGray, color.DarkGray, color.Gold)
        player.RareAdd.Button:SetPoint("TOPLEFT", 560, -3)
        player.RareAdd.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.RareAdd.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end
    player.RareAdd.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        local num = tonumber(player.RareDiffText:GetText()) + 1
        if num > 0 then
            local g = color.Green
            player.RareDiffText:SetText("+" .. num)
            player.RareDiffText:SetTextColor(g.r, g.g, g.b)
        elseif num < 0 then
            local r = color.Red
            player.RareDiffText:SetText(num)
            player.RareDiffText:SetTextColor(r.r, r.g, r.b)
        else
            local r = color.White
            player.RareDiffText:SetText(0)
            player.RareDiffText:SetTextColor(r.r, r.g, r.b)
        end
        -- Update order if active
        local activeOrder = nil
        for name, orderBtn in pairs(setup.Order) do
            if orderBtn.Button.pushed then
                for _, order in pairs(orderConfigs) do
                    if order.Name == name then
                        activeOrder = order
                        break
                    end
                end
                break
            end
        end
        if activeOrder then
            table.sort(setup.Players, activeOrder["Callback"])
            local vOffset = 0

            local sortedOrder = {}
            for i, player in pairs(setup.Players) do
                sortedOrder[player.PlayerName] = i
                player.Container:SetPoint("TOPLEFT", 0, vOffset)
                vOffset = vOffset - 32
            end
            setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

            for k, config in pairs(configs) do
                if config.Name == setup.Name then
                    table.sort(config["PlayerInfos"], function(a, b)
                        return sortedOrder[a.Name] < sortedOrder[b.Name]
                    end)
                    break
                end
            end
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Rare Remove Button
    -------------------------------------------------------------------------------------------------------------------
    if player.RareRemove == nil then
        player.RareRemove = {}
        player.RareRemove.Button, player.RareRemove.Text = CreateButton(player.Container, "Remove", 80, 28, color.DarkGray, color.DarkGray, color.Gold)
        player.RareRemove.Button:SetPoint("TOPLEFT", 620, -3)
        player.RareRemove.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.RareRemove.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end
    player.RareRemove.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        local num = tonumber(player.RareDiffText:GetText()) - 1
        local n = tonumber(player.RareText:GetText())
        if n + num < 0 then
            num = -n
        end
        if num > 0 then
            local g = color.Green
            player.RareDiffText:SetText("+" .. num)
            player.RareDiffText:SetTextColor(g.r, g.g, g.b)
        elseif num < 0 then
            local r = color.Red
            player.RareDiffText:SetText(num)
            player.RareDiffText:SetTextColor(r.r, r.g, r.b)
        else
            local r = color.White
            player.RareDiffText:SetText(0)
            player.RareDiffText:SetTextColor(r.r, r.g, r.b)
        end
        -- Update order if active
        local activeOrder = nil
        for name, orderBtn in pairs(setup.Order) do
            if orderBtn.Button.pushed then
                for _, order in pairs(orderConfigs) do
                    if order.Name == name then
                        activeOrder = order
                        break
                    end
                end
                break
            end
        end
        if activeOrder then
            table.sort(setup.Players, activeOrder["Callback"])
            local vOffset = 0

            local sortedOrder = {}
            for i, player in pairs(setup.Players) do
                sortedOrder[player.PlayerName] = i
                player.Container:SetPoint("TOPLEFT", 0, vOffset)
                vOffset = vOffset - 32
            end
            setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

            for k, config in pairs(configs) do
                if config.Name == setup.Name then
                    table.sort(config["PlayerInfos"], function(a, b)
                        return sortedOrder[a.Name] < sortedOrder[b.Name]
                    end)
                    break
                end
            end
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Tier Count Label
    -------------------------------------------------------------------------------------------------------------------
    if player.TierText then
        player.TierText:SetText(tier)
    else
        player.TierText = CreateLabel(tier, player.Container, 755, -10, color.White)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Tier Diff Label
    -------------------------------------------------------------------------------------------------------------------
    if player.TierDiffText then
        player.TierDiffText:SetText(0)
    else
        player.TierDiffText = CreateLabel(0, player.Container, 815, -10, color.White)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Tier Add Button
    -------------------------------------------------------------------------------------------------------------------
    if player.TierAdd == nil then
        player.TierAdd = {}
        player.TierAdd.Button, player.TierAdd.Text = CreateButton(player.Container, "Add", 50, 28, color.DarkGray, color.DarkGray, color.Gold)
        player.TierAdd.Button:SetPoint("TOPLEFT", 865, -3)
        player.TierAdd.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.TierAdd.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end
    player.TierAdd.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        local num = tonumber(player.TierDiffText:GetText()) + 1
        if num > 0 then
            local g = color.Green
            player.TierDiffText:SetText("+" .. num)
            player.TierDiffText:SetTextColor(g.r, g.g, g.b)
        elseif num < 0 then
            local r = color.Red
            player.TierDiffText:SetText(num)
            player.TierDiffText:SetTextColor(r.r, r.g, r.b)
        else
            local r = color.White
            player.TierDiffText:SetText(0)
            player.TierDiffText:SetTextColor(r.r, r.g, r.b)
        end
        -- Update order if active
        local activeOrder = nil
        for name, orderBtn in pairs(setup.Order) do
            if orderBtn.Button.pushed then
                for _, order in pairs(orderConfigs) do
                    if order.Name == name then
                        activeOrder = order
                        break
                    end
                end
                break
            end
        end
        if activeOrder then
            table.sort(setup.Players, activeOrder["Callback"])
            local vOffset = 0

            local sortedOrder = {}
            for i, player in pairs(setup.Players) do
                sortedOrder[player.PlayerName] = i
                player.Container:SetPoint("TOPLEFT", 0, vOffset)
                vOffset = vOffset - 32
            end
            setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

            for k, config in pairs(configs) do
                if config.Name == setup.Name then
                    table.sort(config["PlayerInfos"], function(a, b)
                        return sortedOrder[a.Name] < sortedOrder[b.Name]
                    end)
                    break
                end
            end
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Tier Remove Button
    -------------------------------------------------------------------------------------------------------------------
    if player.TierRemove == nil then
        player.TierRemove = {}
        player.TierRemove.Button, player.TierRemove.Text = CreateButton(player.Container, "Remove", 80, 28, color.DarkGray, color.DarkGray, color.Gold)
        player.TierRemove.Button:SetPoint("TOPLEFT", 925, -3)
        player.TierRemove.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.TierRemove.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end
    player.TierRemove.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        local num = tonumber(player.TierDiffText:GetText()) - 1
        local n = tonumber(player.TierText:GetText())
        if n + num < 0 then
            num = -n
        end
        if num > 0 then
            local g = color.Green
            player.TierDiffText:SetText("+" .. num)
            player.TierDiffText:SetTextColor(g.r, g.g, g.b)
        elseif num < 0 then
            local r = color.Red
            player.TierDiffText:SetText(num)
            player.TierDiffText:SetTextColor(r.r, r.g, r.b)
        else
            local r = color.White
            player.TierDiffText:SetText(0)
            player.TierDiffText:SetTextColor(r.r, r.g, r.b)
        end
        -- Update order if active
        local activeOrder = nil
        for name, orderBtn in pairs(setup.Order) do
            if orderBtn.Button.pushed then
                for _, order in pairs(orderConfigs) do
                    if order.Name == name then
                        activeOrder = order
                        break
                    end
                end
                break
            end
        end
        if activeOrder then
            table.sort(setup.Players, activeOrder["Callback"])
            local vOffset = 0

            local sortedOrder = {}
            for i, player in pairs(setup.Players) do
                sortedOrder[player.PlayerName] = i
                player.Container:SetPoint("TOPLEFT", 0, vOffset)
                vOffset = vOffset - 32
            end
            setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

            for k, config in pairs(configs) do
                if config.Name == setup.Name then
                    table.sort(config["PlayerInfos"], function(a, b)
                        return sortedOrder[a.Name] < sortedOrder[b.Name]
                    end)
                    break
                end
            end
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Normal Count Label
    -------------------------------------------------------------------------------------------------------------------
    if player.NormalText then
        player.NormalText:SetText(normal)
    else
        player.NormalText = CreateLabel(normal, player.Container, 1060, -10, color.White)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Normal Diff Label
    -------------------------------------------------------------------------------------------------------------------
    if player.NormalDiffText then
        player.NormalDiffText:SetText(0)
    else
        player.NormalDiffText = CreateLabel(0, player.Container, 1120, -10, color.White)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Normal Add Button
    -------------------------------------------------------------------------------------------------------------------
    if player.NormalAdd == nil then
        player.NormalAdd = {}
        player.NormalAdd.Button, player.NormalAdd.Text = CreateButton(player.Container, "Add", 50, 28, color.DarkGray, color.DarkGray, color.Gold)
        player.NormalAdd.Button:SetPoint("TOPLEFT", 1170, -3)
        player.NormalAdd.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.NormalAdd.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end
    player.NormalAdd.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        local num = tonumber(player.NormalDiffText:GetText()) + 1
        if num > 0 then
            local g = color.Green
            player.NormalDiffText:SetText("+" .. num)
            player.NormalDiffText:SetTextColor(g.r, g.g, g.b)
        elseif num < 0 then
            local r = color.Red
            player.NormalDiffText:SetText(num)
            player.NormalDiffText:SetTextColor(r.r, r.g, r.b)
        else
            local r = color.White
            player.NormalDiffText:SetText(0)
            player.NormalDiffText:SetTextColor(r.r, r.g, r.b)
        end
        -- Update order if active
        local activeOrder = nil
        for name, orderBtn in pairs(setup.Order) do
            if orderBtn.Button.pushed then
                for _, order in pairs(orderConfigs) do
                    if order.Name == name then
                        activeOrder = order
                        break
                    end
                end
                break
            end
        end
        if activeOrder then
            table.sort(setup.Players, activeOrder["Callback"])
            local vOffset = 0

            local sortedOrder = {}
            for i, player in pairs(setup.Players) do
                sortedOrder[player.PlayerName] = i
                player.Container:SetPoint("TOPLEFT", 0, vOffset)
                vOffset = vOffset - 32
            end
            setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

            for k, config in pairs(configs) do
                if config.Name == setup.Name then
                    table.sort(config["PlayerInfos"], function(a, b)
                        return sortedOrder[a.Name] < sortedOrder[b.Name]
                    end)
                    break
                end
            end
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Normal Remove Button
    -------------------------------------------------------------------------------------------------------------------
    if player.NormalRemove == nil then
        player.NormalRemove = {}
        player.NormalRemove.Button, player.NormalRemove.Text = CreateButton(player.Container, "Remove", 80, 28, color.DarkGray, color.DarkGray, color.Gold)
        player.NormalRemove.Button:SetPoint("TOPLEFT", 1230, -3)
        player.NormalRemove.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.NormalRemove.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end
    player.NormalRemove.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        local num = tonumber(player.NormalDiffText:GetText()) - 1
        local n = tonumber(player.NormalText:GetText())
        if n + num < 0 then
            num = -n
        end
        if num > 0 then
            local g = color.Green
            player.NormalDiffText:SetText("+" .. num)
            player.NormalDiffText:SetTextColor(g.r, g.g, g.b)
        elseif num < 0 then
            local r = color.Red
            player.NormalDiffText:SetText(num)
            player.NormalDiffText:SetTextColor(r.r, r.g, r.b)
        else
            local r = color.White
            player.NormalDiffText:SetText(0)
            player.NormalDiffText:SetTextColor(r.r, r.g, r.b)
        end
        -- Update order if active
        local activeOrder = nil
        for name, orderBtn in pairs(setup.Order) do
            if orderBtn.Button.pushed then
                for _, order in pairs(orderConfigs) do
                    if order.Name == name then
                        activeOrder = order
                        break
                    end
                end
                break
            end
        end
        if activeOrder then
            table.sort(setup.Players, activeOrder["Callback"])
            local vOffset = 0

            local sortedOrder = {}
            for i, player in pairs(setup.Players) do
                sortedOrder[player.PlayerName] = i
                player.Container:SetPoint("TOPLEFT", 0, vOffset)
                vOffset = vOffset - 32
            end
            setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

            for k, config in pairs(configs) do
                if config.Name == setup.Name then
                    table.sort(config["PlayerInfos"], function(a, b)
                        return sortedOrder[a.Name] < sortedOrder[b.Name]
                    end)
                    break
                end
            end
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Return Player Container
    -------------------------------------------------------------------------------------------------------------------
    return player
end

-----------------------------------------------------------------------------------------------------------------------
-- Create Right Mouse Click Menu Frame
-----------------------------------------------------------------------------------------------------------------------
widgets.RightMouseClickTabMenu = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")

-----------------------------------------------------------------------------------------------------------------------
-- Create Addon Window
-----------------------------------------------------------------------------------------------------------------------
widgets.Addon = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Addon:SetFrameStrata("HIGH")
widgets.Addon:SetSize(1600, 1000)
widgets.Addon:SetMovable(true)
widgets.Addon:EnableMouse(true)
widgets.Addon:RegisterForDrag("LeftButton")
widgets.Addon:SetScript("OnDragStart", widgets.Addon.StartMoving)
widgets.Addon:SetScript("OnDragStop", widgets.Addon.StopMovingOrSizing)
widgets.Addon:SetPoint("CENTER")
widgets.Addon:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Addon:SetBackdropColor(0, 0, 0, 1)
widgets.Addon:SetBackdropBorderColor(0, 0, 0, 1)

-----------------------------------------------------------------------------------------------------------------------
-- Create Tab Scroll
-----------------------------------------------------------------------------------------------------------------------
widgets.TabScroll = CreateFrame("ScrollFrame", nil, widgets.Addon, "UIPanelScrollFrameTemplate, BackdropTemplate")
widgets.TabScroll:SetPoint("TOPLEFT", 6, -6)
widgets.TabScroll:SetPoint("BOTTOMRIGHT", widgets.Addon, "BOTTOMLEFT", 200, 6 + 100)
widgets.TabScroll:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.TabScroll:SetBackdropColor(0, 0, 0, 1)
widgets.TabScroll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

-----------------------------------------------------------------------------------------------------------------------
-- Create Tab Content And Insert Into Tab Scroll
-----------------------------------------------------------------------------------------------------------------------
widgets.TabContent = CreateFrame("Frame", nil, widgets.TabScroll)
widgets.TabContent:SetWidth(400)
widgets.TabContent:SetHeight(1)
widgets.TabScroll:SetScrollChild(widgets.TabContent)

-----------------------------------------------------------------------------------------------------------------------
-- Create CreatedBy Label
-----------------------------------------------------------------------------------------------------------------------
widgets.CreatedBy = widgets.Addon:CreateFontString(nil, "ARTWORK")
widgets.CreatedBy:SetPoint("BOTTOMLEFT", 10, 6)
widgets.CreatedBy:SetFont("Fonts\\FRIZQT__.TTF", 12, "NONE")
widgets.CreatedBy:SetTextColor(1, 0.8, 0) -- set the color to golden
widgets.CreatedBy:SetText("Created by " .. author)

-----------------------------------------------------------------------------------------------------------------------
-- Create Content Frame
-----------------------------------------------------------------------------------------------------------------------
widgets.Content = CreateFrame("Frame", nil, widgets.Addon, "BackdropTemplate")
widgets.Content:SetPoint("TOPLEFT", 227, -6)
widgets.Content:SetPoint("BOTTOMRIGHT", -6, 6)
widgets.Content:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Content:SetBackdropColor(0, 0, 0, 1)
widgets.Content:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

-----------------------------------------------------------------------------------------------------------------------
-- Create Close Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Close = {}
widgets.Close.Button, widgets.Close.Text = CreateButton(widgets.Content, "Close", 102, 35, color.DarkGray, color.LightGray)
widgets.Close.Button:SetPoint("BOTTOMRIGHT", widgets.Content, "BOTTOMRIGHT", -10, 10)
widgets.Close.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Close.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Close.Button:SetScript("OnClick", function(self)
    if IsDialogShown() then
        return
    end
    if widgets.Addon:IsShown() then
        widgets.Addon:Hide()
    else
        widgets.Addon:Show()
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Save Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Save = {}
widgets.Save.Button, widgets.Save.Text = CreateButton(widgets.Content, "Save", 102, 35, color.DarkGray, color.LightGray)
widgets.Save.Button:SetPoint("BOTTOMRIGHT", widgets.Content, "BOTTOMRIGHT", -122, 10)
widgets.Save.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Save.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Save.Button:SetScript("OnClick", function(self)
    if IsDialogShown() then
        return
    end

    local config = nil
    local setup = nil
    for k, v in pairs(widgets.Setups) do 
        if v.Tab.Button.pushed then
            setup = v
            break
        end
    end
    for k, v in pairs(configs) do
        if setup.Name == v.Name then
            config = v
        end
    end

    for _, player in pairs(setup.Players) do
        for _, info in pairs(config.PlayerInfos) do
            if player.PlayerName == info.Name then
                info.Rare = info.Rare + tonumber(player.RareDiffText:GetText())
                info.Tier = info.Tier + tonumber(player.TierDiffText:GetText())
                info.Normal = info.Normal + tonumber(player.NormalDiffText:GetText())

                player.RareText:SetText(info.Rare)
                player.TierText:SetText(info.Tier)
                player.NormalText:SetText(info.Normal)
                player.RareDiffText:SetText(0)
                player.TierDiffText:SetText(0)
                player.NormalDiffText:SetText(0)
                player.RareDiffText:SetTextColor(color.White.r, color.White.g, color.White.b)
                player.TierDiffText:SetTextColor(color.White.r, color.White.g, color.White.b)
                player.NormalDiffText:SetTextColor(color.White.r, color.White.g, color.White.b)
                break
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Export Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Export = {}
widgets.Export.Button, widgets.Export.Text = CreateButton(widgets.Content, "Export", 102, 35, color.DarkGray, color.LightGray)
widgets.Export.Button:SetPoint("BOTTOMLEFT", widgets.Content, "BOTTOMLEFT", 10, 10)
widgets.Export.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Export.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Export.Button:SetScript("OnClick", function(self)
    if IsDialogShown() then
        return
    end

    for k, v in pairs(widgets.Setups) do
        if v.Tab.Button.pushed then
            for h, c in pairs(configs) do
                if c.Name == v.Name then
                    local serialized = LibSerialize:SerializeEx({errorOnUnserializableType = false}, c)
                    local compressed = LibDeflate:CompressDeflate(serialized)
                    local encoded = LibDeflate:EncodeForPrint(compressed)
                    widgets.Dialogs.Export.InputField:SetMaxLetters(0)
                    widgets.Dialogs.Export.InputField:SetText(encoded)
                    widgets.Dialogs.Export.Frame:Show()
                end
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Print Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Print = {}
widgets.Print.Button, widgets.Print.Text = CreateButton(widgets.Content, "Print", 102, 35, color.DarkGray, color.LightGray)
widgets.Print.Button:SetPoint("BOTTOMLEFT", widgets.Export.Button, "BOTTOMRIGHT", 10, 0)
widgets.Print.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Print.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Print.Button:SetScript("OnClick", function(self)
    if IsDialogShown() then
        return
    end

    local content =  ""
    content = content .. "+------------------------------------------+-------+-------+--------+\n" 
    content = content .. "| Character Name                           | Rares | Tiers | Normal |\n"
    for k, v in pairs(widgets.Setups) do
        if v.Tab.Button.pushed then
            for h, c in pairs(configs) do
                if c.Name == v.Name then
                    for _, playerInfo in pairs(c.PlayerInfos) do
                        local _, count = string.gsub(playerInfo.Name, '[^\128-\193]', '')
                        content = content .. "+------------------------------------------+-------+-------+--------+\n"
                        content = content .. "| " .. playerInfo.Name .. Ws(39 - count) .. " | " .. string.format("%5d", playerInfo.Rare)  .. " | " .. string.format("%5d", playerInfo.Tier) .. " | " .. string.format("%6d", playerInfo.Normal) .. " |\n"
                    end
                end
            end
        end
    end
    content = content .. "+------------------------------------------+-------+-------+--------+\n"

    widgets.Dialogs.Print.EditBox:SetText(content)
    widgets.Dialogs.Print.Frame:Show()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Function to Create a New Raid Content Frame from Configuration
-----------------------------------------------------------------------------------------------------------------------
local function SetupNewEntry(cfg, show)
    -------------------------------------------------------------------------------------------------------------------
    -- Setup Local
    -------------------------------------------------------------------------------------------------------------------
    local name = cfg.Name
    local setup = nil

    local characterWidth = 350
    local countWidth = 300

    -------------------------------------------------------------------------------------------------------------------
    -- Create Content Table or Retrieve Previously Freed Table
    -------------------------------------------------------------------------------------------------------------------
    if widgets.FreeSetups and #widgets.FreeSetups > 0 then
        for k, v in pairs(widgets.FreeSetups) do
            setup = v
            table.remove(widgets.FreeSetups, k)
            break
        end
    else
        setup = {}
    end
    table.insert(setups, setup)

    -------------------------------------------------------------------------------------------------------------------
    -- Setup Name
    -------------------------------------------------------------------------------------------------------------------
    setup.Name = name

    -------------------------------------------------------------------------------------------------------------------
    -- Create Content Container
    -------------------------------------------------------------------------------------------------------------------
    if setup.Content == nil then
        setup.Content = CreateFrame("Frame", nil, widgets.Content)
        setup.Content:SetPoint("TOPLEFT", 0, 0)
        setup.Content:SetPoint("BOTTOMRIGHT", 0, 0)
    end
    local setupWidth = setup.Content:GetWidth()

    -------------------------------------------------------------------------------------------------------------------
    -- Create Order Heading
    -------------------------------------------------------------------------------------------------------------------
    if setup.OrderHeading == nil then
        setup.OrderHeading = {}
        setup.OrderHeading.LeftLine, setup.OrderHeading.Label, setup.OrderHeading.RightLine = CreateHeading("ORDERING", setupWidth - 20, setup.Content, 10, -10)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create all Order Button
    -------------------------------------------------------------------------------------------------------------------
    setup.Order = setup.Order or {}
    local order = setup.Order
    local offsetX = 0
    for orderIdx, orderCfg in pairs(orderConfigs) do
        local orderName = orderCfg.Name

        ---------------------------------------------------------------------------------------------------------------
        -- Create Order Button
        ---------------------------------------------------------------------------------------------------------------
        if order[orderName] == nil then
            order[orderName] = {}
            order[orderName]["Button"], order[orderName]["Text"] = CreateButton(setup.Content, orderName, 150, 40, color.DarkGray, color.LightGray)
        end
        local orderButton, text = order[orderName]["Button"], order[orderName]["Text"]
        orderButton.pushed = false
        orderButton:Enable()
        orderButton:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, color.DarkGray.a)
        orderButton:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, color.LightGray.a)
        orderButton:SetPoint("TOPLEFT", 20 + offsetX, -30)
        orderButton:SetScript("OnEnter", function(self)
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end)
        orderButton:SetScript("OnLeave", function(self)
            if self.pushed then
                local c = color.Gold
                self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            else
                local c = color.LightGray
                self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            end
        end)
        orderButton:SetScript("OnClick", function(self)
            if IsDialogShown() and not IsRollShown() then
                return
            end
            -- Set orderButton active and update order
            self.pushed = true
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            self:Disable()

            -- Update order
            table.sort(setup.Players, orderConfigs[orderIdx]["Callback"])
            local vOffset = 0

            local sortedOrder = {}
            for i, player in pairs(setup.Players) do
                sortedOrder[player.PlayerName] = i
                player.Container:SetPoint("TOPLEFT", 0, vOffset)
                vOffset = vOffset - 32
            end
            setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

            for k, config in pairs(configs) do
                if config.Name == setup.Name then
                    table.sort(config["PlayerInfos"], function(a, b)
                        return sortedOrder[a.Name] < sortedOrder[b.Name]
                    end)
                    break
                end
            end

            for _, s in pairs(widgets.Setups) do
                if s.Name == name then
                    -- Set all other orderButton inactive
                    for k, v in pairs(s["Order"]) do
                        if orderName ~= k then
                            local cl = color.LightGray
                            v.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
                            v.Button.pushed = false
                            v.Button:Enable()
                        end
                    end
                    break
                end
            end
        end)

        ---------------------------------------------------------------------------------------------------------------
        -- Update Offset For Next Button
        ---------------------------------------------------------------------------------------------------------------
        offsetX = offsetX + 165
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Table Scroll Container
    -------------------------------------------------------------------------------------------------------------------
    if setup.TableScrollContainer == nil then
        setup.TableScrollContainer = CreateFrame("Frame", nil, setup.Content, "BackdropTemplate")
        setup.TableScrollContainer:SetPoint("TOPLEFT", 10, -80)
        setup.TableScrollContainer:SetPoint("BOTTOMRIGHT", -6, 50)
        setup.TableScrollContainer:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
        setup.TableScrollContainer:SetBackdropColor(0, 0, 0, 1)
        setup.TableScrollContainer:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Heading Line of Delete Button Column
    -------------------------------------------------------------------------------------------------------------------
    local btnHeadingWidth = 40
    if setup.BtnHeadingLine == nil then
        setup.BtnHeadingLine = CreateLine(btnHeadingWidth, setup.TableScrollContainer, 10, -15, color.White)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Character Name Column Heading
    -------------------------------------------------------------------------------------------------------------------
    if setup.CharacterHeading == nil then
        setup.CharacterHeading = {}
        setup.CharacterHeading.LeftLine, setup.CharacterHeading.Label, setup.CharacterHeading.RightLine = CreateHeading("NAME", characterWidth, setup.TableScrollContainer, 15 + btnHeadingWidth, -10)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Rare Column Heading
    -------------------------------------------------------------------------------------------------------------------
    if setup.RareHeading == nil then
        setup.RareHeading = {}
        setup.RareHeading.LeftLine, setup.RareHeading.Label, setup.RareHeading.RightLine = CreateHeading("RARE", countWidth, setup.TableScrollContainer, 20 + btnHeadingWidth + characterWidth, -10)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Tier Column Heading
    -------------------------------------------------------------------------------------------------------------------
    if setup.TierHeading == nil then
        setup.TierHeading = {}
        setup.TierHeading.LeftLine, setup.TierHeading.Label, setup.TierHeading.RightLine = CreateHeading("TIER", countWidth, setup.TableScrollContainer, 25 + countWidth + btnHeadingWidth + characterWidth, -10)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Normal Column Heading
    -------------------------------------------------------------------------------------------------------------------
    if setup.NormalHeading == nil then
        setup.NormalHeading = {}
        setup.NormalHeading.LeftLine, setup.NormalHeading.Label, setup.NormalHeading.RightLine = CreateHeading("NORMAL", countWidth, setup.TableScrollContainer, 30 + countWidth * 2 + btnHeadingWidth + characterWidth, -10)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Table Scroll Widget
    -------------------------------------------------------------------------------------------------------------------
    if setup.TableScroll == nil then
        setup.TableScroll = CreateFrame("ScrollFrame", nil, setup.TableScrollContainer, "UIPanelScrollFrameTemplate")
        setup.TableScroll:SetPoint("TOPLEFT", 0, -25)
        setup.TableScroll:SetPoint("BOTTOMRIGHT", -27, 5)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Table Scroll Content Widget
    -------------------------------------------------------------------------------------------------------------------
    if setup.Table == nil then
        setup.Table = CreateFrame("Frame")
        setup.Table:SetWidth(setup.TableScroll:GetWidth())
        setup.Table:SetHeight(1)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Player Row Frames for All Existing Players
    -------------------------------------------------------------------------------------------------------------------
    local vOffset = 0
    setup.Players = setup.Players or {}
    for _, playerInfo in pairs(cfg.PlayerInfos or {}) do
        local player = {}
        for fk, fv in pairs(widgets.FreePlayers) do 
            player = fv
            player.Container:Show()
            player.Container:SetParent(setup.Table)
            table.remove(widgets.FreePlayers, fk)
            break
        end
        CreatePlayerFrame(player, cfg, setup, widgets, setup.Table, playerInfo, setup.Table:GetWidth(), 0, vOffset)
        table.insert(setup.Players, player)
        vOffset = vOffset - 32
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Bottom Line
    -------------------------------------------------------------------------------------------------------------------
    if setup.TableBottomLine == nil then
        setup.TableBottomLine = CreateLine(setup.Table:GetWidth() - 10, setup.Table, 5, vOffset + 2, color.DarkGray)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Assign Table to Table Scroll
    -------------------------------------------------------------------------------------------------------------------
    setup.TableScroll:SetScrollChild(setup.Table)
    
    -------------------------------------------------------------------------------------------------------------------
    -- Assign Tab Button
    -------------------------------------------------------------------------------------------------------------------
    if setup.Tab == nil then
        setup.Tab = {}
        setup.Tab.Button, setup.Tab.Text = CreateButton(widgets.TabContent, name, 188, 40, color.DarkGray, color.LightGray)
    else
        setup.Tab.Button:SetText(name)
        setup.Tab.Button:Show()
    end
    local button, text = setup.Tab.Button, setup.Tab.Text
    button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    button:SetScript("OnLeave", function(self)
        if self.pushed then
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        else
            local c = color.LightGray
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end
    end)
    button:SetScript("OnMouseDown", function(self, button)
        if IsDialogShown() then
            return 
        end
        if button == "RightButton" then
            -----------------------------------------------------------------------------------------------------------
            -- Create Right Mouse Click Menu
            -----------------------------------------------------------------------------------------------------------
            local rightMouseClickMenuItems = {}
            if addonDB.Tracking.Active and addonDB.Tracking.Name == setup.Name then
                local item = {
                    text = "Stop Tracking", 
                    func = function() 
                        local name = setup.Name
                        addonDB.Tracking.Active = false 
                        addonDB.Tracking.Name = nil 
                        for k, v in pairs(setups) do
                            if v.Name == name then
                                local c = color.DarkGray
                                v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
                                break
                            end
                        end
                    end
                }
                table.insert(rightMouseClickMenuItems, item);
            else
                local item = {
                    text = "Start Tracking", 
                    func = function() 
                        local name = setup.Name
                        for k, v in pairs(setups) do
                            if v.Name == name then
                                local c = color.Highlight
                                v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
                            else
                                local c = color.DarkGray
                                v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
                            end
                        end
                        addonDB.Tracking.Active = true
                        addonDB.Tracking.Name = name
                    end
                }
                table.insert(rightMouseClickMenuItems, item);
            end
            local rename = {
                text = "Rename...", 
                func = function() 
                    local name = setup.Name
                    widgets.Dialogs.Rename.InputField.currentName = name
                    widgets.Dialogs.Rename.Frame:Show()
                end
            }
            table.insert(rightMouseClickMenuItems, rename);
            local delete = {
                text = "Delete",
                func = function()
                    local name = setup.Name
                    -- Stop tracking if name matches
                    if addonDB.Tracking.Active and addonDB.Tracking.Name == name then
                        for k, v in pairs(setups) do
                            if v.Name == name then
                                local c = color.DarkGray
                                v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
                                break
                            end
                        end
                        addonDB.Tracking.Name = nil
                        addonDB.Tracking.Active = false
                    end
                    -- Remove 
                    for k, v in pairs(configs) do
                        if v.Name == name then
                            table.remove(configs, k)
                            break
                        end
                    end
                    for k, v in pairs(setups) do
                        if v.Name == name then
                            -- Free all player frames
                            for ek, ev in pairs(v.Players) do 
                                ev.Container:Hide()
                                table.insert(widgets.FreePlayers, ev)
                            end
                            v.Players = {}
                            -- Hide Tab button
                            v.Tab.Button:Hide()
                            -- Free setup
                            table.insert(widgets.FreeSetups, v)
                            table.remove(setups, k)
                            -- Rearrange visible tab buttons
                            local i = 0
                            for ek, ev in pairs(setups) do
                                ev.Tab.Button:SetPoint("TOPLEFT", 3, -3 - 42 * i)
                                i = i + 1
                            end
                            -- Hide freed setup if visible
                            if v.Content:IsShown() then
                                v.Content:Hide()
                                -- Show another frame if available
                                for ek, ev in pairs(setups) do
                                    local c = color.Gold
                                    ev.Tab.Button.pushed = true
                                    ev.Tab.Button:Disable()
                                    ev.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                                    ev.Content:Show()
                                    break
                                end
                            end
                            break
                        end
                    end
                end
            }
            table.insert(rightMouseClickMenuItems, delete)
            EasyMenu(rightMouseClickMenuItems, widgets.RightMouseClickTabMenu, "cursor", 0, 0, "MENU", 1)
        else
            -----------------------------------------------------------------------------------------------------------
            -- Activate Tab and Show Its Content
            -----------------------------------------------------------------------------------------------------------
            self.pushed = true
            self:Disable()
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            for _, s in pairs(widgets.Setups) do
                if s.Name == self:GetText() then
                    s.Content:Show()
                    break
                end
            end

            -----------------------------------------------------------------------------------------------------------
            -- Hide All Other Content
            -----------------------------------------------------------------------------------------------------------
            for _, s in pairs(widgets.Setups) do
                if s.Name ~= self:GetText() then
                    local cl = color.LightGray
                    s.Tab.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
                    s.Tab.Button.pushed = false
                    s.Tab.Button:Enable()
                    s.Content:Hide()
                end
            end
        end
    end)
    button:SetPoint("TOPLEFT", 3, -3 - 42 * (#setups - 1))

    -------------------------------------------------------------------------------------------------------------------
    -- Show Or Hide The Newly Created Frame Based On Argument
    -------------------------------------------------------------------------------------------------------------------
    if show then
        button.pushed = true
        local c = color.Gold
        button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        setup.Content:Show()
    else
        setup.Content:Hide()
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Return Player Table
    -------------------------------------------------------------------------------------------------------------------
    return setup
end

-----------------------------------------------------------------------------------------------------------------------
-- Options Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Options = {}
widgets.Dialogs.Options.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.Options.Frame:SetSize(650, 600)
widgets.Dialogs.Options.Frame:SetMovable(true)
widgets.Dialogs.Options.Frame:EnableMouse(true)
widgets.Dialogs.Options.Frame:RegisterForDrag("LeftButton")
widgets.Dialogs.Options.Frame:SetScript("OnDragStart", widgets.Addon.StartMoving)
widgets.Dialogs.Options.Frame:SetScript("OnDragStop", widgets.Addon.StopMovingOrSizing)
widgets.Dialogs.Options.Frame:SetPoint("CENTER", widgets.Addon, "CENTER", 0, 0)
widgets.Dialogs.Options.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Options.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Options.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.Options.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.Options.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Options Dialog: Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Options.Header = CreateHeading("OPTIONS", widgets.Dialogs.Options.Frame:GetWidth() - 10, widgets.Dialogs.Options.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- Options Dialog: Close Button 
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Options.Close = {}
widgets.Dialogs.Options.Close.Button, widgets.Dialogs.Options.Close.Text = CreateButton(widgets.Dialogs.Options.Frame, "Close", 102, 28, color.DarkGray, color.LightGray)
widgets.Dialogs.Options.Close.Button:SetPoint("BOTTOMRIGHT", widgets.Dialogs.Options.Frame, "BOTTOMRIGHT", -10, 10)
widgets.Dialogs.Options.Close.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Options.Close.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Options.Close.Button:SetScript("OnClick", function(self)
    widgets.Dialogs.Options.Frame:Hide()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Options Dialog: Tier Identifier Inputfield
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Options.TierIdInputField = CreateFrame("EditBox", nil, widgets.Dialogs.Options.Frame, "InputBoxTemplate")
widgets.Dialogs.Options.TierIdInputField:SetWidth(widgets.Dialogs.Options.Frame:GetWidth() - 60)
widgets.Dialogs.Options.TierIdInputField:SetHeight(30)
widgets.Dialogs.Options.TierIdInputField:SetPoint("TOP", widgets.Dialogs.Options.Frame, "TOP", 0, -50)
widgets.Dialogs.Options.TierIdInputField:SetAutoFocus(false)
widgets.Dialogs.Options.TierIdInputField:SetMaxLetters(0)
widgets.Dialogs.Options.TierIdInputField:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
widgets.Dialogs.Options.TierIdInputField:SetScript("OnTextChanged", function(self) 
    local c = color.White
    self:SetTextColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Options.TierIdInputField:SetScript("OnEnterPressed", function(self) 
    local text = widgets.Dialogs.Options.TierIdInputField:GetText()
    local split = SplitString(text, ",")
    local numbers = {}
    for _, v in pairs(split) do
        local num = tonumber(v)
        if not num then
            local c = color.Red
            widgets.Dialogs.Options.TierIdInputField:SetTextColor(c.r, c.g, c.b, c.a)
            return
        end
        table.insert(numbers, num)
    end
    addonDB.Options.TierItems = numbers
end)
widgets.Dialogs.Options.TierIdInputField:SetScript("OnEscapePressed", function(self) 
    self:SetText(ArrayToString(addonDB.Options.TierItems))
end)

-----------------------------------------------------------------------------------------------------------------------
-- Options Dialog: Tier Identifier Label 
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Options.TierIdLabel = CreateLabel("Tier Identifiers:", widgets.Dialogs.Options.Frame, nil, nil, color.Gold)
widgets.Dialogs.Options.TierIdLabel:SetPoint("BOTTOMLEFT", widgets.Dialogs.Options.TierIdInputField, "TOPLEFT", 10, 0)

-----------------------------------------------------------------------------------------------------------------------
-- Options Dialog: Tier Identifier Inputfield
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Options.RareIdInputField = CreateFrame("EditBox", nil, widgets.Dialogs.Options.Frame, "InputBoxTemplate")
widgets.Dialogs.Options.RareIdInputField:SetWidth(widgets.Dialogs.Options.Frame:GetWidth() - 60)
widgets.Dialogs.Options.RareIdInputField:SetHeight(30)
widgets.Dialogs.Options.RareIdInputField:SetPoint("TOP", widgets.Dialogs.Options.Frame, "TOP", 0, -100)
widgets.Dialogs.Options.RareIdInputField:SetAutoFocus(false)
widgets.Dialogs.Options.RareIdInputField:SetMaxLetters(0)
widgets.Dialogs.Options.RareIdInputField:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
widgets.Dialogs.Options.RareIdInputField:SetScript("OnTextChanged", function(self) 
    local c = color.White
    self:SetTextColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Options.RareIdInputField:SetScript("OnEnterPressed", function(self) 
    local text = widgets.Dialogs.Options.RareIdInputField:GetText()
    local split = SplitString(text, ",")
    local numbers = {}
    for _, v in pairs(split) do
        local num = tonumber(v)
        if not num then
            local c = color.Red
            widgets.Dialogs.Options.RareIdInputField:SetTextColor(c.r, c.g, c.b, c.a)
            return
        end
        table.insert(numbers, num)
    end
    addonDB.Options.RareItems = numbers
end)
widgets.Dialogs.Options.RareIdInputField:SetScript("OnEscapePressed", function(self) 
    self:SetText(ArrayToString(addonDB.Options.RareItems))
end)

-----------------------------------------------------------------------------------------------------------------------
-- Options Dialog: Rare Identifier Label 
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Options.RareIdLabel = CreateLabel("Rare Identifiers:", widgets.Dialogs.Options.Frame, nil, nil, color.Gold)
widgets.Dialogs.Options.RareIdLabel:SetPoint("BOTTOMLEFT", widgets.Dialogs.Options.RareIdInputField, "TOPLEFT", 10, 0)

-----------------------------------------------------------------------------------------------------------------------
-- Print Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Print = {}
widgets.Dialogs.Print.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.Print.Frame:SetSize(650, 600)
widgets.Dialogs.Print.Frame:SetMovable(true)
widgets.Dialogs.Print.Frame:EnableMouse(true)
widgets.Dialogs.Print.Frame:RegisterForDrag("LeftButton")
widgets.Dialogs.Print.Frame:SetScript("OnDragStart", widgets.Addon.StartMoving)
widgets.Dialogs.Print.Frame:SetScript("OnDragStop", widgets.Addon.StopMovingOrSizing)
widgets.Dialogs.Print.Frame:SetPoint("CENTER")
widgets.Dialogs.Print.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Print.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Print.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.Print.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.Print.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Print Dialog: Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Print.Header = CreateHeading("PRINT", widgets.Dialogs.Print.Frame:GetWidth() - 10, widgets.Dialogs.Print.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- Print Dialog: Scroll Area 
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Print.Scroll = CreateFrame("ScrollFrame", nil, widgets.Dialogs.Print.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
widgets.Dialogs.Print.Scroll:SetPoint("TOPLEFT", 6, -30)
widgets.Dialogs.Print.Scroll:SetPoint("BOTTOMRIGHT", widgets.Dialogs.Print.Frame, "BOTTOMRIGHT", -27, 40)
widgets.Dialogs.Print.Scroll:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Print.Scroll:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Print.Scroll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
widgets.Dialogs.Print.Scroll:SetClipsChildren(true)

-----------------------------------------------------------------------------------------------------------------------
-- Print Dialog: EditBox
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Print.EditBox = CreateFrame("EditBox", nil, widgets.Dialogs.Print.Scroll)
widgets.Dialogs.Print.EditBox:SetMultiLine(true)
widgets.Dialogs.Print.EditBox:SetFontObject("ChatFontNormal")
widgets.Dialogs.Print.EditBox:SetWidth(widgets.Dialogs.Print.Scroll:GetWidth())
widgets.Dialogs.Print.EditBox:SetAutoFocus(false)
widgets.Dialogs.Print.EditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

widgets.Dialogs.Print.Scroll:SetScrollChild(widgets.Dialogs.Print.EditBox)

-----------------------------------------------------------------------------------------------------------------------
-- Print Dialog: Close Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Print.Close = {}
widgets.Dialogs.Print.Close.Button, widgets.Dialogs.Print.Close.Text = CreateButton(widgets.Dialogs.Print.Frame, "Close", 102, 28, color.DarkGray, color.LightGray)
widgets.Dialogs.Print.Close.Button:SetPoint("BOTTOMRIGHT", widgets.Dialogs.Print.Frame, "BOTTOMRIGHT", -10, 10)
widgets.Dialogs.Print.Close.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Print.Close.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Print.Close.Button:SetScript("OnClick", function(self)
    widgets.Dialogs.Print.Frame:Hide()
    widgets.Dialogs.Print.EditBox:SetText("")
end)

-----------------------------------------------------------------------------------------------------------------------
-- Rename Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Rename = {}
widgets.Dialogs.Rename.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.Rename.Frame:SetFrameStrata("HIGH")
widgets.Dialogs.Rename.Frame:SetSize(250, 90)
widgets.Dialogs.Rename.Frame:SetMovable(false)
widgets.Dialogs.Rename.Frame:SetPoint("CENTER")
widgets.Dialogs.Rename.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Rename.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Rename.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.Rename.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.Rename.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Rename Dialog: Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Rename.Header = CreateHeading("RENAME", widgets.Dialogs.Rename.Frame:GetWidth() - 10, widgets.Dialogs.Rename.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- Rename Dialog: Escape Label 
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Rename.Escape = CreateLabel("<ESC>: Cancel", widgets.Dialogs.Rename.Frame, 10, 10, color.White, "BOTTOMLEFT")

-----------------------------------------------------------------------------------------------------------------------
-- Rename Dialog: Enter Label 
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Rename.Enter = CreateLabel("<ENTER>: Confirm", widgets.Dialogs.Rename.Frame, -10, 10, color.White, "BOTTOMRIGHT")

-----------------------------------------------------------------------------------------------------------------------
-- Rename Dialog: Inputfield
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Rename.InputField = CreateFrame("EditBox", nil, widgets.Dialogs.Rename.Frame, "InputBoxTemplate")
widgets.Dialogs.Rename.InputField:SetWidth(widgets.Dialogs.Rename.Frame:GetWidth() - 30)
widgets.Dialogs.Rename.InputField:SetHeight(30)
widgets.Dialogs.Rename.InputField:SetPoint("TOPLEFT", widgets.Dialogs.Rename.Frame, "TOPLEFT", 17, -30)
widgets.Dialogs.Rename.InputField:SetAutoFocus(true)
widgets.Dialogs.Rename.InputField:SetMaxLetters(25)
widgets.Dialogs.Rename.InputField:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
widgets.Dialogs.Rename.InputField:SetScript("OnTextChanged", function(self) 
    local input = self:GetText()
    if #input > 0 then
        -- Check if name already taken
        for k, v in pairs(configs) do
            if v.Name == input and self.currentName ~= v.Name then
                self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
                return
            end
        end
        self:SetTextColor(color.White.r, color.White.g, color.White.b)
    end
end)
widgets.Dialogs.Rename.InputField:SetScript("OnEnterPressed", function(self) 
    local input = self:GetText()
    if #input > 0 then
        if input ~= self.currentName then
            -- Check if name already taken
            for k, v in pairs(configs) do
                if v.Name == input then
                    return
                end
            end

            if self.config then
                self.config.Name = input
                self.currentName = self.config.Name
                -- Hide other setups since new tab is activated by default
                for k, v in pairs(setups) do
                    if v.Name ~= self.currentName then
                        v.Content:Hide()
                        v.Tab.Button.pushed = false
                        local c = color.LightGray
                        v.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                    end
                end
                -- Insert and setup new entry
                table.insert(configs, self.config)
                SetupNewEntry(self.config, true)
            else
                for k, v in pairs(configs) do
                    if v.Name == self.currentName then
                        v.Name = input
                        break
                    end
                end
                for k, v in pairs(widgets.Setups) do
                    if v.Name == self.currentName then
                        v.Name = input
                        v.Tab.Text:SetText(input)
                        break
                    end
                end
            end
            -- Update tracking raid name 
            if addonDB.Tracking.Active and addonDB.Tracking.Name == self.currentName then
                addonDB.Tracking.Name = input
            end
        end
        widgets.Dialogs.Rename.Frame:Hide()
        widgets.Dialogs.Rename.Escape:Show()
        self.currentName = nil
        self.config = nil
        self:SetText("")
    end
end)
widgets.Dialogs.Rename.InputField:SetScript("OnEscapePressed", function(self) 
    if widgets.Dialogs.Rename.Frame:IsShown() and widgets.Dialogs.Rename.Escape:IsShown() then
        self:SetText("")
        self.currentName = nil
        widgets.Dialogs.Rename.Frame:Hide()
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Export Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Export = {}
widgets.Dialogs.Export.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.Export.Frame:SetSize(250, 90)
widgets.Dialogs.Export.Frame:SetMovable(false)
widgets.Dialogs.Export.Frame:SetPoint("CENTER")
widgets.Dialogs.Export.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Export.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Export.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.Export.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.Export.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Export Dialog: Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Export.Header = CreateHeading("EXPORT", widgets.Dialogs.Export.Frame:GetWidth() - 10, widgets.Dialogs.Export.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- Export Dialog: Escape Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Export.Escape = CreateLabel("<ESC>: Close", widgets.Dialogs.Export.Frame, 0, 10, color.White, "BOTTOM")

-----------------------------------------------------------------------------------------------------------------------
-- Export Dialog: InputField
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Export.InputField = CreateFrame("EditBox", nil, widgets.Dialogs.Export.Frame, "InputBoxTemplate")
widgets.Dialogs.Export.InputField:SetWidth(widgets.Dialogs.Export.Frame:GetWidth() - 30)
widgets.Dialogs.Export.InputField:SetHeight(30)
widgets.Dialogs.Export.InputField:SetPoint("TOPLEFT", widgets.Dialogs.Export.Frame, "TOPLEFT", 17, -30)
widgets.Dialogs.Export.InputField:SetAutoFocus(true)
widgets.Dialogs.Export.InputField:SetMaxLetters(0)
widgets.Dialogs.Export.InputField:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
widgets.Dialogs.Export.InputField:SetScript("OnEscapePressed", function(self) 
    if widgets.Dialogs.Export.Frame:IsShown() then
        self:SetText("")
        widgets.Dialogs.Export.Frame:Hide()
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Conflict Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Conflict = {}
widgets.Dialogs.Conflict.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.Conflict.Frame:SetSize(250, 80)
widgets.Dialogs.Conflict.Frame:SetMovable(false)
widgets.Dialogs.Conflict.Frame:SetPoint("CENTER")
widgets.Dialogs.Conflict.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Conflict.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Conflict.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.Conflict.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.Conflict.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Conflict Dialog: Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Conflict.Header = CreateHeading("NAME CONFLICT", widgets.Dialogs.Conflict.Frame:GetWidth() - 10, widgets.Dialogs.Conflict.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- Conflict Dialog: Update Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Conflict.Update = {}
widgets.Dialogs.Conflict.Update.Button, widgets.Dialogs.Conflict.Update.Text = CreateButton(widgets.Dialogs.Conflict.Frame, "Update", 102, 35, color.DarkGray, color.LightGray, color.Gold)
widgets.Dialogs.Conflict.Update.Button:SetPoint("TOPLEFT", widgets.Dialogs.Conflict.Frame, "TOPLEFT", 15, -30)
widgets.Dialogs.Conflict.Update.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Conflict.Update.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Conflict.Update.Button:SetScript("OnClick", function(self)
    -- Clear previously existing
    for k, v in pairs(configs) do
        if v.Name == widgets.Dialogs.Conflict.config.Name then
            table.remove(configs, k)
            break
        end
    end
    for k, v in pairs(setups) do
        if v.Name == widgets.Dialogs.Conflict.config.Name then
            -- Free all player frames
            for ek, ev in pairs(v.Players) do 
                ev.Container:Hide()
                table.insert(widgets.FreePlayers, ev)
            end
            v.Players = {}
            -- Hide Tab button
            v.Tab.Button:Hide()
            -- Free setup
            table.insert(widgets.FreeSetups, v)
            table.remove(setups, k)
            -- Rearrange visible tab buttons
            local i = 0
            for ek, ev in pairs(setups) do
                ev.Tab.Button:SetPoint("TOPLEFT", 3, -3 - 42 * i)
                i = i + 1
            end
            -- Hide freed setup if visible
            if v.Content:IsShown() then
                v.Content:Hide()
            end
            break
        end
    end
    -- Hide other setups since new tab is activated by default
    for k, v in pairs(setups) do
        if v.Name ~= widgets.Dialogs.Conflict.config.Name then
            v.Content:Hide()
            v.Tab.Button.pushed = false
            local c = color.LightGray
            v.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end
    end
    -- Insert and setup new entry
    table.insert(configs, widgets.Dialogs.Conflict.config)
    SetupNewEntry(widgets.Dialogs.Conflict.config, true)

    widgets.Dialogs.Conflict.config = nil
    widgets.Dialogs.Conflict.Frame:Hide()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Conflict Dialog: Rename Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Conflict.Rename = {}
widgets.Dialogs.Conflict.Rename.Button, widgets.Dialogs.Conflict.Rename.Text = CreateButton(widgets.Dialogs.Conflict.Frame, "Rename", 102, 35, color.DarkGray, color.LightGray, color.Gold)
widgets.Dialogs.Conflict.Rename.Button:SetPoint("TOPRIGHT", widgets.Dialogs.Conflict.Frame, "TOPRIGHT", -15, -30)
widgets.Dialogs.Conflict.Rename.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Conflict.Rename.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Conflict.Rename.Button:SetScript("OnClick", function(self)
    widgets.Dialogs.Rename.InputField.config = widgets.Dialogs.Conflict.config
    widgets.Dialogs.Rename.Escape:Hide()
    widgets.Dialogs.Rename.Frame:Show()

    widgets.Dialogs.Conflict.config = nil
    widgets.Dialogs.Conflict.Frame:Hide()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Import Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Import = {}
widgets.Dialogs.Import.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.Import.Frame:SetSize(250, 90)
widgets.Dialogs.Import.Frame:SetMovable(false)
widgets.Dialogs.Import.Frame:SetPoint("CENTER")
widgets.Dialogs.Import.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Import.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Import.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.Import.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.Import.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Import Dialog: Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Import.Header = CreateHeading("IMPORT", widgets.Dialogs.Import.Frame:GetWidth() - 10, widgets.Dialogs.Import.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- Import Dialog: Escape Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Import.Escape = CreateLabel("<ESC>: Cancel", widgets.Dialogs.Import.Frame, 10, 10, color.White, "BOTTOMLEFT")

-----------------------------------------------------------------------------------------------------------------------
-- Import Dialog: Enter Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Import.Enter = CreateLabel("<ENTER>: Confirm", widgets.Dialogs.Import.Frame, -10, 10, color.White, "BOTTOMRIGHT")

-----------------------------------------------------------------------------------------------------------------------
-- Import Dialog: InputField
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Import.InputField = CreateFrame("EditBox", nil, widgets.Dialogs.Import.Frame, "InputBoxTemplate")
widgets.Dialogs.Import.InputField:SetWidth(widgets.Dialogs.Import.Frame:GetWidth() - 30)
widgets.Dialogs.Import.InputField:SetHeight(30)
widgets.Dialogs.Import.InputField:SetPoint("TOPLEFT", widgets.Dialogs.Import.Frame, "TOPLEFT", 17, -30)
widgets.Dialogs.Import.InputField:SetAutoFocus(true)
widgets.Dialogs.Import.InputField:SetMaxLetters(0)
widgets.Dialogs.Import.InputField:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
widgets.Dialogs.Import.InputField:SetScript("OnTextChanged", function(self) 
    self:SetTextColor(color.White.r, color.White.g, color.White.b)
end)
widgets.Dialogs.Import.InputField:SetScript("OnEnterPressed", function(self) 
    local input = self:GetText()
    if #input > 0 then
        -- Deserialize
        local encoded = self:GetText()
        local compressed = LibDeflate:DecodeForPrint(encoded)
        local serialized = LibDeflate:DecompressDeflate(compressed)
        local success, deserialized = LibSerialize:Deserialize(serialized)
        -- Change to red if unsuccessful
        if not success then
            self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
            return
        end
        -- Hide frame and reset for next time
        widgets.Dialogs.Import.Frame:Hide()
        self:SetText("")
        -- Check if config would override
        for k, v in pairs(configs) do
            if v.Name == deserialized.Name then
                widgets.Dialogs.Conflict.config = deserialized
                widgets.Dialogs.Conflict.Frame:Show()
                return
            end
        end
        -- Hide other setups since new tab is activated by default
        for k, v in pairs(setups) do
            if v.Name ~= deserialized.Name then
                v.Content:Hide()
                v.Tab.Button.pushed = false
                local c = color.LightGray
                v.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            end
        end
        -- Insert and setup new entry
        table.insert(configs, deserialized)
        SetupNewEntry(deserialized, true)
    end
end)
widgets.Dialogs.Import.InputField:SetScript("OnEscapePressed", function(self) 
    if widgets.Dialogs.Import.Frame:IsShown() then
        self:SetText("")
        widgets.Dialogs.Import.Frame:Hide()
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Activate Raid Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.ActivateRaid = {}
widgets.Dialogs.ActivateRaid.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.ActivateRaid.Frame:SetSize(350, 130)
widgets.Dialogs.ActivateRaid.Frame:SetMovable(false)
widgets.Dialogs.ActivateRaid.Frame:SetPoint("TOP", 0, -200)
widgets.Dialogs.ActivateRaid.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.ActivateRaid.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.ActivateRaid.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.ActivateRaid.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.ActivateRaid.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Activate Raid Dialog: Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.ActivateRaid.Header = CreateHeading("RAID TABLES", widgets.Dialogs.ActivateRaid.Frame:GetWidth() - 20, widgets.Dialogs.ActivateRaid.Frame, 5, -10, false, 14)

-----------------------------------------------------------------------------------------------------------------------
-- Activate Raid Dialog: Label 
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.ActivateRaid.Label = CreateLabel("Start tracking by " .. addonName .. " for this group?", widgets.Dialogs.ActivateRaid.Frame, 0, -35, color.White, "TOP", 14)
widgets.Dialogs.ActivateRaid.Label:SetWidth(widgets.Dialogs.ActivateRaid.Frame:GetWidth() - 20)

-----------------------------------------------------------------------------------------------------------------------
-- Activate Raid Dialog: Raid Selection
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.ActivateRaid.RaidSelection = CreateFrame("Frame", nil, widgets.Dialogs.ActivateRaid.Frame, "UIDropDownMenuTemplate")
widgets.Dialogs.ActivateRaid.RaidSelection:SetPoint("CENTER", widgets.Dialogs.ActivateRaid.Frame, "CENTER", 35, -10)
widgets.Dialogs.ActivateRaid.SetupSelection = function()
    addonDB.Tracking.Name = nil
    addonDB.Tracking.Active = false
    UIDropDownMenu_Initialize(widgets.Dialogs.ActivateRaid.RaidSelection, function(self, level)
        for i, setup in pairs(widgets.Setups) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = setup.Name
            info.value = setup.Name
            info.func = function(self) 
                addonDB.Tracking.Name = setup.Name
                UIDropDownMenu_SetSelectedID(widgets.Dialogs.ActivateRaid.RaidSelection, i)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetWidth(widgets.Dialogs.ActivateRaid.RaidSelection, 100)
    UIDropDownMenu_SetButtonWidth(widgets.Dialogs.ActivateRaid.RaidSelection, widgets.Dialogs.ActivateRaid.Frame:GetWidth() - 192)
    for i, setup in pairs(widgets.Setups) do
        if setup.Tab.Button.pushed then
            addonDB.Tracking.Name = setup.Name
            UIDropDownMenu_SetSelectedID(widgets.Dialogs.ActivateRaid.RaidSelection, i)
        end
    end
    UIDropDownMenu_JustifyText(widgets.Dialogs.ActivateRaid.RaidSelection, "CENTER")
end

-----------------------------------------------------------------------------------------------------------------------
-- Activate Raid Dialog: Selection Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.ActivateRaid.SelectionLabel = CreateLabel("Raid Name:", widgets.Dialogs.ActivateRaid.Frame, -60, -8, color.Gold, "CENTER", 12)

-----------------------------------------------------------------------------------------------------------------------
-- Activate Raid Dialog: Yes Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.ActivateRaid.Yes = {}
widgets.Dialogs.ActivateRaid.Yes.Button, widgets.Dialogs.ActivateRaid.Yes.Text = CreateButton(widgets.Dialogs.ActivateRaid.Frame, "YES", 102, 28, color.DarkGray, color.LightGray)
widgets.Dialogs.ActivateRaid.Yes.Button:SetPoint("BOTTOMRIGHT", widgets.Dialogs.ActivateRaid.Frame, "BOTTOMRIGHT", -45, 10)
widgets.Dialogs.ActivateRaid.Yes.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.ActivateRaid.Yes.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.ActivateRaid.Yes.Button:SetScript("OnClick", function(self)
    addonDB.Tracking.Active = true
    for k, v in pairs(setups) do
        if v.Name == addonDB.Tracking.Name then
            local c = color.Highlight
            v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
        else
            local c = color.DarkGray
            v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
        end
    end
    widgets.Dialogs.ActivateRaid.Frame:Hide()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Activate Raid Dialog: No Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.ActivateRaid.No = {}
widgets.Dialogs.ActivateRaid.No.Button, widgets.Dialogs.ActivateRaid.No.Text = CreateButton(widgets.Dialogs.ActivateRaid.Frame, "NO", 102, 28, color.DarkGray, color.LightGray)
widgets.Dialogs.ActivateRaid.No.Button:SetPoint("BOTTOMLEFT", widgets.Dialogs.ActivateRaid.Frame, "BOTTOMLEFT", 45, 10)
widgets.Dialogs.ActivateRaid.No.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.ActivateRaid.No.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.ActivateRaid.No.Button:SetScript("OnClick", function(self)
    addonDB.Tracking.Active = false
    addonDB.Tracking.Name = nil
    widgets.Dialogs.ActivateRaid.Frame:Hide()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create New Raid Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.NewRaid = {}
widgets.Dialogs.NewRaid.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.NewRaid.Frame:SetSize(250, 90)
widgets.Dialogs.NewRaid.Frame:SetMovable(false)
widgets.Dialogs.NewRaid.Frame:SetPoint("CENTER")
widgets.Dialogs.NewRaid.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.NewRaid.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.NewRaid.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.NewRaid.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.NewRaid.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- New Raid Dialog: Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.NewRaid.Header = CreateHeading("NEW RAID", widgets.Dialogs.NewRaid.Frame:GetWidth() - 10, widgets.Dialogs.NewRaid.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- New Raid Dialog: Escape Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.NewRaid.Escape = CreateLabel("<ESC>: Cancel", widgets.Dialogs.NewRaid.Frame, 10, 10, color.White, "BOTTOMLEFT")

-----------------------------------------------------------------------------------------------------------------------
-- New Raid Dialog: Enter Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.NewRaid.Enter = CreateLabel("<ENTER>: Confirm", widgets.Dialogs.NewRaid.Frame, -10, 10, color.White, "BOTTOMRIGHT")

-----------------------------------------------------------------------------------------------------------------------
-- New Raid Dialog: InputField
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.NewRaid.InputField = CreateFrame("EditBox", nil, widgets.Dialogs.NewRaid.Frame, "InputBoxTemplate")
widgets.Dialogs.NewRaid.InputField:SetWidth(widgets.Dialogs.NewRaid.Frame:GetWidth() - 30)
widgets.Dialogs.NewRaid.InputField:SetHeight(30)
widgets.Dialogs.NewRaid.InputField:SetPoint("TOPLEFT", widgets.Dialogs.NewRaid.Frame, "TOPLEFT", 17, -30)
widgets.Dialogs.NewRaid.InputField:SetAutoFocus(true)
widgets.Dialogs.NewRaid.InputField:SetMaxLetters(25)
widgets.Dialogs.NewRaid.InputField:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
widgets.Dialogs.NewRaid.InputField:SetScript("OnTextChanged", function(self) 
    local input = self:GetText()
    if #input > 0 then
        -- Check if name already taken
        for k, v in pairs(configs) do
            if v.Name == input then
                self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
                return
            end
        end
        self:SetTextColor(color.White.r, color.White.g, color.White.b)
    end
end)
widgets.Dialogs.NewRaid.InputField:SetScript("OnEnterPressed", function(self) 
    local input = self:GetText()
    if #input > 0 then
        -- Check if name already taken
        for k, v in pairs(configs) do
            if v.Name == input then
                return
            end
        end
        -- Create new entry
        local entry = { 
            ["Name"] = input,
            ["PlayerInfos"] = {}
        }
        table.insert(configs, entry)
        SetupNewEntry(entry, true)
        -- Hide other setups since new tab is activated by default
        for k, v in pairs(setups) do
            if v.Name ~= entry.Name then
                v.Content:Hide()
                local c = color.LightGray
                v.Tab.Button.pushed = false
                v.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            end
        end
        widgets.Dialogs.NewRaid.Frame:Hide()
        self:SetText("")
    end
end)
widgets.Dialogs.NewRaid.InputField:SetScript("OnEscapePressed", function(self) 
    if widgets.Dialogs.NewRaid.Frame:IsShown() then
        self:SetText("")
        widgets.Dialogs.NewRaid.Frame:Hide()
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Add Players Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers = {}
widgets.Dialogs.AddPlayers.PlayerFrames = {}
widgets.Dialogs.AddPlayers.FreePlayerFrames = {}
widgets.Dialogs.AddPlayers.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.AddPlayers.Frame:SetSize(470, 350)
widgets.Dialogs.AddPlayers.Frame:SetMovable(true)
widgets.Dialogs.AddPlayers.Frame:EnableMouse(true)
widgets.Dialogs.AddPlayers.Frame:RegisterForDrag("LeftButton")
widgets.Dialogs.AddPlayers.Frame:SetScript("OnDragStart", widgets.Addon.StartMoving)
widgets.Dialogs.AddPlayers.Frame:SetScript("OnDragStop", widgets.Addon.StopMovingOrSizing)
widgets.Dialogs.AddPlayers.Frame:SetPoint("CENTER")
widgets.Dialogs.AddPlayers.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.AddPlayers.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.AddPlayers.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.AddPlayers.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.AddPlayers.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers.Header = CreateHeading("ADD PLAYERS", widgets.Dialogs.AddPlayers.Frame:GetWidth() - 10, widgets.Dialogs.AddPlayers.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: Scroll Area
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers.Scroll = CreateFrame("ScrollFrame", nil, widgets.Dialogs.AddPlayers.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
widgets.Dialogs.AddPlayers.Scroll :SetPoint("TOPLEFT", 6, -30)
widgets.Dialogs.AddPlayers.Scroll:SetPoint("BOTTOMRIGHT", widgets.Dialogs.AddPlayers.Frame, "BOTTOMRIGHT", -27, 100)
widgets.Dialogs.AddPlayers.Scroll:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.AddPlayers.Scroll:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.AddPlayers.Scroll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: Scroll View
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers.ScrollView = CreateFrame("Frame", nil, widgets.Dialogs.AddPlayers.Scroll)
widgets.Dialogs.AddPlayers.ScrollView:SetWidth(widgets.Dialogs.AddPlayers.Scroll:GetWidth())
widgets.Dialogs.AddPlayers.ScrollView:SetHeight(1)

widgets.Dialogs.AddPlayers.Scroll:SetScrollChild(widgets.Dialogs.AddPlayers.ScrollView)

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: Add Callback
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers.onAdd = function(self)
    local input = widgets.Dialogs.AddPlayers.InputField:GetText()
    if #input > 0 then
        -- Check if name already taken
        for k, v in pairs(widgets.Dialogs.AddPlayers.PlayerFrames) do
            if v.Name:GetText() == input then
                widgets.Dialogs.AddPlayers.InputField:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
                return
            end
        end
        for k, v in pairs(setups) do
            if v.Tab.Button.pushed then
                for _, player in pairs(v.Players) do
                    if player.PlayerName == input then
                        self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
                        return
                    end
                end
                break
            end
        end
        -- Create frame
        local player = {}
        player.Class = widgets.Dialogs.AddPlayers.ClassSelection.Class
        local c = classColor[widgets.Dialogs.AddPlayers.ClassSelection.Class]
        if #widgets.Dialogs.AddPlayers.FreePlayerFrames > 0 then
            for k, v in pairs(widgets.Dialogs.AddPlayers.FreePlayerFrames) do
                player = v
                player.Container:Show()
                player.Checkbox:SetChecked(true)
                player.Name:SetText(input)
                player.Name:SetTextColor(c.r, c.g, c.b)
                player.Container:SetPoint("TOPLEFT", 10, -10 + -33 * #widgets.Dialogs.AddPlayers.PlayerFrames)
                table.insert(widgets.Dialogs.AddPlayers.PlayerFrames, player)
                table.remove(widgets.Dialogs.AddPlayers.FreePlayerFrames, k)
                widgets.Dialogs.AddPlayers.ScrollView:SetHeight(20 + 33 * #widgets.Dialogs.AddPlayers.PlayerFrames)
                break 
            end
        else
            player.Container = CreateFrame("Frame", nil, widgets.Dialogs.AddPlayers.ScrollView, "BackdropTemplate")
            player.Container:SetWidth(widgets.Dialogs.AddPlayers.ScrollView:GetWidth() - 20)
            player.Container:SetHeight(30)
            player.Container:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
            player.Container:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, color.DarkGray.a)
            player.Container:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, color.LightGray.a)
            player.Container:SetPoint("TOPLEFT", 10, -10 + -33 * #widgets.Dialogs.AddPlayers.PlayerFrames)
            player.Name = CreateLabel(input, player.Container, 100, -9, c)
            player.Checkbox = CreateFrame("CheckButton", nil, player.Container, "ChatConfigCheckButtonTemplate")
            player.Checkbox:SetSize(24, 24)
            player.Checkbox:SetChecked(true)
            player.Checkbox:SetPoint("TOPLEFT", 30, -3)
            table.insert(widgets.Dialogs.AddPlayers.PlayerFrames, player)
            player.Container:SetWidth(widgets.Dialogs.AddPlayers.ScrollView:GetWidth() - 20)
        end
        widgets.Dialogs.AddPlayers.InputField:SetText("")
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: InputField
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers.InputField = CreateFrame("EditBox", nil, widgets.Dialogs.AddPlayers.Frame, "InputBoxTemplate")
widgets.Dialogs.AddPlayers.InputField:SetWidth(200)
widgets.Dialogs.AddPlayers.InputField:SetHeight(40)
widgets.Dialogs.AddPlayers.InputField:SetPoint("BOTTOMLEFT", widgets.Dialogs.AddPlayers.Frame, "BOTTOMLEFT", 18, 40)
widgets.Dialogs.AddPlayers.InputField:SetAutoFocus(false)
widgets.Dialogs.AddPlayers.InputField:SetMaxLetters(0)
widgets.Dialogs.AddPlayers.InputField:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
widgets.Dialogs.AddPlayers.InputField:SetScript("OnTextChanged", function(self) 
    local input = self:GetText()
    if #input > 0 then
        -- Check if name already taken
        for k, v in pairs(widgets.Dialogs.AddPlayers.PlayerFrames) do
            if v.Name:GetText() == input then
                widgets.Dialogs.AddPlayers.InputField:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
                return
            end
        end
        for k, v in pairs(setups) do
            if v.Tab.Button.pushed then
                for _, player in pairs(v.Players) do
                    if player.PlayerName == input then
                        self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
                        return
                    end
                end
                break
            end
        end
        self:SetTextColor(color.White.r, color.White.g, color.White.b)
    end
end)
widgets.Dialogs.AddPlayers.InputField:SetScript("OnEnterPressed", widgets.Dialogs.AddPlayers.onAdd)

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: Input Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers.InputLabel = CreateLabel("Enter Player Name:", widgets.Dialogs.AddPlayers.InputField, 0, 10, color.Gold, "TOPLEFT")

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: Class Color Options
-----------------------------------------------------------------------------------------------------------------------
local classColorOptions = {
    { text = "DEATHKNIGHT", value = "DEATHKNIGHT" },
    { text = "DEMONHUNTER", value = "DEMONHUNTER" },
    { text = "DRUID", value = "DRUID" },
    { text = "EVOKER", value = "EVOKER" },
    { text = "HUNTER", value = "HUNTER" },
    { text = "MAGE", value = "MAGE" },
    { text = "MONK", value = "MONK" },
    { text = "PALADIN", value = "PALADIN" },
    { text = "PRIEST", value = "PRIEST" },
    { text = "ROGUE", value = "ROGUE" },
    { text = "SHAMAN", value = "SHAMAN" },
    { text = "WARLOCK", value = "WARLOCK" },
    { text = "WARRIOR", value = "WARRIOR" },
}

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: Class Selection
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers.ClassSelection = CreateFrame("Frame", nil, widgets.Dialogs.AddPlayers.InputField, "UIDropDownMenuTemplate")
widgets.Dialogs.AddPlayers.ClassSelection:SetPoint("LEFT", widgets.Dialogs.AddPlayers.InputField, "RIGHT", -5, -3)
widgets.Dialogs.AddPlayers.ClassSelection.Class = classColorOptions[1].value
UIDropDownMenu_Initialize(widgets.Dialogs.AddPlayers.ClassSelection, function(self, level)
    for i, option in pairs(classColorOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.text
        info.value = option.value
        info.func = function(self) 
            widgets.Dialogs.AddPlayers.ClassSelection.Class = option.value
            UIDropDownMenu_SetSelectedID(widgets.Dialogs.AddPlayers.ClassSelection, i)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)
UIDropDownMenu_SetWidth(widgets.Dialogs.AddPlayers.ClassSelection, 100)
UIDropDownMenu_SetButtonWidth(widgets.Dialogs.AddPlayers.ClassSelection, 124)
UIDropDownMenu_SetSelectedID(widgets.Dialogs.AddPlayers.ClassSelection, 1)
UIDropDownMenu_JustifyText(widgets.Dialogs.AddPlayers.ClassSelection, "LEFT")

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: Add Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers.Add = {}
widgets.Dialogs.AddPlayers.Add.Button, widgets.Dialogs.AddPlayers.Add.Text = CreateButton(widgets.Dialogs.AddPlayers.Frame, "Add", 102, 28, color.DarkGray, color.LightGray)
widgets.Dialogs.AddPlayers.Add.Button:SetPoint("LEFT", widgets.Dialogs.AddPlayers.ClassSelection, "RIGHT", -5, 2)
widgets.Dialogs.AddPlayers.Add.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.AddPlayers.Add.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.AddPlayers.Add.Button:SetScript("OnClick", widgets.Dialogs.AddPlayers.onAdd)

-----------------------------------------------------------------------------------------------------------------------
-- Add Players Dialog: Confirm Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.AddPlayers.Confirm = {}
widgets.Dialogs.AddPlayers.Confirm.Button, widgets.Dialogs.AddPlayers.Confirm.Text = CreateButton(widgets.Dialogs.AddPlayers.Frame, "Confirm", 102, 28, color.DarkGray, color.LightGray)
widgets.Dialogs.AddPlayers.Confirm.Button:SetPoint("BOTTOMRIGHT", widgets.Dialogs.AddPlayers.Frame, "BOTTOMRIGHT", -10, 10)
widgets.Dialogs.AddPlayers.Confirm.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.AddPlayers.Confirm.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.AddPlayers.Confirm.Button:SetScript("OnClick", function(self)
    -- Create player frames
    for k, setup in pairs(setups) do
        if setup.Tab.Button.pushed then
            local config = nil
            for _, c in pairs(configs) do
                if c.Name == setup.Name then
                    config = c
                    break
                end
            end
            for _, playerFrame in pairs(widgets.Dialogs.AddPlayers.PlayerFrames or {}) do
                if playerFrame.Checkbox:GetChecked() then
                    -- Create new entry
                    local playerInfo = { 
                        ["Name"] = playerFrame.Name:GetText(),
                        ["Rare"] = 0,
                        ["Tier"] = 0,
                        ["Normal"] = 0,
                        ["Class"] = playerFrame.Class
                    }
                    -- Create Player Frame
                    local player = {}
                    for fk, fv in pairs(widgets.FreePlayers) do 
                        player = fv
                        player.Container:Show()
                        player.Container:SetParent(setup.Table)
                        table.remove(widgets.FreePlayers, fk)
                        break
                    end
                    CreatePlayerFrame(player, config, setup, widgets, setup.Table, playerInfo, setup.Table:GetWidth(), 0, #config.PlayerInfos * -32)
                    -- Deactive order button
                    for _, btn in pairs(setup.Order) do
                        btn.Button:Enable()
                        btn.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
                    end
                    -- Insert player data
                    table.insert(setup.Players, player)
                    table.insert(config.PlayerInfos, playerInfo)
                end
            end
        end
    end
    for _, playerFrame in pairs(widgets.Dialogs.AddPlayers.PlayerFrames or {}) do
        -- Hide and free
        playerFrame.Container:Hide()
        table.insert(widgets.Dialogs.AddPlayers.FreePlayerFrames, playerFrame)
    end
    widgets.Dialogs.AddPlayers.PlayerFrames = {}
    widgets.Dialogs.AddPlayers.Frame:Hide()
    widgets.Dialogs.AddPlayers.InputField:SetText("")
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll = {}
widgets.Dialogs.Roll.Items = {}
widgets.Dialogs.Roll.MainSpecRolls = {}
widgets.Dialogs.Roll.SecondSpecRolls = {}
widgets.Dialogs.Roll.TransmogRolls = {}
widgets.Dialogs.Roll.InvalidRolls = {}
widgets.Dialogs.Roll.FreeRolls = {}
widgets.Dialogs.Roll.AssignmentList = {}
widgets.Dialogs.Roll.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Dialogs.Roll.Frame:SetSize(40 + 64 + 20 + 125 + 20 + 125 + 40, 860)
widgets.Dialogs.Roll.Frame:SetPoint("TOPLEFT", widgets.Addon, "TOPRIGHT", 10, 0)
widgets.Dialogs.Roll.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Roll.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Roll.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Dialogs.Roll.Frame:SetFrameStrata("DIALOG")
widgets.Dialogs.Roll.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Create Skip Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.Skip = {}
widgets.Dialogs.Roll.Skip.Button, widgets.Dialogs.Roll.Skip.Text = CreateButton(widgets.Dialogs.Roll.Frame, "SKIP", 102, 30, color.DarkGray, color.LightGray, color.Gold)
widgets.Dialogs.Roll.Skip.Button:SetPoint("BOTTOMRIGHT", -15, 15)
widgets.Dialogs.Roll.Skip.Button:SetScript("OnEnter", function(self)
    if widgets.Dialogs.Roll.Roll.Button.rollActive then
        return
    end
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Roll.Skip.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Roll.Skip.Button:SetScript("OnClick", function(self)
    if widgets.Dialogs.Roll.Roll.Button.rollActive then
        return
    end

    widgets.Dialogs.Roll.ActiveItemLink = nil
    widgets.Dialogs.Roll.TypeSelection = nil

    widgets.Dialogs.Roll.Tier.Button.pushed = false
    widgets.Dialogs.Roll.Tier.Button:Enable()
    widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

    widgets.Dialogs.Roll.Rare.Button.pushed = false
    widgets.Dialogs.Roll.Rare.Button:Enable()
    widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

    widgets.Dialogs.Roll.Normal.Button.pushed = false
    widgets.Dialogs.Roll.Normal.Button:Enable()
    widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

    widgets.Dialogs.Roll.Assignment:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
    widgets.Dialogs.Roll.AssignmentText:SetText("NO ASSIGNMENT YET")
    widgets.Dialogs.Roll.AssignmentText:SetTextColor(color.White.r, color.White.g, color.White.b)

    for k, v in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
        v.Frame:Hide()
        table.insert(widgets.Dialogs.Roll.FreeRolls, v)
    end
    widgets.Dialogs.Roll.MainSpecRolls = {}
    for k, v in pairs(widgets.Dialogs.Roll.SecondSpecRolls) do
        v.Frame:Hide()
        table.insert(widgets.Dialogs.Roll.FreeRolls, v)
    end
    widgets.Dialogs.Roll.SecondSpecRolls = {}
    for k, v in pairs(widgets.Dialogs.Roll.TransmogRolls) do
        v.Frame:Hide()
        table.insert(widgets.Dialogs.Roll.FreeRolls, v)
    end
    widgets.Dialogs.Roll.TransmogRolls = {}
    for k, v in pairs(widgets.Dialogs.Roll.InvalidRolls) do
        v.Frame:Hide()
        table.insert(widgets.Dialogs.Roll.FreeRolls, v)
    end
    widgets.Dialogs.Roll.InvalidRolls = {}

    HandleLootAssignment()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.Header = CreateHeading("LOOT", widgets.Dialogs.Roll.Frame:GetWidth() - 10, widgets.Dialogs.Roll.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog Player Assignment Field
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.Assignment = CreateFrame("Frame", nil, widgets.Dialogs.Roll.Frame, "BackdropTemplate")
widgets.Dialogs.Roll.Assignment:SetPoint("TOPLEFT", 50, -155)
widgets.Dialogs.Roll.Assignment:SetSize(widgets.Dialogs.Roll.Frame:GetWidth() - 100, 30)
widgets.Dialogs.Roll.Assignment:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Roll.Assignment:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Roll.Assignment:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog Player Assignment Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.AssignmentText = CreateLabel("NO ASSIGNMENT YET", widgets.Dialogs.Roll.Assignment, nil, nil, color.White)
widgets.Dialogs.Roll.AssignmentText:SetPoint("CENTER")

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog MainSpec Loot Scroll View
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.ScrollMainSpecRoll = CreateFrame("ScrollFrame", nil, widgets.Dialogs.Roll.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
widgets.Dialogs.Roll.ScrollMainSpecRoll:SetPoint("TOPLEFT", 10, -215)
widgets.Dialogs.Roll.ScrollMainSpecRoll:SetPoint("TOPRIGHT", -32, -215)
widgets.Dialogs.Roll.ScrollMainSpecRoll:SetHeight(125)
widgets.Dialogs.Roll.ScrollMainSpecRoll:SetPoint("BOTTOMRIGHT", widgets.Dialogs.Roll.Frame, "TOPRIGHT", -38, -335)
widgets.Dialogs.Roll.ScrollMainSpecRoll:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Roll.ScrollMainSpecRoll:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Roll.ScrollMainSpecRoll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

widgets.Dialogs.Roll.ScrollMainSpecRollView = CreateFrame("Frame", nil, widgets.Dialogs.Roll.ScrollMainSpecRoll)
widgets.Dialogs.Roll.ScrollMainSpecRollView:SetWidth(widgets.Dialogs.Roll.ScrollMainSpecRoll:GetWidth())
widgets.Dialogs.Roll.ScrollMainSpecRollView:SetHeight(1)

widgets.Dialogs.Roll.ScrollMainSpecRoll:SetScrollChild(widgets.Dialogs.Roll.ScrollMainSpecRollView)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog MainSpec Roll Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.MainSpecRollLabel = CreateLabel("Main Spec Need (100):", widgets.Dialogs.Roll.Frame, nil, nil, color.Gold)
widgets.Dialogs.Roll.MainSpecRollLabel:SetPoint("BOTTOMLEFT", widgets.Dialogs.Roll.ScrollMainSpecRoll, "TOPLEFT", 5, 5)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog SecondSpec Loot Scroll View
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.ScrollSecondSpecRoll = CreateFrame("ScrollFrame", nil, widgets.Dialogs.Roll.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetPoint("TOPLEFT", widgets.Dialogs.Roll.ScrollMainSpecRoll, "BOTTOMLEFT", 0, -30)
widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetPoint("TOPRIGHT", widgets.Dialogs.Roll.ScrollMainSpecRoll, "BOTTOMRIGHT", 0, -30)
widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetHeight(125)
widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

widgets.Dialogs.Roll.ScrollSecondSpecRollView = CreateFrame("Frame", nil, widgets.Dialogs.Roll.ScrollSecondSpecRoll)
widgets.Dialogs.Roll.ScrollSecondSpecRollView:SetWidth(widgets.Dialogs.Roll.ScrollSecondSpecRoll:GetWidth())
widgets.Dialogs.Roll.ScrollSecondSpecRollView:SetHeight(1)

widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetScrollChild(widgets.Dialogs.Roll.ScrollSecondSpecRollView)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog MainSpec Roll Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.SecondSpecRollLabel = CreateLabel("Second Spec Rolls (50):", widgets.Dialogs.Roll.Frame, nil, nil, color.Gold)
widgets.Dialogs.Roll.SecondSpecRollLabel:SetPoint("BOTTOMLEFT", widgets.Dialogs.Roll.ScrollSecondSpecRoll, "TOPLEFT", 5, 5)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog Transmog Loot Scroll View
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.ScrollTransmogRoll = CreateFrame("ScrollFrame", nil, widgets.Dialogs.Roll.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
widgets.Dialogs.Roll.ScrollTransmogRoll:SetPoint("TOPLEFT", widgets.Dialogs.Roll.ScrollSecondSpecRoll, "BOTTOMLEFT", 0, -30)
widgets.Dialogs.Roll.ScrollTransmogRoll:SetPoint("TOPRIGHT", widgets.Dialogs.Roll.ScrollSecondSpecRoll, "BOTTOMRIGHT", 0, -30)
widgets.Dialogs.Roll.ScrollTransmogRoll:SetHeight(125)
widgets.Dialogs.Roll.ScrollTransmogRoll:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Roll.ScrollTransmogRoll:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Roll.ScrollTransmogRoll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

widgets.Dialogs.Roll.ScrollTransmogRollView = CreateFrame("Frame", nil, widgets.Dialogs.Roll.ScrollTransmogRoll)
widgets.Dialogs.Roll.ScrollTransmogRollView:SetWidth(widgets.Dialogs.Roll.ScrollTransmogRoll:GetWidth())
widgets.Dialogs.Roll.ScrollTransmogRollView:SetHeight(1)

widgets.Dialogs.Roll.ScrollTransmogRoll:SetScrollChild(widgets.Dialogs.Roll.ScrollTransmogRollView)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog MainSpec Roll Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.TransmogRollLabel = CreateLabel("Transmog Rolls (25):", widgets.Dialogs.Roll.Frame, nil, nil, color.Gold)
widgets.Dialogs.Roll.TransmogRollLabel:SetPoint("BOTTOMLEFT", widgets.Dialogs.Roll.ScrollTransmogRoll, "TOPLEFT", 5, 5)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog Invalid Loot Scroll View
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.ScrollInvalidRoll = CreateFrame("ScrollFrame", nil, widgets.Dialogs.Roll.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
widgets.Dialogs.Roll.ScrollInvalidRoll:SetPoint("TOPLEFT", widgets.Dialogs.Roll.ScrollTransmogRoll, "BOTTOMLEFT", 0, -30)
widgets.Dialogs.Roll.ScrollInvalidRoll:SetPoint("TOPRIGHT", widgets.Dialogs.Roll.ScrollTransmogRoll, "BOTTOMRIGHT", 0, -30)
widgets.Dialogs.Roll.ScrollInvalidRoll:SetHeight(125)
widgets.Dialogs.Roll.ScrollInvalidRoll:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Roll.ScrollInvalidRoll:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Roll.ScrollInvalidRoll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

widgets.Dialogs.Roll.ScrollInvalidRollView = CreateFrame("Frame", nil, widgets.Dialogs.Roll.ScrollInvalidRoll)
widgets.Dialogs.Roll.ScrollInvalidRollView:SetWidth(widgets.Dialogs.Roll.ScrollInvalidRoll:GetWidth())
widgets.Dialogs.Roll.ScrollInvalidRollView:SetHeight(1)

widgets.Dialogs.Roll.ScrollInvalidRoll:SetScrollChild(widgets.Dialogs.Roll.ScrollInvalidRollView)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog MainSpec Roll Label
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.InvalidRollLabel = CreateLabel("Invalid Rolls:", widgets.Dialogs.Roll.Frame, nil, nil, color.Gold)
widgets.Dialogs.Roll.InvalidRollLabel:SetPoint("BOTTOMLEFT", widgets.Dialogs.Roll.ScrollInvalidRoll, "TOPLEFT", 5, 5)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog Item Icon
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.ItemIcon = CreateFrame("Frame", nil, widgets.Dialogs.Roll.Frame, "BackdropTemplate")
widgets.Dialogs.Roll.ItemIcon:SetSize(64, 64)
widgets.Dialogs.Roll.ItemIcon:SetPoint("TOPLEFT", 40, -40)
widgets.Dialogs.Roll.ItemIcon:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Dialogs.Roll.ItemIcon:SetBackdropColor(0, 0, 0, 1)
widgets.Dialogs.Roll.ItemIcon:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

-----------------------------------------------------------------------------------------------------------------------
-- Create Roll Dialog Item Texture
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.ItemTexture = widgets.Dialogs.Roll.ItemIcon:CreateTexture(nil, "ARTWORK")
widgets.Dialogs.Roll.ItemTexture:SetAllPoints()
widgets.Dialogs.Roll.ActiveItemLink = nil
local itemTexture = select(10, GetItemInfo("|cffa335ee|Hitem:188032::::::::60:269::4:4:7183:6652:1472:6646:1:28:1707:::|h[Thunderous Echo Vambraces]|h|r"))
widgets.Dialogs.Roll.ItemTexture:SetTexture(itemTexture)

-----------------------------------------------------------------------------------------------------------------------
-- Roll Dialog: Roll Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.Roll = {}
widgets.Dialogs.Roll.Roll.Button, widgets.Dialogs.Roll.Roll.Text = CreateButton(widgets.Dialogs.Roll.Frame, "START ROLL", 125, 40, color.DarkGray, color.LightGray, color.Gold)
widgets.Dialogs.Roll.Roll.Button:SetPoint("LEFT", widgets.Dialogs.Roll.ItemIcon, "RIGHT", 20, 0)
widgets.Dialogs.Roll.Roll.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Roll.Roll.Button:SetScript("OnLeave", function(self)
    if self.rollActive then
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    else
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end
end)
widgets.Dialogs.Roll.Roll.Button:SetScript("OnClick", function(self)
    local channel = "RAID"
    if addonDB.Testing then
        channel = "WHISPER"
    end
    if self.rollActive then
        self.rollActive = false
        local itemLink = widgets.Dialogs.Roll.ActiveItemLink
        local msg = "---- FINISHED ROLL OF " .. itemLink .. " ----"
        SendChatMessage(msg, channel, nil, UnitName("player"))
        widgets.Dialogs.Roll.Roll.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
        widgets.Dialogs.Roll.Roll.Text:SetText("START ROLL")
    else
        self.rollActive = true
        local itemLink = widgets.Dialogs.Roll.ActiveItemLink
        local msg = "----    START ROLL OF " .. itemLink .. " ----"
        SendChatMessage(msg, channel, nil, UnitName("player"))
        widgets.Dialogs.Roll.Roll.Button:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
        widgets.Dialogs.Roll.Roll.Text:SetText("STOP ROLL")
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Roll Dialog: Roll CHAT_MSG_SYSTEM Handling
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.Frame:RegisterEvent("CHAT_MSG_SYSTEM")
widgets.Dialogs.Roll.Frame:SetScript("OnEvent", function(self, event, message)
    if event ~= "CHAT_MSG_SYSTEM" or message == nil or not widgets.Dialogs.Roll.Roll.Button.rollActive then
        return
    end
    -- Get data from message
    local colour = nil
    local class = nil
    local rollPattern = "^(.+)%-(.+) rolls (%d+) %((%d+)%-(%d+)%)$"
    local name, realm, rollValue, min, max = message:match(rollPattern)
    if name then
        class = select(2, UnitClass(name .. "-" .. realm))
        colour = classColor[class]
    else
        rollPattern = "^(.+) rolls (%d+) %((%d+)%-(%d+)%)$"
        name, rollValue, min, max = message:match(rollPattern)
        if not name then
            return
        end
        class = select(2, UnitClass(name))
        colour = classColor[class]
        realm = select(2, UnitFullName("player"))
    end
    -- Get as numbers
    rollValue = tonumber(rollValue)
    min = tonumber(min)
    max = tonumber(max)

    -- Get associated rolls and frame
    local rolls = widgets.Dialogs.Roll.InvalidRolls
    local scrollView = widgets.Dialogs.Roll.ScrollInvalidRollView
    if max == 100 then
        rolls = widgets.Dialogs.Roll.MainSpecRolls
        scrollView = widgets.Dialogs.Roll.ScrollMainSpecRollView
    elseif max == 50 then
        rolls = widgets.Dialogs.Roll.SecondSpecRolls
        scrollView = widgets.Dialogs.Roll.ScrollSecondSpecRollView
    elseif max == 25 then
        rolls = widgets.Dialogs.Roll.TransmogRolls
        scrollView = widgets.Dialogs.Roll.ScrollTransmogRollView
    end

    local roll = nil

    -- Prevent players from rolling more than once
    local fullName = name .. "-" .. realm
    for k, v in pairs(rolls) do
        if v.PlayerLabel:GetText() == fullName then
            return
        end
    end
    
    -- Create frame for player roll
    if #widgets.Dialogs.Roll.FreeRolls > 0 then
        for k, v in pairs(widgets.Dialogs.Roll.FreeRolls) do
            roll = v
            table.remove(widgets.Dialogs.Roll.FreeRolls, k)
            break
        end
        roll.Frame:SetParent(scrollView)
        roll.Frame:Show()
    else
        roll = {}
        roll.Frame = CreateFrame("Button", nil, scrollView, "BackdropTemplate")
        roll.Frame:SetSize(scrollView:GetWidth() - 20, 30)
        roll.Frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
        roll.Frame:SetBackdropColor(0, 0, 0, 1)
        roll.Frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        roll.Frame:SetScript("OnEnter", function(self) end)
        roll.Frame:SetScript("OnLeave", function(self)
            local c = color.LightGray
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end)

        roll.PlayerLabel = CreateLabel(name .. "-" .. realm, roll.Frame, 10, -10, colour)
        roll.RollLabel = CreateLabel("Roll:", roll.Frame, 200, -10, color.White)
        roll.PriorityLabel = CreateLabel("", roll.Frame, -10, -10, color.Gold, "TOPRIGHT")
        roll.Add = {}
        roll.Add.Button, roll.Add.Text = CreateButton(roll.Frame, "ADD", 70, 25, color.DarkGray, color.LightGray, color.Gold)
        roll.Add.Button:SetPoint("RIGHT", -10, 0)
        roll.Add.Button:SetScript("OnEnter", function(self)
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end)
        roll.Add.Button:SetScript("OnLeave", function(self)
            local c = color.LightGray
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end)
    end

    if max == 100 or (#widgets.Dialogs.Roll.MainSpecRolls == 0 and max == 50) or (#widgets.Dialogs.Roll.MainSpecRolls == 0 and #widgets.Dialogs.Roll.SecondSpecRolls == 0 and max == 25) then
        roll.Frame:SetScript("OnEnter", function(self)
            if not widgets.Dialogs.Roll.Roll.Button.rollActive then
                local c = color.Gold
                self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            end
        end)
        roll.Frame:SetScript("OnClick", function(self)
            if not widgets.Dialogs.Roll.Roll.Button.rollActive then
                widgets.Dialogs.Roll.AssignmentText:SetText(fullName)
                widgets.Dialogs.Roll.AssignmentText:SetTextColor(colour.r, colour.g, colour.b)
                widgets.Dialogs.Roll.Assignment:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
                widgets.Dialogs.Roll.Class = class
                -- Only count main rolls
                if max == 100 then
                    widgets.Dialogs.Roll.RollType = "MainSpecRoll"
                elseif max == 50 then
                    widgets.Dialogs.Roll.RollType = "SecondSpecRoll"
                elseif max == 25 then
                    widgets.Dialogs.Roll.RollType = "TransmogRoll"
                else
                    widgets.Dialogs.Roll.RollType = "InvalidRoll"
                end
            end
        end)
    else
        roll.Frame:SetScript("OnEnter", function(self) end)
        roll.Frame:SetScript("OnClick", function(self) end)
    end

    roll.Priority = 0
    roll.PlayerLabel:SetText(name .. "-" .. realm)
    roll.PlayerLabel:SetTextColor(colour.r, colour.g, colour.b, colour.a)
    roll.RollLabel:SetText("Roll: " .. rollValue)

    local orderName = nil
    for _, v in pairs(widgets.Setups) do
        if v.Name == addonDB.Tracking.Name then
            local playerFound = false
            for _, p in pairs(v.Players) do
                if p.PlayerName == fullName then
                    if max == 100 and widgets.Dialogs.Roll.Tier.Button.pushed then
                        local num = tonumber(p.TierText:GetText()) + tonumber(p.TierDiffText:GetText())
                        roll.Priority = num
                        roll.PriorityLabel:SetText("Prio: "..num)
                        roll.PriorityLabel:Show()
                        orderName = "Tier Low"
                    elseif max == 100 and widgets.Dialogs.Roll.Rare.Button.pushed then
                        local num = tonumber(p.RareText:GetText()) + tonumber(p.RareDiffText:GetText())
                        roll.Priority = num
                        roll.PriorityLabel:SetText("Prio: "..num)
                        roll.PriorityLabel:Show()
                        orderName = "Rare Low"
                    elseif max == 100 and widgets.Dialogs.Roll.Normal.Button.pushed then
                        local num = tonumber(p.NormalText:GetText()) + tonumber(p.NormalDiffText:GetText())
                        roll.Priority = num
                        roll.PriorityLabel:SetText("Prio: "..num)
                        roll.PriorityLabel:Show()
                        orderName = "Normal Low"
                    else
                        roll.PriorityLabel:SetText("")
                        roll.PriorityLabel:Hide()
                    end
                    roll.Add.Button:Hide()
                    playerFound = true
                    break
                end
            end
            -- Player missing in setup
            if not playerFound then
                roll.Priority = -1
                -- Hide label
                roll.PriorityLabel:SetText("")
                roll.PriorityLabel:Hide()
                -- Show button
                roll.Add.Button:Show()
                roll.Add.Button:SetScript("OnClick", function(self)
                    -- Add player frame
                    for _, setup in pairs(widgets.Setups) do
                        if setup.Tab.Button.pushed then
                            local config = nil
                            for _, c in pairs(configs) do
                                if c.Name == setup.Name then
                                    config = c
                                    break
                                end
                            end
                            -- Create new entry
                            local playerInfo = { 
                                ["Name"] = fullName,
                                ["Rare"] = 0,
                                ["Tier"] = 0,
                                ["Normal"] = 0,
                                ["Class"] = class
                            }
                            -- Create Player Frame
                            local player = {}
                            for fk, fv in pairs(widgets.FreePlayers) do 
                                player = fv
                                player.Container:Show()
                                player.Container:SetParent(setup.Table)
                                table.remove(widgets.FreePlayers, fk)
                                break
                            end
                            CreatePlayerFrame(player, config, setup, widgets, setup.Table, playerInfo, setup.Table:GetWidth(), 0, #config.PlayerInfos * -32)

                            -- Insert player data
                            table.insert(setup.Players, player)
                            table.insert(config.PlayerInfos, playerInfo)

                            -- Sort by order
                            if orderName then
                                for _, v in pairs(orderConfigs) do
                                    if v.Name == orderName then
                                        table.sort(setup.Players, v["Callback"])
                                        local vOffset = 0
                                        local sortedOrder = {}
                                        for i, p in pairs(setup.Players) do
                                            sortedOrder[p.PlayerName] = i
                                            p.Container:SetPoint("TOPLEFT", 0, vOffset)
                                            vOffset = vOffset - 32
                                        end
                                        setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

                                        table.sort(config["PlayerInfos"], function(a, b)
                                            return sortedOrder[a.Name] < sortedOrder[b.Name]
                                        end)
                                    end
                                end
                            end
                        end
                    end
                    -- Remove add button
                    for _, r in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
                        if r.PlayerLabel:GetText() == fullName then
                            r.Add.Button:Hide()
                            r.Priority = 0
                            if widgets.Dialogs.Roll.Tier.Button.pushed or widgets.Dialogs.Roll.Rare.Button.pushed or widgets.Dialogs.Roll.Normal.Button.pushed then
                                r.PriorityLabel:SetText("Prio: 0")
                                r.PriorityLabel:Show()
                            end
                            table.sort(widgets.Dialogs.Roll.MainSpecRolls, function(a, b) 
                                if a.Priority == nil and b.Priority == nil then
                                    return a.Value > b.Value
                                end
                                if a.Priority == nil then
                                    return false 
                                end
                                if b.Priority == nil then
                                    return true 
                                end
                                return a.Priority < b.Priority or (a.Priority == b.Priority and a.Value > b.Value)
                            end)

                            local vOffset = -5
                            for _, r in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
                                r.Frame:SetPoint("TOPLEFT", 10, vOffset)
                                vOffset = vOffset - 32
                            end
                            break
                        end
                    end
                    for _, r in pairs(widgets.Dialogs.Roll.SecondSpecRolls) do
                        if r.PlayerLabel:GetText() == fullName then
                            r.Add.Button:Hide()
                            break
                        end
                    end
                    for _, r in pairs(widgets.Dialogs.Roll.TransmogRolls) do
                        if r.PlayerLabel:GetText() == fullName then
                            r.Add.Button:Hide()
                            break
                        end
                    end
                    for _, r in pairs(widgets.Dialogs.Roll.InvalidRolls) do
                        if r.PlayerLabel:GetText() == fullName then
                            r.Add.Button:Hide()
                            break
                        end
                    end
                end)
            end
            break
        end
    end

    roll.Value = rollValue

    table.insert(rolls, roll)
    table.sort(rolls, function(a, b) 
        if a.Priority == nil and b.Priority == nil then
            return a.Value > b.Value
        end
        if a.Priority == nil then
            return false 
        end
        if b.Priority == nil then
            return true 
        end
        return a.Priority < b.Priority or (a.Priority == b.Priority and a.Value > b.Value)
    end)

    local vOffset = -5
    for _, r in pairs(rolls) do
        r.Frame:SetPoint("TOPLEFT", 10, vOffset)
        vOffset = vOffset - 32
    end

    if #widgets.Dialogs.Roll.MainSpecRolls > 0 then
        for _, r in pairs(widgets.Dialogs.Roll.SecondSpecRolls) do
            r.Frame:SetScript("OnClick", function(self) end)
            r.Frame:SetScript("OnEnter", function(self) end)
        end
    end
    if #widgets.Dialogs.Roll.MainSpecRolls > 0 or #widgets.Dialogs.Roll.SecondSpecRolls > 0 then
        for _, r in pairs(widgets.Dialogs.Roll.TransmogRolls) do
            r.Frame:SetScript("OnClick", function(self) end)
            r.Frame:SetScript("OnEnter", function(self) end)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Roll Dialog: Tier Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.Tier = {}
widgets.Dialogs.Roll.Tier.Button, widgets.Dialogs.Roll.Tier.Text = CreateButton(widgets.Dialogs.Roll.Frame, "TIER", 102, 25, color.DarkGray, color.LightGray, color.Gold)
widgets.Dialogs.Roll.Tier.Button:SetPoint("TOP", 0, -120)
widgets.Dialogs.Roll.Tier.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Roll.Tier.Button:SetScript("OnLeave", function(self)
    if self.pushed then
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    else
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end
end)
widgets.Dialogs.Roll.Tier.Button:SetScript("OnClick", function(self)
    if not self.pushed then
        self.pushed = true
        self:Disable()
        widgets.Dialogs.Roll.TypeSelection = "Tier"
        self:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
        widgets.Dialogs.Roll.Rare.Button.pushed = false
        widgets.Dialogs.Roll.Rare.Button:Enable()
        widgets.Dialogs.Roll.Normal.Button.pushed = false
        widgets.Dialogs.Roll.Normal.Button:Enable()
        widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
        widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

        for _, setup in pairs(widgets.Setups) do
            if setup.Tab.Button.pushed then
                local c = color.Gold
                -- Set orderButton active and update order
                setup.Order["Tier Low"].Button.pushed = true
                setup.Order["Tier Low"].Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                setup.Order["Tier Low"].Button:Disable()

                -- update order of rolls
                for _, roll in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
                    -- Update priorities in rolls
                    for _, player in pairs(setup.Players) do
                        if player.PlayerName == roll.PlayerLabel:GetText() then
                            local num = tonumber(player.TierText:GetText()) + tonumber(player.TierDiffText:GetText())
                            roll.Priority = num
                            roll.PriorityLabel:SetText("Prio: ".. num)
                            roll.PriorityLabel:Show()
                            break
                        end
                    end
                end

                table.sort(widgets.Dialogs.Roll.MainSpecRolls, function(a, b) 
                    if a.Priority == nil and b.Priority == nil then
                        return a.Value > b.Value
                    end
                    if a.Priority == nil then
                        return false 
                    end
                    if b.Priority == nil then
                        return true 
                    end
                    return a.Priority < b.Priority or (a.Priority == b.Priority and a.Value > b.Value)
                end)

                local vOffset = -5
                for _, r in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
                    r.Frame:SetPoint("TOPLEFT", 10, vOffset)
                    vOffset = vOffset - 32
                end

                -- Update order of table view
                local setupOrder = nil
                for _, v in pairs(orderConfigs) do
                    if v.Name == "Tier Low" then
                        setupOrder = v
                        break
                    end
                end
                table.sort(setup.Players, setupOrder.Callback)
                local vOffset = 0

                local sortedOrder = {}
                for i, player in pairs(setup.Players) do
                    sortedOrder[player.PlayerName] = i
                    player.Container:SetPoint("TOPLEFT", 0, vOffset)
                    vOffset = vOffset - 32
                end
                setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

                for k, config in pairs(configs) do
                    if config.Name == setup.Name then
                        table.sort(config["PlayerInfos"], function(a, b)
                            return sortedOrder[a.Name] < sortedOrder[b.Name]
                        end)
                        break
                    end
                end

                for k, v in pairs(setup["Order"]) do
                    if "Tier Low" ~= k then
                        local cl = color.LightGray
                        v.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
                        v.Button.pushed = false
                        v.Button:Enable()
                    end
                end
                break
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Roll Dialog: Rare Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.Rare = {}
widgets.Dialogs.Roll.Rare.Button, widgets.Dialogs.Roll.Rare.Text = CreateButton(widgets.Dialogs.Roll.Frame, "RARE", 102, 25, color.DarkGray, color.LightGray, color.Gold)
widgets.Dialogs.Roll.Rare.Button:SetPoint("RIGHT", widgets.Dialogs.Roll.Tier.Button, "LEFT", -14, 0)
widgets.Dialogs.Roll.Rare.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Roll.Rare.Button:SetScript("OnLeave", function(self)
    if self.pushed then
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    else
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end
end)
widgets.Dialogs.Roll.Rare.Button:SetScript("OnClick", function(self)
    if not self.pushed then
        self.pushed = true
        self:Disable()
        widgets.Dialogs.Roll.TypeSelection = "Rare"
        self:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
        widgets.Dialogs.Roll.Tier.Button.pushed = false 
        widgets.Dialogs.Roll.Tier.Button:Enable()
        widgets.Dialogs.Roll.Normal.Button.pushed = false 
        widgets.Dialogs.Roll.Normal.Button:Enable()
        widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
        widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

        for _, setup in pairs(widgets.Setups) do
            if setup.Tab.Button.pushed then
                local c = color.Gold
                -- Set orderButton active and update order
                setup.Order["Rare Low"].Button.pushed = true
                setup.Order["Rare Low"].Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                setup.Order["Rare Low"].Button:Disable()

                -- update order of rolls
                for _, roll in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
                    -- Update priorities in rolls
                    for _, player in pairs(setup.Players) do
                        if player.PlayerName == roll.PlayerLabel:GetText() then
                            local num = tonumber(player.RareText:GetText()) + tonumber(player.RareDiffText:GetText())
                            roll.Priority = num
                            roll.PriorityLabel:SetText("Prio: ".. num)
                            roll.PriorityLabel:Show()
                            break
                        end
                    end
                end

                table.sort(widgets.Dialogs.Roll.MainSpecRolls, function(a, b) 
                    if a.Priority == nil and b.Priority == nil then
                        return a.Value > b.Value
                    end
                    if a.Priority == nil then
                        return false 
                    end
                    if b.Priority == nil then
                        return true 
                    end
                    return a.Priority < b.Priority or (a.Priority == b.Priority and a.Value > b.Value)
                end)

                local vOffset = -5
                for _, r in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
                    r.Frame:SetPoint("TOPLEFT", 10, vOffset)
                    vOffset = vOffset - 32
                end

                -- Update order
                local setupOrder = nil
                for _, v in pairs(orderConfigs) do
                    if v.Name == "Rare Low" then
                        setupOrder = v
                        break
                    end
                end
                table.sort(setup.Players, setupOrder.Callback)
                local vOffset = 0

                local sortedOrder = {}
                for i, player in pairs(setup.Players) do
                    sortedOrder[player.PlayerName] = i
                    player.Container:SetPoint("TOPLEFT", 0, vOffset)
                    vOffset = vOffset - 32
                end
                setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

                for k, config in pairs(configs) do
                    if config.Name == setup.Name then
                        table.sort(config["PlayerInfos"], function(a, b)
                            return sortedOrder[a.Name] < sortedOrder[b.Name]
                        end)
                        break
                    end
                end

                for k, v in pairs(setup["Order"]) do
                    if "Rare Low" ~= k then
                        local cl = color.LightGray
                        v.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
                        v.Button.pushed = false
                        v.Button:Enable()
                    end
                end
                break
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Roll Dialog: Normal Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.Normal = {}
widgets.Dialogs.Roll.Normal.Button, widgets.Dialogs.Roll.Normal.Text = CreateButton(widgets.Dialogs.Roll.Frame, "NORMAL", 102, 25, color.DarkGray, color.LightGray, color.Gold)
widgets.Dialogs.Roll.Normal.Button:SetPoint("LEFT", widgets.Dialogs.Roll.Tier.Button, "RIGHT", 14, 0)
widgets.Dialogs.Roll.Normal.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Roll.Normal.Button:SetScript("OnLeave", function(self)
    if self.pushed then
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    else
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end
end)
widgets.Dialogs.Roll.Normal.Button:SetScript("OnClick", function(self)
    if not self.pushed then
        self.pushed = true
        self:Disable()
        widgets.Dialogs.Roll.TypeSelection = "Normal"
        self:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
        widgets.Dialogs.Roll.Tier.Button.pushed = false
        widgets.Dialogs.Roll.Tier.Button:Enable()
        widgets.Dialogs.Roll.Rare.Button.pushed = false
        widgets.Dialogs.Roll.Rare.Button:Enable()
        widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
        widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

        for _, setup in pairs(widgets.Setups) do
            if setup.Tab.Button.pushed then
                local c = color.Gold
                -- Set orderButton active and update order
                setup.Order["Normal Low"].Button.pushed = true
                setup.Order["Normal Low"].Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                setup.Order["Normal Low"].Button:Disable()

                -- update order of rolls
                for _, roll in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
                    -- Update priorities in rolls
                    for _, player in pairs(setup.Players) do
                        if player.PlayerName == roll.PlayerLabel:GetText() then
                            local num = tonumber(player.NormalText:GetText()) + tonumber(player.NormalDiffText:GetText())
                            roll.Priority = num
                            roll.PriorityLabel:SetText("Prio: ".. num)
                            roll.PriorityLabel:Show()
                            break
                        end
                    end
                end

                table.sort(widgets.Dialogs.Roll.MainSpecRolls, function(a, b) 
                    if a.Priority == nil and b.Priority == nil then
                        return a.Value > b.Value
                    end
                    if a.Priority == nil then
                        return false 
                    end
                    if b.Priority == nil then
                        return true 
                    end
                    return a.Priority < b.Priority or (a.Priority == b.Priority and a.Value > b.Value)
                end)

                local vOffset = -5
                for _, r in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
                    r.Frame:SetPoint("TOPLEFT", 10, vOffset)
                    vOffset = vOffset - 32
                end

                -- Update order
                local setupOrder = nil
                for _, v in pairs(orderConfigs) do
                    if v.Name == "Normal Low" then
                        setupOrder = v
                        break
                    end
                end
                table.sort(setup.Players, setupOrder.Callback)
                local vOffset = 0

                local sortedOrder = {}
                for i, player in pairs(setup.Players) do
                    sortedOrder[player.PlayerName] = i
                    player.Container:SetPoint("TOPLEFT", 0, vOffset)
                    vOffset = vOffset - 32
                end
                setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

                for k, config in pairs(configs) do
                    if config.Name == setup.Name then
                        table.sort(config["PlayerInfos"], function(a, b)
                            return sortedOrder[a.Name] < sortedOrder[b.Name]
                        end)
                        break
                    end
                end

                for k, v in pairs(setup["Order"]) do
                    if "Normal Low" ~= k then
                        local cl = color.LightGray
                        v.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
                        v.Button.pushed = false
                        v.Button:Enable()
                    end
                end
                break
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Roll Dialog: Assign Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Dialogs.Roll.Assign = {}
widgets.Dialogs.Roll.Assign.Button, widgets.Dialogs.Roll.Assign.Text = CreateButton(widgets.Dialogs.Roll.Frame, "ASSIGN", 125, 40, color.DarkGray, color.LightGray, color.Gold)
widgets.Dialogs.Roll.Assign.Button:SetPoint("LEFT", widgets.Dialogs.Roll.Roll.Button, "RIGHT", 20, 0)
widgets.Dialogs.Roll.Assign.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Roll.Assign.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Dialogs.Roll.Assign.Button:SetScript("OnClick", function(self)
    if widgets.Dialogs.Roll.Roll.Button.rollActive or widgets.Dialogs.Roll.AssignmentText:GetText() == "NO ASSIGNMENT YET"  or widgets.Dialogs.Roll.TypeSelection == nil then
        return
    end

    local playerName = widgets.Dialogs.Roll.AssignmentText:GetText()
    if widgets.Dialogs.Roll.RollType == "MainSpecRoll" then
        for _, setup in pairs(widgets.Setups) do
            if setup.Tab.Button.pushed then
                for _, player in pairs(setup.Players) do
                    if player.PlayerName == playerName then
                        if widgets.Dialogs.Roll.TypeSelection == "Tier" then
                            local num = tonumber(player.TierDiffText:GetText()) + 1
                            if num > 0 then
                                local g = color.Green
                                player.TierDiffText:SetText("+" .. num)
                                player.TierDiffText:SetTextColor(g.r, g.g, g.b)
                            elseif num < 0 then
                                local r = color.Red
                                player.TierDiffText:SetText(num)
                                player.TierDiffText:SetTextColor(r.r, r.g, r.b)
                            else
                                local r = color.White
                                player.TierDiffText:SetText(0)
                                player.TierDiffText:SetTextColor(r.r, r.g, r.b)
                            end
                        elseif widgets.Dialogs.Roll.TypeSelection == "Rare" then
                            local num = tonumber(player.RareDiffText:GetText()) + 1
                            if num > 0 then
                                local g = color.Green
                                player.RareDiffText:SetText("+" .. num)
                                player.RareDiffText:SetTextColor(g.r, g.g, g.b)
                            elseif num < 0 then
                                local r = color.Red
                                player.RareDiffText:SetText(num)
                                player.RareDiffText:SetTextColor(r.r, r.g, r.b)
                            else
                                local r = color.White
                                player.RareDiffText:SetText(0)
                                player.RareDiffText:SetTextColor(r.r, r.g, r.b)
                            end
                        elseif widgets.Dialogs.Roll.TypeSelection == "Normal" then
                            local num = tonumber(player.NormalDiffText:GetText()) + 1
                            if num > 0 then
                                local g = color.Green
                                player.NormalDiffText:SetText("+" .. num)
                                player.NormalDiffText:SetTextColor(g.r, g.g, g.b)
                            elseif num < 0 then
                                local r = color.Red
                                player.NormalDiffText:SetText(num)
                                player.NormalDiffText:SetTextColor(r.r, r.g, r.b)
                            else
                                local r = color.White
                                player.NormalDiffText:SetText(0)
                                player.NormalDiffText:SetTextColor(r.r, r.g, r.b)
                            end
                        else
                            print("[ERROR] No loot category selected!")
                        end
                        -- Update order if active
                        local activeOrder = nil
                        for name, orderBtn in pairs(setup.Order) do
                            if orderBtn.Button.pushed then
                                for _, order in pairs(orderConfigs) do
                                    if order.Name == name then
                                        activeOrder = order
                                        break
                                    end
                                end
                                break
                            end
                        end
                        if activeOrder then
                            table.sort(setup.Players, activeOrder["Callback"])
                            local vOffset = 0

                            local sortedOrder = {}
                            for i, player in pairs(setup.Players) do
                                sortedOrder[player.PlayerName] = i
                                player.Container:SetPoint("TOPLEFT", 0, vOffset)
                                vOffset = vOffset - 32
                            end
                            setup.TableBottomLine:SetPoint("TOPLEFT", 5, vOffset + 2)

                            for k, config in pairs(configs) do
                                if config.Name == setup.Name then
                                    table.sort(config["PlayerInfos"], function(a, b)
                                        return sortedOrder[a.Name] < sortedOrder[b.Name]
                                    end)
                                    break
                                end
                            end
                        end
                        break
                    end
                end
                break
            end
        end
    end

    local assignment = {
        ItemLink = widgets.Dialogs.Roll.ActiveItemLink,
        PlayerName = playerName,
        RollType = widgets.Dialogs.Roll.RollType,
        Class = widgets.Dialogs.Roll.Class
    }
    table.insert(widgets.Dialogs.Roll.AssignmentList, assignment)

    widgets.Dialogs.Roll.ActiveItemLink = nil
    widgets.Dialogs.Roll.TypeSelection = nil

    widgets.Dialogs.Roll.Tier.Button.pushed = false
    widgets.Dialogs.Roll.Tier.Button:Enable()
    widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

    widgets.Dialogs.Roll.Rare.Button.pushed = false
    widgets.Dialogs.Roll.Rare.Button:Enable()
    widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

    widgets.Dialogs.Roll.Normal.Button.pushed = false
    widgets.Dialogs.Roll.Normal.Button:Enable()
    widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

    widgets.Dialogs.Roll.Assignment:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
    widgets.Dialogs.Roll.AssignmentText:SetText("NO ASSIGNMENT YET")
    widgets.Dialogs.Roll.AssignmentText:SetTextColor(color.White.r, color.White.g, color.White.b)

    for k, v in pairs(widgets.Dialogs.Roll.MainSpecRolls) do
        v.Frame:Hide()
        table.insert(widgets.Dialogs.Roll.FreeRolls, v)
    end
    widgets.Dialogs.Roll.MainSpecRolls = {}
    for k, v in pairs(widgets.Dialogs.Roll.SecondSpecRolls) do
        v.Frame:Hide()
        table.insert(widgets.Dialogs.Roll.FreeRolls, v)
    end
    widgets.Dialogs.Roll.SecondSpecRolls = {}
    for k, v in pairs(widgets.Dialogs.Roll.TransmogRolls) do
        v.Frame:Hide()
        table.insert(widgets.Dialogs.Roll.FreeRolls, v)
    end
    widgets.Dialogs.Roll.TransmogRolls = {}
    for k, v in pairs(widgets.Dialogs.Roll.InvalidRolls) do
        v.Frame:Hide()
        table.insert(widgets.Dialogs.Roll.FreeRolls, v)
    end
    widgets.Dialogs.Roll.InvalidRolls = {}

    HandleLootAssignment()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Summary Dialog
-----------------------------------------------------------------------------------------------------------------------
widgets.Summary = {}
widgets.Summary.Items = {}
widgets.Summary.FreeItems = {}
widgets.Summary.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
widgets.Summary.Frame:SetSize(390, 450)
widgets.Summary.Frame:SetPoint("CENTER", 0, 0)
widgets.Summary.Frame:SetMovable(true)
widgets.Summary.Frame:EnableMouse(true)
widgets.Summary.Frame:RegisterForDrag("LeftButton")
widgets.Summary.Frame:SetScript("OnDragStart", widgets.Summary.Frame.StartMoving)
widgets.Summary.Frame:SetScript("OnDragStop", widgets.Summary.Frame.StopMovingOrSizing)
widgets.Summary.Frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
})
widgets.Summary.Frame:SetBackdropColor(0, 0, 0, 1)
widgets.Summary.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
widgets.Summary.Frame:SetFrameStrata("DIALOG")
widgets.Summary.Frame:Hide()

-----------------------------------------------------------------------------------------------------------------------
-- Create Summary Dialog Header
-----------------------------------------------------------------------------------------------------------------------
widgets.Summary.Header = CreateHeading("SUMMARY", widgets.Summary.Frame:GetWidth() - 10, widgets.Summary.Frame, 5, -10, true)

-----------------------------------------------------------------------------------------------------------------------
-- Create Summary Dialog Close Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Summary.Close = {}
widgets.Summary.Close.Button, widgets.Summary.Close.Text = CreateButton(widgets.Summary.Frame, "CLOSE", 102, 30, color.DarkGray, color.LightGray, color.Gold)
widgets.Summary.Close.Button:SetPoint("BOTTOMRIGHT", widgets.Summary.Frame, "BOTTOMRIGHT", -10, 10)
widgets.Summary.Close.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Summary.Close.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Summary.Close.Button:SetScript("OnClick", function(self)
    widgets.Dialogs.Roll.AssignmentList = {}
    widgets.Summary.Frame:Hide()
    -- Free all frames
    for _, w in pairs(widgets.Summary.Items) do
        table.insert(widgets.Summary.FreeItems, w)
        w.Frame:Hide()
    end
    widgets.Summary.Items = {}
    -- Show Roll frame again if rolls came up while summary was shown
    HandleLootAssignment()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Setup New Raid Button
-----------------------------------------------------------------------------------------------------------------------
widgets.NewRaid = {}
widgets.NewRaid.Button, widgets.NewRaid.Text= CreateButton(widgets.Addon, "New RAID", 102, 35, color.DarkGray, color.LightGray)
widgets.NewRaid.Button:SetPoint("BOTTOMLEFT", 6, 66)
widgets.NewRaid.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.NewRaid.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.NewRaid.Button:SetScript("OnClick", function(self)
    if IsDialogShown() then
        return
    end
    widgets.Dialogs.NewRaid.Frame:Show()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Setup Import Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Import = {}
widgets.Import.Button, widgets.Import.Text = CreateButton(widgets.Addon, "Import", 102, 35, color.DarkGray, color.LightGray)
widgets.Import.Button:SetPoint("BOTTOMLEFT", 6, 25)
widgets.Import.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Import.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Import.Button:SetScript("OnClick", function(self)
    if IsDialogShown() then
        return
    end
    widgets.Dialogs.Import.Frame:Show()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Setup AddPlayers Button
-----------------------------------------------------------------------------------------------------------------------
widgets.AddPlayers = {}
widgets.AddPlayers.Button, widgets.AddPlayers.Text = CreateButton(widgets.Addon, "Add Players", 102, 35, color.DarkGray, color.LightGray)
widgets.AddPlayers.Button:SetPoint("BOTTOMLEFT", 112, 66)
widgets.AddPlayers.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.AddPlayers.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.AddPlayers.Button:SetScript("OnClick", function(self)
    if IsDialogShown() then
        return
    end

    for _, setup in pairs(widgets.Setups) do
        if setup.Tab.Button.pushed then
            local units = GetUnregisteredPlayers(setup)
            for _, unit in pairs(units) do
                -- Create frame
                local player = {}
                player.Class = unit.Class
                local c = classColor[unit.Class]
                if #widgets.Dialogs.AddPlayers.FreePlayerFrames > 0 then
                    for k, v in pairs(widgets.Dialogs.AddPlayers.FreePlayerFrames) do
                        player = v
                        player.Container:Show()
                        player.Checkbox:SetChecked(false)
                        player.Name:SetText(unit.Name)
                        player.Name:SetTextColor(c.r, c.g, c.b)
                        player.Container:SetPoint("TOPLEFT", 10, -10 + -33 * #widgets.Dialogs.AddPlayers.PlayerFrames)
                        table.insert(widgets.Dialogs.AddPlayers.PlayerFrames, player)
                        table.remove(widgets.Dialogs.AddPlayers.FreePlayerFrames, k)
                        break 
                    end
                else
                    player.Container = CreateFrame("Frame", nil, widgets.Dialogs.AddPlayers.ScrollView, "BackdropTemplate")
                    player.Container:SetWidth(widgets.Dialogs.AddPlayers.ScrollView:GetWidth() - 20)
                    player.Container:SetHeight(30)
                    player.Container:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 2,
                    })
                    player.Container:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, color.DarkGray.a)
                    player.Container:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, color.LightGray.a)
                    player.Container:SetPoint("TOPLEFT", 10, -10 + -33 * #widgets.Dialogs.AddPlayers.PlayerFrames)
                    player.Name = CreateLabel(unit.Name, player.Container, 100, -9, classColor[unit.Class])
                    player.Checkbox = CreateFrame("CheckButton", nil, player.Container, "ChatConfigCheckButtonTemplate")
                    player.Checkbox:SetSize(24, 24)
                    player.Checkbox:SetChecked(false)
                    player.Checkbox:SetPoint("TOPLEFT", 30, -3)
                    table.insert(widgets.Dialogs.AddPlayers.PlayerFrames, player)
                end
            end
            break;
        end
    end

    widgets.Dialogs.AddPlayers.Frame:Show()
end)

-----------------------------------------------------------------------------------------------------------------------
-- Setup Options Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Options = {}
widgets.Options.Button, widgets.Options.Text = CreateButton(widgets.Addon, "Options", 102, 35, color.DarkGray, color.LightGray)
widgets.Options.Button:SetPoint("BOTTOMLEFT", 112, 25)
widgets.Options.Button:SetScript("OnEnter", function(self)
    local c = color.Gold
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Options.Button:SetScript("OnLeave", function(self)
    local c = color.LightGray
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end)
widgets.Options.Button:SetScript("OnClick", function(self)
    if IsDialogShown() then
        return
    end
    widgets.Dialogs.Options.Frame:ClearAllPoints()
    widgets.Dialogs.Options.Frame:SetPoint("CENTER", widgets.Addon, "CENTER", 0, 0)
    widgets.Dialogs.Options.TierIdInputField:SetText(ArrayToString(addonDB.Options.TierItems))
    widgets.Dialogs.Options.RareIdInputField:SetText(ArrayToString(addonDB.Options.RareItems))
    widgets.Dialogs.Options.Frame:Show()
end)


-----------------------------------------------------------------------------------------------------------------------
-- Register Addon Events
-----------------------------------------------------------------------------------------------------------------------
widgets.Addon:RegisterEvent("ADDON_LOADED")
widgets.Addon:RegisterEvent("PLAYER_LOGOUT")
widgets.Addon:RegisterEvent("PLAYER_LOGIN")
widgets.Addon:RegisterEvent("BOSS_KILL")
widgets.Addon:RegisterEvent("START_LOOT_ROLL")
widgets.Addon:RegisterEvent("RAID_INSTANCE_WELCOME")

-----------------------------------------------------------------------------------------------------------------------
-- Callback for Event Handling
-----------------------------------------------------------------------------------------------------------------------
widgets.Addon:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        local savedVariable = RaidTablesDB or {}
        if savedVariable.Config then
            for k, v in pairs(savedVariable.Config) do
                table.insert(addonDB.Config, v)
                SetupNewEntry(v, k == 1)
            end
        end
        addonDB.Options = {}
        addonDB.Options.TierItems = (savedVariable.Options and savedVariable.Options.TierItems) or TierItems
        addonDB.Options.RareItems = (savedVariable.Options and savedVariable.Options.RareItems) or RareItems
    elseif event == "PLAYER_LOGIN" then
        if IsInInstance("raid") and not addonDB.Tracking.Active and not widgets.Dialogs.ActivateRaid.Frame:IsShown() then
            widgets.Dialogs.ActivateRaid.SetupSelection()
            widgets.Dialogs.ActivateRaid.Frame:Show()
        end
    elseif event == "PLAYER_LOGOUT" then
        RaidTablesDB = {}
        RaidTablesDB.Config = addonDB.Config
        RaidTablesDB.Options = addonDB.Options
    elseif event == "RAID_INSTANCE_WELCOME" then
        if not addonDB.Tracking.Active and not widgets.Dialogs.ActivateRaid.Frame:IsShown() then
            widgets.Dialogs.ActivateRaid.SetupSelection()
            widgets.Dialogs.ActivateRaid.Frame:Show()
        end
    elseif event == "BOSS_KILL" then
        -- pass
    elseif event == "START_LOOT_ROLL" and arg1 then
        if addonDB.Tracking.Active and IsInRaid() then
            local itemLink = GetLootRollItemLink(arg1)
            widgets.Dialogs.Roll.Items = widgets.Dialogs.Roll.Items or {}
            table.insert(widgets.Dialogs.Roll.Items, itemLink)

            for _, s in pairs(widgets.Setups) do
                if addonDB.Tracking.Name == nil and s.Tab.Button.pushed then
                    addonDB.Tracking.Name = s.Name
                elseif s.Name == addonDB.Tracking.Name then
                    -- Activate the tracked Raid Tab
                    s.Tab.Button.pushed = true
                    s.Tab.Button:Disable()
                    local c = color.Gold
                    s.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                    s.Content:Show()
                else
                    -- Hide all other Tabs
                    local cl = color.LightGray
                    s.Tab.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
                    s.Tab.Button.pushed = false
                    s.Tab.Button:Enable()
                    s.Content:Hide()
                end
            end

            HandleLootAssignment()
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Create Slash Command
-----------------------------------------------------------------------------------------------------------------------
SLASH_RAID_TABLES_COMMAND1 = "/gpt"
local function SlashCommandHandler(msg)
    if msg == "help" then
        print("LootTables - Help Menu")
        print(" ")
        print("Options:")
        print("  help: Show this help menu.")
        print("  stats: Show stats of the addon.")
    elseif msg == "stats" then
        print("Created Frames = "..createdFrameCount)
        print("Raid Configs = "..#configs)
        print("Free Raid Entities = "..#widgets.FreeSetups)
        print("Free Player Entities = "..#widgets.FreePlayers)
        print("Player List Items = "..#widgets.Dialogs.AddPlayers.PlayerFrames)
        print("Free Player List Items = "..#widgets.Dialogs.AddPlayers.FreePlayerFrames)
    elseif msg == "roll test" then
        addonDB.Testing = true
        local item = select(2, GetItemInfo("|cffa335ee|Hitem:196590::::::::60:577::6:4:7188:6652:1485:6646:1:28:752:::|h[Dreadful Topaz Forgestone]|h|r"))
        table.insert(widgets.Dialogs.Roll.Items, item)
        item = select(2, GetItemInfo("|cffa335ee|Hitem:19019::::::::120:265::5::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r"))
        table.insert(widgets.Dialogs.Roll.Items, item)
        item = select(2, GetItemInfo("|cffa335ee|Hitem:188032::::::::60:269::4:4:7183:6652:1472:6646:1:28:1707:::|h[Thunderous Echo Vambraces]|h|r"))
        table.insert(widgets.Dialogs.Roll.Items, item)

        addonDB.Tracking.Active = true
        for _, s in pairs(widgets.Setups) do
            if addonDB.Tracking.Name == nil and s.Tab.Button.pushed then
                addonDB.Tracking.Name = s.Name
                local c = color.Highlight
                s.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
            elseif s.Name == addonDB.Tracking.Name then
                -- Activate the tracked Raid Tab
                s.Tab.Button.pushed = true
                s.Tab.Button:Disable()
                local c = color.Gold
                s.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                s.Content:Show()
            else
                -- Hide all other Tabs
                local cl = color.LightGray
                s.Tab.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
                s.Tab.Button.pushed = false
                s.Tab.Button:Enable()
                s.Content:Hide()
            end
        end

        HandleLootAssignment()
    else
        if not widgets.Addon:IsShown() then
            widgets.Addon:Show()
        else 
            widgets.Addon:Hide()
        end
    end
end
SlashCmdList.RAID_TABLES_COMMAND = SlashCommandHandler

-----------------------------------------------------------------------------------------------------------------------
-- Create Minimap Button
-----------------------------------------------------------------------------------------------------------------------
widgets.Minimap = CreateFrame("Button", nil, Minimap)
widgets.Minimap:SetSize(32, 32)
widgets.Minimap:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 10, -50)
widgets.Minimap:SetNormalTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
widgets.Minimap:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
widgets.Minimap:SetPushedTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
widgets.Minimap:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("MyAddon")
    GameTooltip:AddLine("Click to show MyAddon frame", 1, 1, 1)
    GameTooltip:Show()
end)
widgets.Minimap:SetScript("OnLeave", function() GameTooltip:Hide() end)
widgets.Minimap:SetScript("OnClick", function(self)
    if widgets.Addon:IsShown() then
        if IsDialogShown() then
            return
        end
        widgets.Addon:Hide()
    else
        widgets.Addon:Show()
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Hide Addon Frame Initially
-----------------------------------------------------------------------------------------------------------------------
widgets.Addon:Hide()
