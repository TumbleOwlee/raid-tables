-----------------------------------------------------------------------------------------------------------------------
-- Addon Meta Information
-----------------------------------------------------------------------------------------------------------------------
local addonName = "RaidTables"
local author = "Owleé-Blackmoore (EU)"

-----------------------------------------------------------------------------------------------------------------------
-- Setup Tables And Variables for Easy Access
-----------------------------------------------------------------------------------------------------------------------
local addonDB = {
    Widgets = {
        Setups = {},
        FreeSetups = {},
        FreePlayers = {},
        Dialogs = {},
        Minimap = {},
    },
    Configs = {},
    Options = {
        TierItems = {
            196488, 196598, 196603, 196593,
            196587, 196597, 196602, 196592,
            196586, 196596, 196601, 196591,
            196589, 196599, 196604, 196594,
            196590, 196600, 196605, 196595,
        },
        RareItems = {
            195480, 194301, 195526, 195527,
        },
        Scaling = 1.0,
        Minimap = {
            X = 10,
            Y = 10,
        },
    },
    Tracking = {
        Active = false,
        Name = nil,
    },
    Testing = true,
    Sharing = false,
    LastEncodedConfig = nil,
}

-----------------------------------------------------------------------------------------------------------------------
-- Merge Tables
-----------------------------------------------------------------------------------------------------------------------
local function MergeTables(t1, t2)
    local merged = {}
    for k, v in pairs(t1) do
        merged[k] = v
    end
    for k, v in pairs(t2) do
        merged[k] = v
    end
    return merged
end

-----------------------------------------------------------------------------------------------------------------------
-- Get Scale agnostic Width
-----------------------------------------------------------------------------------------------------------------------
local function GetWidth(frame)
    return frame:GetWidth() / addonDB.Options.Scaling
end

-----------------------------------------------------------------------------------------------------------------------
-- Get Scale Agnostic Height
-----------------------------------------------------------------------------------------------------------------------
local function GetHeight(frame)
    return frame:GetHeight() / addonDB.Options.Scaling
end

-----------------------------------------------------------------------------------------------------------------------
-- Agnostic
-----------------------------------------------------------------------------------------------------------------------
local function Agnostic(num)
    if not num then
        return nil
    end
    return num / addonDB.Options.Scaling
end

-----------------------------------------------------------------------------------------------------------------------
-- Apply Scale
-----------------------------------------------------------------------------------------------------------------------
local function Scaled(num)
    if not num then
        return nil
    end
    return num * addonDB.Options.Scaling
end

-----------------------------------------------------------------------------------------------------------------------
-- Set Scale agnostic Width
-----------------------------------------------------------------------------------------------------------------------
local function SetWidth(frame, width)
    frame:SetWidth(Scaled(width))
end

-----------------------------------------------------------------------------------------------------------------------
-- Set Scale agnostic Height 
-----------------------------------------------------------------------------------------------------------------------
local function SetHeight(frame, height)
    frame:SetHeight(Scaled(height))
end

-----------------------------------------------------------------------------------------------------------------------
-- Set Scale agnostic Size 
-----------------------------------------------------------------------------------------------------------------------
local function SetSize(frame, width, height)
    frame:SetSize(Scaled(width), Scaled(height))
end

-----------------------------------------------------------------------------------------------------------------------
-- Set Scale agnostic Position 
-----------------------------------------------------------------------------------------------------------------------
local function SetPoint(frame, point, relativeTo, relativePoint, offsetX, offsetY)
    if relativeTo == nil and relativePoint == nil and offsetX == nil and offsetY == nil then
        frame:SetPoint(point)
    elseif offsetX == nil and offsetY == nil then
        frame:SetPoint(point, Scaled(relativeTo), Scaled(relativePoint))
    else
        frame:SetPoint(point, relativeTo, relativePoint, Scaled(offsetX), Scaled(offsetY))
    end
end

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
-- Get Active Configuration
-----------------------------------------------------------------------------------------------------------------------
local function GetActiveConfig() 
    for _, v in pairs(addonDB.Widgets.Setups) do
        if v.Tab.Button.pushed then
            for _, c in pairs(addonDB.Configs) do
                if c.Name == v.Name then
                    return c
                end
            end
            break
        end
    end
    return nil
end

-----------------------------------------------------------------------------------------------------------------------
-- Get Setup By Name
-----------------------------------------------------------------------------------------------------------------------
local function GetSetupByName(name) 
    for k, v in pairs(addonDB.Widgets.Setups) do
        if v.Name == name then
            return k, v
        end
    end
    return nil
end

-----------------------------------------------------------------------------------------------------------------------
-- Get Config By Name
-----------------------------------------------------------------------------------------------------------------------
local function GetConfigByName(name) 
    for k, v in pairs(addonDB.Configs) do
        if v.Name == name then
            return k, v
        end
    end
    return nil
end

-----------------------------------------------------------------------------------------------------------------------
-- Get Active Setup
-----------------------------------------------------------------------------------------------------------------------
local function GetActiveSetup() 
    for _, v in pairs(addonDB.Widgets.Setups) do
        if v.Tab.Button.pushed then
            return v
        end
    end
    return nil
end

-----------------------------------------------------------------------------------------------------------------------
-- Get First Element of Array
-----------------------------------------------------------------------------------------------------------------------
local function GetFirstValue(table)
    for key, value in pairs(table) do
        return key, value
    end
    return nil, nil
end

-----------------------------------------------------------------------------------------------------------------------
-- Remove First Element
-----------------------------------------------------------------------------------------------------------------------
local function RemoveFirstElement(t)
    for key, value in pairs(t) do
        table.remove(t, key)
        return value
    end
    return nil
end

-----------------------------------------------------------------------------------------------------------------------
-- Toggle Frame
-----------------------------------------------------------------------------------------------------------------------
local function ToggleFrame(frame)
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Hide Frame
-----------------------------------------------------------------------------------------------------------------------
local function HideFrame(frame)
    if frame:IsShown() then
        frame:Hide()
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Show Frame
-----------------------------------------------------------------------------------------------------------------------
local function ShowFrame(frame)
    if not frame:IsShown() then
        frame:Show()
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Get All By Filter
-----------------------------------------------------------------------------------------------------------------------
local function GetAllWithFilter(t, filter)
    local collection = {}
    for k, v in pairs(t) do
        if filter(k, v) then
            collection[k] = v
        end
    end
    return collection
end

-----------------------------------------------------------------------------------------------------------------------
-- Get Value By Filter
-----------------------------------------------------------------------------------------------------------------------
local function GetValueByFilter(t, filter)
    for k, v in pairs(t) do
        if filter(k, v) then
            return k, v
        end
    end
    return nil, nil 
end

-----------------------------------------------------------------------------------------------------------------------
-- Add Hover Effect To Button
-----------------------------------------------------------------------------------------------------------------------
local function AddHover(button, withPushed)
    button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    if withPushed then
        button:SetScript("OnLeave", function(self)
            if self.pushed then
                local c = color.Gold
                self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            else
                local c = color.LightGray
                self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            end
        end)
    else
        button:SetScript("OnLeave", function(self)
            local c = color.LightGray
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end)
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Apply to each Value
-----------------------------------------------------------------------------------------------------------------------
local function ApplyToEach(t, lambda, ...)
    for k, v in pairs(t) do
        lambda(k, v, ...)
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Rearrange Frames with Offsets
-----------------------------------------------------------------------------------------------------------------------
local function RearrangeFrames(t, anchor, xOffset, yOffset, getFrame, startX, startY)
    local x, y = startX or 0, startY or 0
    for k, v in pairs(t) do
        local frame = getFrame(v)
        frame:ClearAllPoints()
        SetPoint(frame, anchor, x, y)
        x = x + xOffset
        y = y + yOffset
    end
    return x, y
end

-----------------------------------------------------------------------------------------------------------------------
-- Remove Values that fulfill the filter requirement
-----------------------------------------------------------------------------------------------------------------------
local function RemoveWithFilter(t, filter)
    for k, v in pairs(t) do
        if filter(k, v) then
            table.remove(t, k)
            return
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Check if Dialog is Shown
-----------------------------------------------------------------------------------------------------------------------
local function IsDialogShown()
    for k, v in pairs(addonDB.Widgets.Dialogs) do
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
    return addonDB.Widgets.Dialogs.Roll.Frame:IsShown()
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
    return tonumber(match[2])
end

-----------------------------------------------------------------------------------------------------------------------
-- Set Icon Texture
-----------------------------------------------------------------------------------------------------------------------
local function SetItemTexture(icon, texture, itemLink)
    local itemTexture = select(10, GetItemInfo(itemLink))
    if itemTexture then
        texture:SetTexture(itemTexture)
    else
        local itemId = GetIdFromLink(itemLink)
        icon:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        icon:SetScript("OnEvent", function(self, event, arg)
            if arg == itemId or arg == tonumber(itemId) then
                local it = select(10, GetItemInfo(itemLink))
                texture:SetTexture(it)
                self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
            end
        end)
    end
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
-- Serialize Table
-----------------------------------------------------------------------------------------------------------------------
local function Serialize(t)
    local serialized = LibSerialize:SerializeEx({errorOnUnserializableType = false}, t)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return encoded
end

-----------------------------------------------------------------------------------------------------------------------
-- Serialize Configuration
-----------------------------------------------------------------------------------------------------------------------
local function SerializeConfig(config)
    local playerName, realm = UnitFullName("player")
    config.Sharer = playerName.."-"..realm
    return Serialize(config)
end

-----------------------------------------------------------------------------------------------------------------------
-- Deserialize Table
-----------------------------------------------------------------------------------------------------------------------
local function Deserialize(encoded)
    local compressed = LibDeflate:DecodeForPrint(encoded)
    local serialized = LibDeflate:DecompressDeflate(compressed)
    local success, deserialized = LibSerialize:Deserialize(serialized)
    return success, deserialized 
end

-----------------------------------------------------------------------------------------------------------------------
-- Share Configuration
-----------------------------------------------------------------------------------------------------------------------
local function ShareConfiguration(config) 
    if addonDB.Sharing and addonDB.Tracking.Active and config.Name == addonDB.Tracking.Name then
        local written = 1
        table.sort(config.PlayerInfos, function(a, b) return a.Name < b.Name end)
        local encoded = SerializeConfig(config)
        if encoded == addonDB.LastEncodedConfig then
            return
        end
        addonDB.LastEncodedConfig = encoded
        addonDB.Identifier = addonDB.Identifier or 0
        local id = addonDB.Identifier
        addonDB.Identifier = addonDB.Identifier + 1
        while written < #encoded do
            local endIndex = math.min(written + 150, #encoded)
            local substr = string.sub(encoded, written, endIndex)

            local success = C_ChatInfo.SendAddonMessage("RTConfig", id.."$|$"..written.."$|$"..endIndex.."$|$"..#encoded.."$|$"..substr, (IsInRaid() and "RAID") or (IsInGroup() and "PARTY") or "WHISPER", UnitName("player"))
            if not success then
                print("[ERROR] RaidTables: Sharing failed!")
                break
            end

            written = endIndex + 1
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Share Summary
-----------------------------------------------------------------------------------------------------------------------
local function ShareLootSummary(items) 
    if addonDB.Sharing and addonDB.Tracking.Active then
        local written = 1
        local encoded = Serialize(items)
        addonDB.Identifier = addonDB.Identifier or 0
        local id = addonDB.Identifier
        addonDB.Identifier = addonDB.Identifier + 1
        while written < #encoded do
            local endIndex = math.min(written + 150, #encoded)
            local substr = string.sub(encoded, written, endIndex)

            local success = C_ChatInfo.SendAddonMessage("RTSummary", id.."$|$"..written.."$|$"..endIndex.."$|$"..#encoded.."$|$"..substr, (IsInRaid() and "RAID") or (IsInGroup() and "PARTY") or "WHISPER", UnitName("player"))
            if not success then
                print("[ERROR] RaidTables: Sharing failed!")
                break
            end

            written = endIndex + 1
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Disable Tracking
-----------------------------------------------------------------------------------------------------------------------
local function DisableTracking()
    addonDB.Tracking.Name = nil
    addonDB.Tracking.Active = false

    addonDB.Widgets.Share.Frame:Hide()
    addonDB.Widgets.Share.Checkbox:SetChecked(false)
end

-----------------------------------------------------------------------------------------------------------------------
-- Enable Tacking
-----------------------------------------------------------------------------------------------------------------------
local function EnableTracking(name, share)
    addonDB.Tracking.Name = name 
    addonDB.Tracking.Active = true

    addonDB.Widgets.Share.Checkbox:SetChecked(share)

    local setup = GetActiveSetup()
    if setup and setup.Name == name then
        addonDB.Widgets.Share.Frame:Show()
    end

    ShareConfiguration(select(2, GetConfigByName(name)))
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
        edgeSize = math.max(1, Scaled(2)),
    })
    button:SetBackdropColor(colorBackground.r, colorBackground.g, colorBackground.b, colorBackground.a)
    button:SetBackdropBorderColor(colorBorder.r, colorBorder.g, colorBorder.b, colorBorder.a)

    local buttonText = button:CreateFontString(nil, "ARTWORK")
    SetPoint(buttonText, "CENTER")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", Scaled(12), "BOLD")
    if textColor then
        buttonText:SetTextColor(textColor.r, textColor.g, textColor.b)
    else
        buttonText:SetTextColor(1, 0.8, 0) 
    end
    buttonText:SetText(label)

    SetSize(button, width, height)
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
    SetHeight(line, 2) -- set the height of the line
    SetWidth(line, width)
    SetPoint(line, "TOPLEFT", x, y)
    return line
end

-----------------------------------------------------------------------------------------------------------------------
-- Create Label 
-----------------------------------------------------------------------------------------------------------------------
local function CreateLabel(label, parent, x, y, colour, anchor, fontSize)
    local c = colour or color.Gold
    local labelString = parent:CreateFontString(nil, "ARTWORK")
    labelString:SetFont("Fonts\\FRIZQT__.TTF", Scaled(fontSize or 12), "NONE")
    labelString:SetTextColor(c.r, c.g, c.b)
    labelString:SetText(label)
    if x ~= nil and y ~= nil then
        SetPoint(labelString, anchor or "TOPLEFT", x, y)
    end
    return labelString
end

-----------------------------------------------------------------------------------------------------------------------
-- Create Heading
-----------------------------------------------------------------------------------------------------------------------
local function CreateHeading(label, width, parent, x, y, noLine, fontSize)
    local labelString = CreateLabel(label, parent, x, y, color.Gold, nil, fontSize)
    local labelWidth = GetWidth(labelString)
    local lineWidth = (width - labelWidth - 10) * 0.5
    local yOffset = ((fontSize or 12) - 12) / 2

    SetPoint(labelString, "TOPLEFT", x + lineWidth + 5, y)

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
local function HandleLootAssignment() 
    -------------------------------------------------------------------------------------------------------------------
    -- Dont show new Loot Assignment if Summary is opened
    -------------------------------------------------------------------------------------------------------------------
    if addonDB.Widgets.Summary.Frame:IsShown() then
        return
    end
    -------------------------------------------------------------------------------------------------------------------
    -- Next Item to be rolled on exists
    -------------------------------------------------------------------------------------------------------------------
    if #addonDB.Widgets.Dialogs.Roll.Items > 0 then
        ---------------------------------------------------------------------------------------------------------------
        -- The previous Item isn't finished
        ---------------------------------------------------------------------------------------------------------------
        if addonDB.Widgets.Dialogs.Roll.ActiveItemLink then
            return
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update the Item Icon
        ---------------------------------------------------------------------------------------------------------------
        addonDB.Widgets.Dialogs.Roll.ActiveItemLink = RemoveFirstElement(addonDB.Widgets.Dialogs.Roll.Items)
        local itemId = GetIdFromLink(addonDB.Widgets.Dialogs.Roll.ActiveItemLink)

        ---------------------------------------------------------------------------------------------------------------
        -- Check if Item is Tier, Rare or Normal
        ---------------------------------------------------------------------------------------------------------------
        if IsInArray(addonDB.Options.TierItems, itemId) then
            addonDB.Widgets.Dialogs.Roll.Tier.Button.pushed = true
            addonDB.Widgets.Dialogs.Roll.Tier.Button:Disable()
            addonDB.Widgets.Dialogs.Roll.TypeSelection = "Tier"
            addonDB.Widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
        elseif IsInArray(addonDB.Options.RareItems, itemId) then
            addonDB.Widgets.Dialogs.Roll.Rare.Button.pushed = true
            addonDB.Widgets.Dialogs.Roll.Rare.Button:Disable()
            addonDB.Widgets.Dialogs.Roll.TypeSelection = "Rare"
            addonDB.Widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
        else
            addonDB.Widgets.Dialogs.Roll.Normal.Button.pushed = true
            addonDB.Widgets.Dialogs.Roll.Normal.Button:Disable()
            addonDB.Widgets.Dialogs.Roll.TypeSelection = "Normal"
            addonDB.Widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update GameTooltip for Item
        ---------------------------------------------------------------------------------------------------------------
        SetItemTexture(addonDB.Widgets.Dialogs.Roll.ItemIcon, addonDB.Widgets.Dialogs.Roll.ItemTexture, addonDB.Widgets.Dialogs.Roll.ActiveItemLink)
        addonDB.Widgets.Dialogs.Roll.ItemIcon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(addonDB.Widgets.Dialogs.Roll.ActiveItemLink)
            GameTooltip:Show()
        end)
        addonDB.Widgets.Dialogs.Roll.ItemIcon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        ---------------------------------------------------------------------------------------------------------------
        -- Show Addon Table and Roll Frame
        ---------------------------------------------------------------------------------------------------------------
        ShowFrame(addonDB.Widgets.Addon)
        ShowFrame(addonDB.Widgets.Dialogs.Roll.Frame)
    else
        ---------------------------------------------------------------------------------------------------------------
        -- No Item to roll an exists, so hide Roll Frame
        ---------------------------------------------------------------------------------------------------------------
        HideFrame(addonDB.Widgets.Dialogs.Roll.Frame)

        ---------------------------------------------------------------------------------------------------------------
        -- No item was assigned to player, so no summary window necessary
        ---------------------------------------------------------------------------------------------------------------
        if #addonDB.Widgets.Dialogs.Roll.AssignmentList == 0 then
            return
        end

        ---------------------------------------------------------------------------------------------------------------
        -- For each Assignment create List Item in Summary View
        ---------------------------------------------------------------------------------------------------------------
        for _, assignment in pairs(addonDB.Widgets.Dialogs.Roll.AssignmentList) do
            -----------------------------------------------------------------------------------------------------------
            -- Check if we can reuse a previous freed frame
            -----------------------------------------------------------------------------------------------------------
            local item = RemoveFirstElement(addonDB.Widgets.Summary.FreeItems)

            -----------------------------------------------------------------------------------------------------------
            -- Create New Frame if necessary
            -----------------------------------------------------------------------------------------------------------
            if not item then
                item = {}
                -- Setup frame
                item.Frame = CreateFrame("Frame", nil, addonDB.Widgets.Summary.Frame, "BackdropTemplate")
                SetSize(item.Frame, GetWidth(addonDB.Widgets.Summary.Frame) - 20, 52)
                item.Frame:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = math.max(1, Scaled(2)),
                })
                item.Frame:SetBackdropColor(0, 0, 0, 1)
                item.Frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

                -- Setup item icon
                item.ItemIcon = CreateFrame("Frame", nil, item.Frame, "BackdropTemplate")
                SetSize(item.ItemIcon, 32, 32)
                SetPoint(item.ItemIcon, "TOPLEFT", 20, -10)
                item.ItemIcon:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = math.max(1, Scaled(2)),
                })
                item.ItemIcon:SetBackdropColor(0, 0, 0, 1)
                item.ItemIcon:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

                item.ItemTexture = item.ItemIcon:CreateTexture(nil, "ARTWORK")
                item.ItemTexture:SetAllPoints()

                -- Setup Player Label
                item.PlayerLabel = CreateLabel("", item.Frame, 70, 0, color.Gold, "LEFT", 12)
            end

            -- Insert
            table.insert(addonDB.Widgets.Summary.Items, item)

            -----------------------------------------------------------------------------------------------------------
            -- Show Item Frame
            -----------------------------------------------------------------------------------------------------------
            ShowFrame(item.Frame)

            -----------------------------------------------------------------------------------------------------------
            -- Update GameTooltip for Item Icon
            -----------------------------------------------------------------------------------------------------------
            SetItemTexture(item.ItemIcon, item.ItemTexture, assignment.ItemLink)
            item.ItemIcon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(assignment.ItemLink)
                GameTooltip:Show()
            end)
            item.ItemIcon:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            -----------------------------------------------------------------------------------------------------------
            -- Update Player Label
            -----------------------------------------------------------------------------------------------------------
            item.PlayerLabel:SetText(assignment.PlayerName)
            local c = classColor[assignment.Class]
            item.PlayerLabel:SetTextColor(c.r, c.g, c.b, c.a)

            -----------------------------------------------------------------------------------------------------------
            -- Update Position in Summary Frame
            -----------------------------------------------------------------------------------------------------------
            SetPoint(item.Frame, "TOPLEFT", 10, -30 - 54 * (#addonDB.Widgets.Summary.Items - 1))
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update Height to have Space for Close Button (We dont use Scroll view because of 6 items at most)
        ---------------------------------------------------------------------------------------------------------------
        SetHeight(addonDB.Widgets.Summary.Frame, 30 + 54 * #addonDB.Widgets.Summary.Items + 45)
        
        ---------------------------------------------------------------------------------------------------------------
        -- If Addon Frame is shown, move Summary frame to the right of it, else in the center
        ---------------------------------------------------------------------------------------------------------------
        if addonDB.Widgets.Addon:IsShown() then
            addonDB.Widgets.Summary.Frame:ClearAllPoints()
            SetPoint(addonDB.Widgets.Summary.Frame, "TOPLEFT", addonDB.Widgets.Addon, "TOPRIGHT", 10, 0)
        else
            addonDB.Widgets.Summary.Frame:ClearAllPoints()
            SetPoint(addonDB.Widgets.Summary.Frame, "CENTER", 0, 0)
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Show Summary Frame
        ---------------------------------------------------------------------------------------------------------------
        ShowFrame(addonDB.Widgets.Summary.Frame)

        ShareLootSummary(addonDB.Widgets.Dialogs.Roll.AssignmentList)
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Function to Create a Player Row Frame for the Table View
-----------------------------------------------------------------------------------------------------------------------
local function CreatePlayerFrame(player, config, setup, parent, playerInfo, width, x, y)
    -------------------------------------------------------------------------------------------------------------------
    -- Setup Locals
    -------------------------------------------------------------------------------------------------------------------
    local colorBackground, colorBorder = color.DarkGray, color.LightGray
    local name, colour, rare, tier, normal = playerInfo.Name, classColor[playerInfo.Class], playerInfo.Rare, playerInfo.Tier, playerInfo.Normal

    -------------------------------------------------------------------------------------------------------------------
    -- Create Player Container (if not reusable)
    -------------------------------------------------------------------------------------------------------------------
    if player.Container == nil then
        player.Container = CreateFrame("Button", nil, parent, "BackdropTemplate")
        SetWidth(player.Container, width)
        SetHeight(player.Container, 34)
        player.Container:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = math.max(1, Scaled(2)),
        })
        player.Container:SetBackdropColor(colorBackground.r, colorBackground.g, colorBackground.b, colorBackground.a)
        player.Container:SetBackdropBorderColor(colorBorder.r, colorBorder.g, colorBorder.b, colorBorder.a)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Update Position and Name
    -------------------------------------------------------------------------------------------------------------------
    SetPoint(player.Container, "TOPLEFT", x, y)
    player.PlayerName = name

    -------------------------------------------------------------------------------------------------------------------
    -- Create Remove Button (if not reusable)
    -------------------------------------------------------------------------------------------------------------------
    if player.Remove == nil then
        player.Remove = {}
        player.Remove.Button, player.Remove.Text = CreateButton(player.Container, "X", 30, 28, color.DarkGray, color.DarkGray, color.Gold)
        SetPoint(player.Remove.Button, "TOPLEFT", 5, -3)
        player.Remove.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.Remove.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Update OnClick
    -------------------------------------------------------------------------------------------------------------------
    player.Remove.Button:SetScript("OnClick", function(self)
        ---------------------------------------------------------------------------------------------------------------
        -- Skip if Dialog is shown
        ---------------------------------------------------------------------------------------------------------------
        if IsDialogShown() then
            return
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Remove the Player  
        ---------------------------------------------------------------------------------------------------------------
        local k, v = GetValueByFilter(setup.Players, function(k, v) return v == player end)
        RemoveWithFilter(config.PlayerInfos, function(_, p) return p.Name == v.PlayerName end)
        HideFrame(v.Container)
        -- Move entry to storage for later reuse
        table.insert(addonDB.Widgets.FreePlayers, v)
        table.remove(setup.Players, k)
        -- Rearrange frames
        local _, y = RearrangeFrames(setup.Players, "TOPLEFT", 0, -32, function(q) return q.Container end, 10, 0)
        SetPoint(setup.TableBottomLine, "TOPLEFT", 5, y + 2)
        -- Share update
        ShareConfiguration(config)
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Player Name Label 
    -------------------------------------------------------------------------------------------------------------------
    if player.NameText then
        player.NameText:SetText(name)
        player.NameText:SetTextColor(colour.r, colour.g, colour.b)
    else
        player.NameText = CreateLabel(name, player.Container, 65, -10, colour)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Rare Count Label
    -------------------------------------------------------------------------------------------------------------------
    if player.RareText then
        player.RareText:SetText(rare)
    else
        player.RareText = CreateLabel(rare, player.Container, nil, nil, color.White)
        SetPoint(player.RareText, "CENTER", player.Container, "TOPLEFT", 440, -17)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Rare Diff Label
    -------------------------------------------------------------------------------------------------------------------
    if player.RareDiffText then
        player.RareDiffText:SetText(0)
    else
        player.RareDiffText = CreateLabel(0, player.Container, nil, nil, color.White)
        SetPoint(player.RareDiffText, "CENTER", player.Container, "TOPLEFT", 500, -17)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Rare Add Button
    -------------------------------------------------------------------------------------------------------------------
    if player.RareAdd == nil then
        player.RareAdd = {}
        player.RareAdd.Button, player.RareAdd.Text = CreateButton(player.Container, "Add", 50, 28, color.DarkGray, color.DarkGray, color.Gold)
        SetPoint(player.RareAdd.Button, "TOPLEFT", 550, -3)
        player.RareAdd.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.RareAdd.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Update OnClick for Rare Add Button
    -------------------------------------------------------------------------------------------------------------------
    player.RareAdd.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update Diff Text
        ---------------------------------------------------------------------------------------------------------------
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

        ---------------------------------------------------------------------------------------------------------------
        -- Update Order
        ---------------------------------------------------------------------------------------------------------------
        local name = GetValueByFilter(setup.Order, function(k, v) return v.Button.pushed end)
        local _, activeOrder = GetValueByFilter(orderConfigs, function(k, v) return v.Name == name end)

        if activeOrder then
            local vOffset = 0
            local sortedOrder = {}

            -----------------------------------------------------------------------------------------------------------
            -- Sort Players in Setup
            -----------------------------------------------------------------------------------------------------------
            table.sort(setup.Players, activeOrder["Callback"])
            ApplyToEach(setup.Players, function(k, v) 
                sortedOrder[v.PlayerName] = k 
                SetPoint(v.Container, "TOPLEFT", 10, vOffset)
                vOffset = vOffset - 32
            end)
            SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

            -----------------------------------------------------------------------------------------------------------
            -- Apply new Order in Configuration
            -----------------------------------------------------------------------------------------------------------
            local _, config = GetValueByFilter(addonDB.Configs, function(k, v) return v.Name == setup.Name end)
            table.sort(config.PlayerInfos, function(a, b) return sortedOrder[a.Name] < sortedOrder[b.Name] end)
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Rare Remove Button
    -------------------------------------------------------------------------------------------------------------------
    if player.RareRemove == nil then
        player.RareRemove = {}
        player.RareRemove.Button, player.RareRemove.Text = CreateButton(player.Container, "Remove", 80, 28, color.DarkGray, color.DarkGray, color.Gold)
        SetPoint(player.RareRemove.Button, "TOPLEFT", 610, -3)
        player.RareRemove.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.RareRemove.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Update Rare Remove Button
    -------------------------------------------------------------------------------------------------------------------
    player.RareRemove.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update Diff Text
        ---------------------------------------------------------------------------------------------------------------
        local num = math.max(tonumber(player.RareDiffText:GetText()) - 1, -tonumber(player.RareText:GetText()))
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

        ---------------------------------------------------------------------------------------------------------------
        -- Update Order
        ---------------------------------------------------------------------------------------------------------------
        local name = GetValueByFilter(setup.Order, function(k, v) return v.Button.pushed end)
        local _, activeOrder = GetValueByFilter(orderConfigs, function(k, v) return v.Name == name end)

        if activeOrder then
            local vOffset = 0
            local sortedOrder = {}

            -----------------------------------------------------------------------------------------------------------
            -- Sort Players in Setup
            -----------------------------------------------------------------------------------------------------------
            table.sort(setup.Players, activeOrder["Callback"])
            ApplyToEach(setup.Players, function(k, v) 
                sortedOrder[v.PlayerName] = k 
                SetPoint(v.Container, "TOPLEFT", 10, vOffset)
                vOffset = vOffset - 32
            end)
            SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

            -----------------------------------------------------------------------------------------------------------
            -- Apply new Order in Configuration
            -----------------------------------------------------------------------------------------------------------
            local _, config = GetValueByFilter(addonDB.Configs, function(k, v) return v.Name == setup.Name end)
            table.sort(config.PlayerInfos, function(a, b) return sortedOrder[a.Name] < sortedOrder[b.Name] end)
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Tier Count Label
    -------------------------------------------------------------------------------------------------------------------
    if player.TierText then
        player.TierText:SetText(tier)
    else
        player.TierText = CreateLabel(tier, player.Container, nil, nil, color.White)
        SetPoint(player.TierText, "CENTER", player.Container, "TOPLEFT", 745, -17)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Tier Diff Label
    -------------------------------------------------------------------------------------------------------------------
    if player.TierDiffText then
        player.TierDiffText:SetText(0)
    else
        player.TierDiffText = CreateLabel(0, player.Container, nil, nil, color.White)
        SetPoint(player.TierDiffText, "CENTER", player.Container, "TOPLEFT", 805, -17)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Tier Add Button
    -------------------------------------------------------------------------------------------------------------------
    if player.TierAdd == nil then
        player.TierAdd = {}
        player.TierAdd.Button, player.TierAdd.Text = CreateButton(player.Container, "Add", 50, 28, color.DarkGray, color.DarkGray, color.Gold)
        SetPoint(player.TierAdd.Button, "TOPLEFT", 855, -3)
        player.TierAdd.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.TierAdd.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Update OnClick for Tier Add Button
    -------------------------------------------------------------------------------------------------------------------
    player.TierAdd.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update Diff Text
        ---------------------------------------------------------------------------------------------------------------
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

        ---------------------------------------------------------------------------------------------------------------
        -- Update Order
        ---------------------------------------------------------------------------------------------------------------
        local name = GetValueByFilter(setup.Order, function(k, v) return v.Button.pushed end)
        local _, activeOrder = GetValueByFilter(orderConfigs, function(k, v) return v.Name == name end)

        if activeOrder then
            local vOffset = 0
            local sortedOrder = {}

            -----------------------------------------------------------------------------------------------------------
            -- Sort Players in Setup
            -----------------------------------------------------------------------------------------------------------
            table.sort(setup.Players, activeOrder["Callback"])
            ApplyToEach(setup.Players, function(k, v) 
                sortedOrder[v.PlayerName] = k 
                SetPoint(v.Container, "TOPLEFT", 10, vOffset)
                vOffset = vOffset - 32
            end)
            SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

            -----------------------------------------------------------------------------------------------------------
            -- Apply new Order in Configuration
            -----------------------------------------------------------------------------------------------------------
            local _, config = GetValueByFilter(addonDB.Configs, function(k, v) return v.Name == setup.Name end)
            table.sort(config.PlayerInfos, function(a, b) return sortedOrder[a.Name] < sortedOrder[b.Name] end)
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Tier Remove Button
    -------------------------------------------------------------------------------------------------------------------
    if player.TierRemove == nil then
        player.TierRemove = {}
        player.TierRemove.Button, player.TierRemove.Text = CreateButton(player.Container, "Remove", 80, 28, color.DarkGray, color.DarkGray, color.Gold)
        SetPoint(player.TierRemove.Button, "TOPLEFT", 915, -3)
        player.TierRemove.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.TierRemove.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Update Tier Remove Button
    -------------------------------------------------------------------------------------------------------------------
    player.TierRemove.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update Diff Text
        ---------------------------------------------------------------------------------------------------------------
        local num = math.max(tonumber(player.TierDiffText:GetText()) - 1, -tonumber(player.TierText:GetText()))
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

        ---------------------------------------------------------------------------------------------------------------
        -- Update Order
        ---------------------------------------------------------------------------------------------------------------
        local name = GetValueByFilter(setup.Order, function(k, v) return v.Button.pushed end)
        local _, activeOrder = GetValueByFilter(orderConfigs, function(k, v) return v.Name == name end)

        if activeOrder then
            local vOffset = 0
            local sortedOrder = {}

            -----------------------------------------------------------------------------------------------------------
            -- Sort Players in Setup
            -----------------------------------------------------------------------------------------------------------
            table.sort(setup.Players, activeOrder["Callback"])
            ApplyToEach(setup.Players, function(k, v) 
                sortedOrder[v.PlayerName] = k 
                SetPoint(v.Container, "TOPLEFT", 10, vOffset)
                vOffset = vOffset - 32
            end)
            SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

            -----------------------------------------------------------------------------------------------------------
            -- Apply new Order in Configuration
            -----------------------------------------------------------------------------------------------------------
            local _, config = GetValueByFilter(addonDB.Configs, function(k, v) return v.Name == setup.Name end)
            table.sort(config.PlayerInfos, function(a, b) return sortedOrder[a.Name] < sortedOrder[b.Name] end)
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Normal Count Label
    -------------------------------------------------------------------------------------------------------------------
    if player.NormalText then
        player.NormalText:SetText(normal)
    else
        player.NormalText = CreateLabel(normal, player.Container, nil, nil, color.White)
        SetPoint(player.NormalText, "CENTER", player.Container, "TOPLEFT", 1050, -17)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Normal Diff Label
    -------------------------------------------------------------------------------------------------------------------
    if player.NormalDiffText then
        player.NormalDiffText:SetText(0)
    else
        player.NormalDiffText = CreateLabel(0, player.Container, nil, nil, color.White)
        SetPoint(player.NormalDiffText, "CENTER", player.Container, "TOPLEFT", 1110, -17)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Normal Add Button
    -------------------------------------------------------------------------------------------------------------------
    if player.NormalAdd == nil then
        player.NormalAdd = {}
        player.NormalAdd.Button, player.NormalAdd.Text = CreateButton(player.Container, "Add", 50, 28, color.DarkGray, color.DarkGray, color.Gold)
        SetPoint(player.NormalAdd.Button, "TOPLEFT", 1160, -3)
        player.NormalAdd.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.NormalAdd.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Update OnClick for Normal Add Button
    -------------------------------------------------------------------------------------------------------------------
    player.NormalAdd.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update Diff Text
        ---------------------------------------------------------------------------------------------------------------
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

        ---------------------------------------------------------------------------------------------------------------
        -- Update Order
        ---------------------------------------------------------------------------------------------------------------
        local name = GetValueByFilter(setup.Order, function(k, v) return v.Button.pushed end)
        local _, activeOrder = GetValueByFilter(orderConfigs, function(k, v) return v.Name == name end)

        if activeOrder then
            local vOffset = 0
            local sortedOrder = {}

            -----------------------------------------------------------------------------------------------------------
            -- Sort Players in Setup
            -----------------------------------------------------------------------------------------------------------
            table.sort(setup.Players, activeOrder["Callback"])
            ApplyToEach(setup.Players, function(k, v) 
                sortedOrder[v.PlayerName] = k 
                SetPoint(v.Container, "TOPLEFT", 10, vOffset)
                vOffset = vOffset - 32
            end)
            SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

            -----------------------------------------------------------------------------------------------------------
            -- Apply new Order in Configuration
            -----------------------------------------------------------------------------------------------------------
            local _, config = GetValueByFilter(addonDB.Configs, function(k, v) return v.Name == setup.Name end)
            table.sort(config.PlayerInfos, function(a, b) return sortedOrder[a.Name] < sortedOrder[b.Name] end)
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Create Normal Remove Button
    -------------------------------------------------------------------------------------------------------------------
    if player.NormalRemove == nil then
        player.NormalRemove = {}
        player.NormalRemove.Button, player.NormalRemove.Text = CreateButton(player.Container, "Remove", 80, 28, color.DarkGray, color.DarkGray, color.Gold)
        SetPoint(player.NormalRemove.Button, "TOPLEFT", 1220, -3)
        player.NormalRemove.Button:SetScript("OnEnter", function(self)
            local gold = color.Gold
            self:SetBackdropBorderColor(gold.r, gold.g, gold.b, gold.a)
        end)
        player.NormalRemove.Button:SetScript("OnLeave", function(self)
            local dark = color.DarkGray
            self:SetBackdropBorderColor(dark.r, dark.g, dark.b, dark.a)
        end)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Update Normal Remove Button
    -------------------------------------------------------------------------------------------------------------------
    player.NormalRemove.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update Diff Text
        ---------------------------------------------------------------------------------------------------------------
        local num = math.max(tonumber(player.NormalDiffText:GetText()) - 1, -tonumber(player.NormalText:GetText()))
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

        ---------------------------------------------------------------------------------------------------------------
        -- Update Order
        ---------------------------------------------------------------------------------------------------------------
        local name = GetValueByFilter(setup.Order, function(k, v) return v.Button.pushed end)
        local _, activeOrder = GetValueByFilter(orderConfigs, function(k, v) return v.Name == name end)

        if activeOrder then
            local vOffset = 0
            local sortedOrder = {}

            -----------------------------------------------------------------------------------------------------------
            -- Sort Players in Setup
            -----------------------------------------------------------------------------------------------------------
            table.sort(setup.Players, activeOrder["Callback"])
            ApplyToEach(setup.Players, function(k, v) 
                sortedOrder[v.PlayerName] = k 
                SetPoint(v.Container, "TOPLEFT", 10, vOffset)
                vOffset = vOffset - 32
            end)
            SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

            -----------------------------------------------------------------------------------------------------------
            -- Apply new Order in Configuration
            -----------------------------------------------------------------------------------------------------------
            local _, config = GetValueByFilter(addonDB.Configs, function(k, v) return v.Name == setup.Name end)
            table.sort(config.PlayerInfos, function(a, b) return sortedOrder[a.Name] < sortedOrder[b.Name] end)
        end
    end)

    -------------------------------------------------------------------------------------------------------------------
    -- Return Player Container
    -------------------------------------------------------------------------------------------------------------------
    return player
end

-----------------------------------------------------------------------------------------------------------------------
-- Function to Create a New Raid Content Frame from Configuration
-----------------------------------------------------------------------------------------------------------------------
local function SetupNewEntry(cfg, show)
    -------------------------------------------------------------------------------------------------------------------
    -- Setup Local
    -------------------------------------------------------------------------------------------------------------------
    local name = cfg.Name
    local characterWidth = 350
    local countWidth = 300

    -------------------------------------------------------------------------------------------------------------------
    -- Create Content Table or Retrieve Previously Freed Table
    -------------------------------------------------------------------------------------------------------------------
    local setup = RemoveFirstElement(addonDB.Widgets.FreeSetups) or {}
    table.insert(addonDB.Widgets.Setups, setup)

    -------------------------------------------------------------------------------------------------------------------
    -- Setup Name
    -------------------------------------------------------------------------------------------------------------------
    setup.Name = name

    -------------------------------------------------------------------------------------------------------------------
    -- Create Content Container
    -------------------------------------------------------------------------------------------------------------------
    if setup.Content == nil then
        setup.Content = CreateFrame("Frame", nil, addonDB.Widgets.Content)
        SetPoint(setup.Content, "TOPLEFT", 0, 0)
        SetPoint(setup.Content, "BOTTOMRIGHT", 0, 0)
    end
    local setupWidth = GetWidth(setup.Content)

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
    local offsetX = 0
    for orderIdx, orderCfg in pairs(orderConfigs) do
        local orderName = orderCfg.Name

        ---------------------------------------------------------------------------------------------------------------
        -- Create Order Button
        ---------------------------------------------------------------------------------------------------------------
        if setup.Order[orderName] == nil then
            setup.Order[orderName] = {}
            setup.Order[orderName]["Button"], setup.Order[orderName]["Text"] = CreateButton(setup.Content, orderName, 150, 40, color.DarkGray, color.LightGray)
        end

        ---------------------------------------------------------------------------------------------------------------
        -- Update Order Button
        ---------------------------------------------------------------------------------------------------------------
        local orderButton, _ = setup.Order[orderName]["Button"], setup.Order[orderName]["Text"]
        orderButton.pushed = false
        orderButton:Enable()
        orderButton:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, color.DarkGray.a)
        orderButton:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, color.LightGray.a)
        SetPoint(orderButton, "TOPLEFT", 20 + offsetX, -30)
        AddHover(orderButton, true)

        ---------------------------------------------------------------------------------------------------------------
        -- Update OnClick
        ---------------------------------------------------------------------------------------------------------------
        orderButton:SetScript("OnClick", function(self)
            if IsDialogShown() and not IsRollShown() then
                return
            end

            -----------------------------------------------------------------------------------------------------------
            -- Update Button
            -----------------------------------------------------------------------------------------------------------
            local c = color.Gold
            self.pushed = true
            self:Disable()
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)

            -----------------------------------------------------------------------------------------------------------
            -- Update Order
            -----------------------------------------------------------------------------------------------------------
            local setup = GetActiveSetup()
            local config = GetActiveConfig()

            local vOffset = 0
            local sortedOrder = {}

            -----------------------------------------------------------------------------------------------------------
            -- Sort Players in Setup
            -----------------------------------------------------------------------------------------------------------
            table.sort(setup.Players, orderConfigs[orderIdx].Callback)
            ApplyToEach(setup.Players, function(k, v) 
                sortedOrder[v.PlayerName] = k 
                SetPoint(v.Container, "TOPLEFT", 10, vOffset)
                vOffset = vOffset - 32
            end)
            SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

            table.sort(config.PlayerInfos, function(a, b) return sortedOrder[a.Name] < sortedOrder[b.Name] end)

            -----------------------------------------------------------------------------------------------------------
            -- Set all other Button inactive
            -----------------------------------------------------------------------------------------------------------
            for k, v in pairs(setup.Order) do
                if orderName ~= k then
                    local cl = color.LightGray
                    v.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
                    v.Button.pushed = false
                    v.Button:Enable()
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
        SetPoint(setup.TableScrollContainer, "TOPLEFT", 10, -80)
        SetPoint(setup.TableScrollContainer, "BOTTOMRIGHT", -6, 50)
        setup.TableScrollContainer:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = math.max(1, Scaled(2)),
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
        SetPoint(setup.TableScroll, "TOPLEFT", 0, -25)
        SetPoint(setup.TableScroll, "BOTTOMRIGHT", Agnostic(-27), 5)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Table Scroll Content Widget
    -------------------------------------------------------------------------------------------------------------------
    if setup.Table == nil then
        setup.Table = CreateFrame("Frame")
        SetWidth(setup.Table, GetWidth(setup.TableScroll))
        SetHeight(setup.Table, 1)
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Player Row Frames for All Existing Players
    -------------------------------------------------------------------------------------------------------------------
    local vOffset = 0
    setup.Players = setup.Players or {}
    for _, playerInfo in pairs(cfg.PlayerInfos or {}) do
        local player = RemoveFirstElement(addonDB.Widgets.FreePlayers) or {}
        if player.Container then
            player.Container:Show()
            player.Container:SetParent(setup.Table)
        end
        CreatePlayerFrame(player, cfg, setup, setup.Table, playerInfo, GetWidth(setup.Table) - 10, 10, vOffset)
        table.insert(setup.Players, player)
        vOffset = vOffset - 32
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Create Bottom Line
    -------------------------------------------------------------------------------------------------------------------
    if setup.TableBottomLine == nil then
        setup.TableBottomLine = CreateLine(GetWidth(setup.Table) - 10, setup.Table, 5, vOffset + 2, color.DarkGray)
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
        setup.Tab.Button, setup.Tab.Text = CreateButton(addonDB.Widgets.TabContent, name, GetWidth(addonDB.Widgets.TabContent), 40, color.DarkGray, color.LightGray)
    else
        setup.Tab.Button:SetText(name)
        setup.Tab.Button:Show()
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Assign Tab Button
    -------------------------------------------------------------------------------------------------------------------
    AddHover(setup.Tab.Button, true)

    setup.Tab.Button:SetScript("OnMouseDown", function(self, mouseButton)
        if IsDialogShown() then
            return 
        end

        if mouseButton == "RightButton" then
            -----------------------------------------------------------------------------------------------------------
            -- Create Right Mouse Click Menu
            -----------------------------------------------------------------------------------------------------------
            local rightMouseClickMenuItems = {}

            if addonDB.Tracking.Active and addonDB.Tracking.Name == setup.Name then
                -------------------------------------------------------------------------------------------------------
                -- Stop Tracking
                -------------------------------------------------------------------------------------------------------
                local item = {
                    text = "Stop Tracking", 
                    func = function() 
                        local c = color.DarkGray
                        local name = setup.Name

                        DisableTracking()

                        local _, setup = GetValueByFilter(addonDB.Widgets.Setups, function(k, v) return v.Name == name end)
                        setup.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
                    end
                }
                table.insert(rightMouseClickMenuItems, item);
            else
                -------------------------------------------------------------------------------------------------------
                -- Start Tracking
                -------------------------------------------------------------------------------------------------------
                local item = {
                    text = "Start Tracking", 
                    func = function() 
                        local name = setup.Name

                        for k, v in pairs(addonDB.Widgets.Setups) do
                            if v.Name == name then
                                local c = color.Highlight
                                v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
                            else
                                local c = color.DarkGray
                                v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
                            end
                        end

                        EnableTracking(name, false)
                    end
                }
                table.insert(rightMouseClickMenuItems, item);
            end

            -----------------------------------------------------------------------------------------------------------
            -- Rename
            -----------------------------------------------------------------------------------------------------------
            local rename = {
                text = "Rename...", 
                func = function() 
                    local name = setup.Name
                    addonDB.Widgets.Dialogs.Rename.InputField.currentName = name
                    ShowFrame(addonDB.Widgets.Dialogs.Rename.Frame)
                end
            }
            table.insert(rightMouseClickMenuItems, rename);

            -----------------------------------------------------------------------------------------------------------
            -- Delete
            -----------------------------------------------------------------------------------------------------------
            local delete = {
                text = "Delete",
                func = function()
                    local name = setup.Name
                    local key, setup = GetSetupByName(name)

                    ---------------------------------------------------------------------------------------------------
                    -- Disable Tracking
                    ---------------------------------------------------------------------------------------------------
                    if addonDB.Tracking.Active and addonDB.Tracking.Name == name then
                        local c = color.DarkGray
                        setup.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
                        DisableTracking()
                    end

                    ---------------------------------------------------------------------------------------------------
                    -- Remove Config
                    ---------------------------------------------------------------------------------------------------
                    RemoveWithFilter(addonDB.Configs, function(k, v) return v.Name == name end)
                    
                    ---------------------------------------------------------------------------------------------------
                    -- Hide Buttons if no configuration exist
                    ---------------------------------------------------------------------------------------------------
                    if #addonDB.Configs == 0 then
                        local c = color.LightGray
                        addonDB.Widgets.Export.Button:Hide()
                        addonDB.Widgets.Save.Button:Hide()
                        addonDB.Widgets.Print.Button:Hide()
                        addonDB.Widgets.AddPlayers.Button:Disable()
                        addonDB.Widgets.AddPlayers.Text:SetTextColor(c.r, c.g, c.b, c.a)
                    end

                    ---------------------------------------------------------------------------------------------------
                    -- Hide all Player Containers and Move to FreePlayers
                    ---------------------------------------------------------------------------------------------------
                    setup.Tab.Button:Hide()
                    for _, ev in pairs(setup.Players) do 
                        ev.Container:Hide()
                        table.insert(addonDB.Widgets.FreePlayers, ev)
                    end
                    setup.Players = {}

                    ---------------------------------------------------------------------------------------------------
                    -- Delete Setup
                    ---------------------------------------------------------------------------------------------------
                    table.insert(addonDB.Widgets.FreeSetups, setup)
                    table.remove(addonDB.Widgets.Setups, key)

                    ---------------------------------------------------------------------------------------------------
                    -- Rearrange Tabs
                    ---------------------------------------------------------------------------------------------------
                    RearrangeFrames(addonDB.Widgets.Setups, "TOPLEFT", 0, -42, function(v) return v.Tab.Button end, 3, -3)

                    ---------------------------------------------------------------------------------------------------
                    -- Hide Freed Setups
                    ---------------------------------------------------------------------------------------------------
                    HideFrame(setup.Content)
                    local _, ev = GetFirstValue(addonDB.Widgets.Setups)
                    if ev then
                        local c = color.Gold
                        ev.Tab.Button.pushed = true
                        ev.Tab.Button:Disable()
                        ev.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                        ev.Content:Show()

                        if addonDB.Tracking.Active and addonDB.Tracking.Name == ev.Tab.Text:GetText() then
                            addonDB.Widgets.Share.Frame:Show()
                        else 
                            addonDB.Widgets.Share.Frame:Hide()
                        end
                    end
                end
            }
            table.insert(rightMouseClickMenuItems, delete)

            -----------------------------------------------------------------------------------------------------------
            -- Setup Right Mouse Click Menu
            -----------------------------------------------------------------------------------------------------------
            EasyMenu(rightMouseClickMenuItems, addonDB.Widgets.RightMouseClickTabMenu, "cursor", 0, 0, "MENU", 1)
        else
            -----------------------------------------------------------------------------------------------------------
            -- Activate Tab and Show Its Content
            -----------------------------------------------------------------------------------------------------------
            self.pushed = true
            self:Disable()
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)

            -----------------------------------------------------------------------------------------------------------
            -- Show Content and Hide All Other Content
            -----------------------------------------------------------------------------------------------------------
            for _, s in pairs(addonDB.Widgets.Setups) do
                if s.Name ~= self:GetText() then
                    local cl = color.LightGray
                    s.Tab.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
                    s.Tab.Button.pushed = false
                    s.Tab.Button:Enable()
                    s.Content:Hide()
                else
                    if addonDB.Tracking.Active and addonDB.Tracking.Name == s.Tab.Text:GetText() then
                        addonDB.Widgets.Share.Frame:Show()
                    else
                        addonDB.Widgets.Share.Frame:Hide()
                    end
                    s.Content:Show()
                end
            end
        end
    end)
    SetPoint(setup.Tab.Button, "TOPLEFT", 3, -3 - 42 * (#addonDB.Widgets.Setups - 1))

    -------------------------------------------------------------------------------------------------------------------
    -- Show Or Hide The Newly Created Frame Based On Argument
    -------------------------------------------------------------------------------------------------------------------
    if show then
        local c = color.Gold
        setup.Tab.Button.pushed = true
        addonDB.Widgets.Export.Button:Show()
        addonDB.Widgets.Save.Button:Show()
        addonDB.Widgets.Print.Button:Show()
        addonDB.Widgets.AddPlayers.Button:Enable()
        addonDB.Widgets.AddPlayers.Text:SetTextColor(c.r, c.g, c.b, c.a)
        setup.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        setup.Content:Show()

        if addonDB.Tracking.Active and addonDB.Tracking.Name == setup.Tab.Text:GetText() then
            addonDB.Widgets.Share.Frame:Show()
        else
            addonDB.Widgets.Share.Frame:Hide()
        end
    else
        setup.Content:Hide()
    end

    -------------------------------------------------------------------------------------------------------------------
    -- Return Player Table
    -------------------------------------------------------------------------------------------------------------------
    return setup
end

-----------------------------------------------------------------------------------------------------------------------
-- Create Right Mouse Click Menu Frame
-----------------------------------------------------------------------------------------------------------------------
addonDB.Widgets.RightMouseClickTabMenu = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")

-----------------------------------------------------------------------------------------------------------------------
-- Create Addon Window
-----------------------------------------------------------------------------------------------------------------------
addonDB.Widgets.Addon = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")

-----------------------------------------------------------------------------------------------------------------------
-- Setup User Interfacd
-----------------------------------------------------------------------------------------------------------------------
local function SetupUserInterface()
    -------------------------------------------------------------------------------------------------------------------
    -- Setup Main Frame
    -------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Addon:SetFrameStrata("HIGH")
    SetSize(addonDB.Widgets.Addon, 1600, 1000)
    addonDB.Widgets.Addon:SetMovable(true)
    addonDB.Widgets.Addon:EnableMouse(true)
    addonDB.Widgets.Addon:RegisterForDrag("LeftButton")
    addonDB.Widgets.Addon:SetScript("OnDragStart", addonDB.Widgets.Addon.StartMoving)
    addonDB.Widgets.Addon:SetScript("OnDragStop", addonDB.Widgets.Addon.StopMovingOrSizing)
    SetPoint(addonDB.Widgets.Addon, "CENTER")
    addonDB.Widgets.Addon:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Addon:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Addon:SetBackdropBorderColor(0, 0, 0, 1)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Tab Scroll
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.TabScroll = CreateFrame("ScrollFrame", nil, addonDB.Widgets.Addon, "UIPanelScrollFrameTemplate, BackdropTemplate")
    SetPoint(addonDB.Widgets.TabScroll, "TOPLEFT", 6, -6)
    SetPoint(addonDB.Widgets.TabScroll, "BOTTOMRIGHT", addonDB.Widgets.Addon, "BOTTOMLEFT", 195, 6 + 100)
    addonDB.Widgets.TabScroll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.TabScroll:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.TabScroll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Tab Content And Insert Into Tab Scroll
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.TabContent = CreateFrame("Frame", nil, addonDB.Widgets.TabScroll)
    SetWidth(addonDB.Widgets.TabContent, GetWidth(addonDB.Widgets.TabScroll) - 7)
    SetHeight(addonDB.Widgets.TabContent, 1)
    addonDB.Widgets.TabScroll:SetScrollChild(addonDB.Widgets.TabContent)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create CreatedBy Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.CreatedBy = addonDB.Widgets.Addon:CreateFontString(nil, "ARTWORK")
    SetPoint(addonDB.Widgets.CreatedBy, "BOTTOMLEFT", 10, 6)
    addonDB.Widgets.CreatedBy:SetFont("Fonts\\FRIZQT__.TTF", Scaled(10), "NONE")
    addonDB.Widgets.CreatedBy:SetTextColor(1, 0.8, 0) -- set the color to golden
    addonDB.Widgets.CreatedBy:SetText("Created by " .. author)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Content Frame
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Content = CreateFrame("Frame", nil, addonDB.Widgets.Addon, "BackdropTemplate")
    SetPoint(addonDB.Widgets.Content, "TOPLEFT", 227, -6)
    SetPoint(addonDB.Widgets.Content, "BOTTOMRIGHT", -6, 6)
    addonDB.Widgets.Content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Content:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Content:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Close Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Close = {}
    addonDB.Widgets.Close.Button, addonDB.Widgets.Close.Text = CreateButton(addonDB.Widgets.Content, "Close", 102, 35, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Close.Button, "BOTTOMRIGHT", addonDB.Widgets.Content, "BOTTOMRIGHT", -10, 10)
    addonDB.Widgets.Close.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        ToggleFrame(addonDB.Widgets.Addon)
    end)
    AddHover(addonDB.Widgets.Close.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Save Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Save = {}
    addonDB.Widgets.Save.Button, addonDB.Widgets.Save.Text = CreateButton(addonDB.Widgets.Content, "Save", 102, 35, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Save.Button, "BOTTOMRIGHT", addonDB.Widgets.Content, "BOTTOMRIGHT", -122, 10)
    addonDB.Widgets.Save.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        -------------------------------------------------------------------------------------------------------------------
        -- Get Config and Setup
        -------------------------------------------------------------------------------------------------------------------
        local config = GetActiveConfig()
        local setup = GetActiveSetup()

        if not config or not setup then
            return
        end

        -------------------------------------------------------------------------------------------------------------------
        -- Update Config and Setup
        -------------------------------------------------------------------------------------------------------------------
        for _, player in pairs(setup.Players) do
            local _, info = GetValueByFilter(config.PlayerInfos, function(k, v) return player.PlayerName == v.Name end)

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
        end

        ShareConfiguration(config)
    end)
    AddHover(addonDB.Widgets.Save.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Export Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Export = {}
    addonDB.Widgets.Export.Button, addonDB.Widgets.Export.Text = CreateButton(addonDB.Widgets.Content, "Export", 102, 35, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Export.Button, "BOTTOMLEFT", addonDB.Widgets.Content, "BOTTOMLEFT", 10, 10)
    addonDB.Widgets.Export.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        -- Serialize
        local encoded = SerializeConfig(GetActiveConfig())

        addonDB.Widgets.Dialogs.Export.InputField:SetMaxLetters(0)
        addonDB.Widgets.Dialogs.Export.InputField:SetText(encoded)
        addonDB.Widgets.Dialogs.Export.Frame:Show()
    end)
    AddHover(addonDB.Widgets.Export.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Print Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Print = {}
    addonDB.Widgets.Print.Button, addonDB.Widgets.Print.Text = CreateButton(addonDB.Widgets.Content, "Print", 102, 35, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Print.Button, "BOTTOMLEFT", addonDB.Widgets.Export.Button, "BOTTOMRIGHT", 10, 0)
    addonDB.Widgets.Print.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        local config = GetActiveConfig()
        local content =  ""
        content = content .. "+------------------------------------------+-------+-------+--------+\n" 
        content = content .. "| Character Name                           | Rares | Tiers | Normal |\n"
        for _, playerInfo in pairs(config.PlayerInfos) do
            local _, count = string.gsub(playerInfo.Name, '[^\128-\193]', '')
            content = content .. "+------------------------------------------+-------+-------+--------+\n"
            content = content .. "| " .. playerInfo.Name .. Ws(39 - count) .. " | " .. string.format("%5d", playerInfo.Rare)  .. " | " .. string.format("%5d", playerInfo.Tier) .. " | " .. string.format("%6d", playerInfo.Normal) .. " |\n"
        end
        content = content .. "+------------------------------------------+-------+-------+--------+\n"

        addonDB.Widgets.Dialogs.Print.EditBox:SetText(content)
        ShowFrame(addonDB.Widgets.Dialogs.Print.Frame)
    end)
    AddHover(addonDB.Widgets.Print.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Share Checkbox
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Share = {}
    addonDB.Widgets.Share.Frame = CreateFrame("Frame", nil, addonDB.Widgets.Content, "BackdropTemplate")
    addonDB.Widgets.Share.Frame:SetFrameStrata("HIGH")
    SetSize(addonDB.Widgets.Share.Frame, 170, 35)
    addonDB.Widgets.Share.Frame:SetMovable(false)
    SetPoint(addonDB.Widgets.Share.Frame, "LEFT", addonDB.Widgets.Print.Button, "RIGHT", 100, 0)
    addonDB.Widgets.Share.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Share.Frame:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, 1)
    addonDB.Widgets.Share.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Share.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Share.Frame:Hide()

    addonDB.Widgets.Share.Checkbox = CreateFrame("CheckButton", nil, addonDB.Widgets.Share.Frame, "ChatConfigCheckButtonTemplate")
    SetSize(addonDB.Widgets.Share.Checkbox, 24, 24)
    addonDB.Widgets.Share.Checkbox:SetChecked(false)
    SetPoint(addonDB.Widgets.Share.Checkbox, "LEFT", 10, 0)
    addonDB.Widgets.Share.Checkbox:SetScript("OnClick", function(self) 
        addonDB.Sharing = self:GetChecked()
        ShareConfiguration(select(2, GetConfigByName(addonDB.Tracking.Name)))
    end)

    addonDB.Widgets.Share.Label = CreateLabel("Share Updates", addonDB.Widgets.Share.Frame, nil, nil, color.Gold)
    SetPoint(addonDB.Widgets.Share.Label, "LEFT", addonDB.Widgets.Share.Checkbox, "RIGHT", 10, 0)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options = {}
    addonDB.Widgets.Dialogs.Options.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.Options.Frame, 650, 320)
    addonDB.Widgets.Dialogs.Options.Frame:SetMovable(true)
    addonDB.Widgets.Dialogs.Options.Frame:EnableMouse(true)
    addonDB.Widgets.Dialogs.Options.Frame:RegisterForDrag("LeftButton")
    addonDB.Widgets.Dialogs.Options.Frame:SetScript("OnDragStart", addonDB.Widgets.Addon.StartMoving)
    addonDB.Widgets.Dialogs.Options.Frame:SetScript("OnDragStop", addonDB.Widgets.Addon.StopMovingOrSizing)
    SetPoint(addonDB.Widgets.Dialogs.Options.Frame, "CENTER", addonDB.Widgets.Addon, "CENTER", 0, 0)
    addonDB.Widgets.Dialogs.Options.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Options.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Options.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.Options.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.Options.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.Header = CreateHeading("OPTIONS", GetWidth(addonDB.Widgets.Dialogs.Options.Frame) - 20, addonDB.Widgets.Dialogs.Options.Frame, 10, -10, false)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Tier Identifier Frame 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.TierIdContainer = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.Options.Frame, "BackdropTemplate")
    SetWidth(addonDB.Widgets.Dialogs.Options.TierIdContainer, GetWidth(addonDB.Widgets.Dialogs.Options.Frame) - 20)
    SetHeight(addonDB.Widgets.Dialogs.Options.TierIdContainer, 60)
    SetPoint(addonDB.Widgets.Dialogs.Options.TierIdContainer, "TOP", addonDB.Widgets.Dialogs.Options.Frame, "TOP", 0, -30)
    addonDB.Widgets.Dialogs.Options.TierIdContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Options.TierIdContainer:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, color.DarkGray.a)
    addonDB.Widgets.Dialogs.Options.TierIdContainer:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, color.LightGray.a)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Tier Identifier Inputfield
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.TierIdInputField = CreateFrame("EditBox", nil, addonDB.Widgets.Dialogs.Options.TierIdContainer, "InputBoxTemplate")
    SetWidth(addonDB.Widgets.Dialogs.Options.TierIdInputField, GetWidth(addonDB.Widgets.Dialogs.Options.TierIdContainer) - 40)
    SetHeight(addonDB.Widgets.Dialogs.Options.TierIdInputField, 30)
    SetPoint(addonDB.Widgets.Dialogs.Options.TierIdInputField, "TOP", addonDB.Widgets.Dialogs.Options.TierIdContainer, "TOP", 0, -20)
    addonDB.Widgets.Dialogs.Options.TierIdInputField:SetAutoFocus(false)
    addonDB.Widgets.Dialogs.Options.TierIdInputField:SetMaxLetters(0)
    addonDB.Widgets.Dialogs.Options.TierIdInputField:SetFont("Fonts\\FRIZQT__.TTF", Scaled(12), "OUTLINE")
    addonDB.Widgets.Dialogs.Options.TierIdInputField:SetScript("OnTextChanged", function(self) 
        local c = color.White
        self:SetTextColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Options.TierIdInputField:SetScript("OnEnterPressed", function(self) 
        local text = addonDB.Widgets.Dialogs.Options.TierIdInputField:GetText()
        local split = SplitString(text, ",")
        local numbers = {}
        for _, v in pairs(split) do
            local num = tonumber(v)
            if not num then
                local c = color.Red
                addonDB.Widgets.Dialogs.Options.TierIdInputField:SetTextColor(c.r, c.g, c.b, c.a)
                return
            end
            table.insert(numbers, num)
        end
        addonDB.Options.TierItems = numbers
    end)
    addonDB.Widgets.Dialogs.Options.TierIdInputField:SetScript("OnEscapePressed", function(self) 
        self:SetText(ArrayToString(addonDB.Options.TierItems))
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Tier Identifier Label 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.TierIdLabel = CreateLabel("Tier Identifiers:", addonDB.Widgets.Dialogs.Options.TierIdContainer, nil, nil, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Options.TierIdLabel, "BOTTOMLEFT", addonDB.Widgets.Dialogs.Options.TierIdInputField, "TOPLEFT", 10, 0)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Rare Identifier Frame 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.RareIdContainer = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.Options.Frame, "BackdropTemplate")
    SetWidth(addonDB.Widgets.Dialogs.Options.RareIdContainer, GetWidth(addonDB.Widgets.Dialogs.Options.Frame) - 20)
    SetHeight(addonDB.Widgets.Dialogs.Options.RareIdContainer, 60)
    SetPoint(addonDB.Widgets.Dialogs.Options.RareIdContainer, "TOP", addonDB.Widgets.Dialogs.Options.TierIdContainer, "BOTTOM", 0, -10)
    addonDB.Widgets.Dialogs.Options.RareIdContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Options.RareIdContainer:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, color.DarkGray.a)
    addonDB.Widgets.Dialogs.Options.RareIdContainer:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, color.LightGray.a)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Rare Identifier Inputfield
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.RareIdInputField = CreateFrame("EditBox", nil, addonDB.Widgets.Dialogs.Options.RareIdContainer, "InputBoxTemplate")
    SetWidth(addonDB.Widgets.Dialogs.Options.RareIdInputField, GetWidth(addonDB.Widgets.Dialogs.Options.RareIdContainer) - 40)
    SetHeight(addonDB.Widgets.Dialogs.Options.RareIdInputField, 30)
    SetPoint(addonDB.Widgets.Dialogs.Options.RareIdInputField, "TOP", addonDB.Widgets.Dialogs.Options.RareIdContainer, "TOP", 0, -20)
    addonDB.Widgets.Dialogs.Options.RareIdInputField:SetAutoFocus(false)
    addonDB.Widgets.Dialogs.Options.RareIdInputField:SetMaxLetters(0)
    addonDB.Widgets.Dialogs.Options.RareIdInputField:SetFont("Fonts\\FRIZQT__.TTF", Scaled(12), "OUTLINE")
    addonDB.Widgets.Dialogs.Options.RareIdInputField:SetScript("OnTextChanged", function(self) 
        local c = color.White
        self:SetTextColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Options.RareIdInputField:SetScript("OnEnterPressed", function(self) 
        local text = addonDB.Widgets.Dialogs.Options.RareIdInputField:GetText()
        local split = SplitString(text, ",")
        local numbers = {}
        for _, v in pairs(split) do
            local num = tonumber(v)
            if not num then
                local c = color.Red
                addonDB.Widgets.Dialogs.Options.RareIdInputField:SetTextColor(c.r, c.g, c.b, c.a)
                return
            end
            table.insert(numbers, num)
        end
        addonDB.Options.RareItems = numbers
    end)
    addonDB.Widgets.Dialogs.Options.RareIdInputField:SetScript("OnEscapePressed", function(self) 
        self:SetText(ArrayToString(addonDB.Options.RareItems))
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Rare Identifier Label 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.RareIdLabel = CreateLabel("Rare Identifiers:", addonDB.Widgets.Dialogs.Options.RareIdContainer, nil, nil, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Options.RareIdLabel, "BOTTOMLEFT", addonDB.Widgets.Dialogs.Options.RareIdInputField, "TOPLEFT", 10, 0)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Scaling Frame 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.ScalingContainer = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.Options.Frame, "BackdropTemplate")
    SetWidth(addonDB.Widgets.Dialogs.Options.ScalingContainer, GetWidth(addonDB.Widgets.Dialogs.Options.Frame) - 20)
    SetHeight(addonDB.Widgets.Dialogs.Options.ScalingContainer, 100)
    SetPoint(addonDB.Widgets.Dialogs.Options.ScalingContainer, "TOP", addonDB.Widgets.Dialogs.Options.RareIdContainer, "BOTTOM", 0, -10)
    addonDB.Widgets.Dialogs.Options.ScalingContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Options.ScalingContainer:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, color.DarkGray.a)
    addonDB.Widgets.Dialogs.Options.ScalingContainer:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, color.LightGray.a)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Scaling Inputfield
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.ScalingInputField = CreateFrame("EditBox", nil, addonDB.Widgets.Dialogs.Options.ScalingContainer, "InputBoxTemplate")
    SetWidth(addonDB.Widgets.Dialogs.Options.ScalingInputField, (GetWidth(addonDB.Widgets.Dialogs.Options.ScalingContainer) - 90) * 0.25)
    SetHeight(addonDB.Widgets.Dialogs.Options.ScalingInputField, 30)
    SetPoint(addonDB.Widgets.Dialogs.Options.ScalingInputField, "TOPLEFT", addonDB.Widgets.Dialogs.Options.ScalingContainer, "TOPLEFT", 70, -30)
    addonDB.Widgets.Dialogs.Options.ScalingInputField:SetAutoFocus(false)
    addonDB.Widgets.Dialogs.Options.ScalingInputField:SetText(addonDB.Options.Scaling)
    addonDB.Widgets.Dialogs.Options.ScalingInputField:SetMaxLetters(5)
    addonDB.Widgets.Dialogs.Options.ScalingInputField:SetFont("Fonts\\FRIZQT__.TTF", Scaled(12), "OUTLINE")
    addonDB.Widgets.Dialogs.Options.ScalingInputField:SetScript("OnTextChanged", function(self) 
        local num = tonumber(addonDB.Widgets.Dialogs.Options.ScalingInputField:GetText())
        if num then
            if num == addonDB.Options.Scaling then
                local c = color.Gold
                self:SetTextColor(c.r, c.g, c.b, c.a)
            else
                local c = color.White
                self:SetTextColor(c.r, c.g, c.b, c.a)
            end
        else
            local c = color.Red
            self:SetTextColor(c.r, c.g, c.b, c.a)
        end
    end)
    addonDB.Widgets.Dialogs.Options.ScalingInputField:SetScript("OnEnterPressed", function(self) 
        local num = tonumber(addonDB.Widgets.Dialogs.Options.ScalingInputField:GetText())
        if num then
            -- Limit to 0.5 <= num <= 1.5
            num = math.max(0.5, math.min(1.5, num))
            addonDB.Widgets.Dialogs.Options.ScalingInputField:SetText(num)
            addonDB.Options.Scaling = num
        else
            local c = color.Red
            addonDB.Widgets.Dialogs.Options.ScalingInputField:SetTextColor(c.r, c.g, c.b, c.a)
        end
    end)
    addonDB.Widgets.Dialogs.Options.ScalingInputField:SetScript("OnEscapePressed", function(self) 
        self:SetText(addonDB.Options.Scaling)
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Scaling Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.ScalingLabel = CreateLabel("Scaling:", addonDB.Widgets.Dialogs.Options.ScalingContainer, nil, nil, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Options.ScalingLabel, "BOTTOMLEFT", addonDB.Widgets.Dialogs.Options.ScalingInputField, "TOPLEFT", 10, 0)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Scaling Description
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.ScalingDescription = CreateLabel("Allows to scale the UI up or down. A value of 1.0 is the default. All values between 0.5 and 1.5 are supported.", addonDB.Widgets.Dialogs.Options.ScalingContainer, nil, nil, color.White)
    addonDB.Widgets.Dialogs.Options.ScalingDescription:SetJustifyH("LEFT")
    SetPoint(addonDB.Widgets.Dialogs.Options.ScalingDescription, "TOPLEFT", addonDB.Widgets.Dialogs.Options.ScalingInputField, "TOPRIGHT", 20, 13)
    SetWidth(addonDB.Widgets.Dialogs.Options.ScalingDescription, GetWidth(addonDB.Widgets.Dialogs.Options.ScalingContainer) * 0.5)

    addonDB.Widgets.Dialogs.Options.ScalingWarning = CreateLabel("IMPORTANT: You have to /reload to apply the scaling change.", addonDB.Widgets.Dialogs.Options.ScalingContainer, nil, nil, color.Red)
    addonDB.Widgets.Dialogs.Options.ScalingWarning:SetJustifyH("LEFT")
    SetPoint(addonDB.Widgets.Dialogs.Options.ScalingWarning, "TOPLEFT", addonDB.Widgets.Dialogs.Options.ScalingDescription, "BOTTOMLEFT", 0, -5)
    SetWidth(addonDB.Widgets.Dialogs.Options.ScalingWarning, GetWidth(addonDB.Widgets.Dialogs.Options.ScalingContainer) * 0.5)

    -----------------------------------------------------------------------------------------------------------------------
    -- Options Dialog: Close Button 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Options.Close = {}
    addonDB.Widgets.Dialogs.Options.Close.Button, addonDB.Widgets.Dialogs.Options.Close.Text = CreateButton(addonDB.Widgets.Dialogs.Options.Frame, "Close", 102, 28, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Dialogs.Options.Close.Button, "BOTTOMRIGHT", addonDB.Widgets.Dialogs.Options.Frame, "BOTTOMRIGHT", -10, 10)
    addonDB.Widgets.Dialogs.Options.Close.Button:SetScript("OnClick", function(self)
        local num = tonumber(addonDB.Widgets.Dialogs.Options.ScalingInputField:GetText())
        if num then
            -- Limit to 0.5 <= num <= 1.5
            num = math.max(0.5, math.min(1.5, num))
            addonDB.Widgets.Dialogs.Options.ScalingInputField:SetText(num)
            addonDB.Options.Scaling = num
            addonDB.Widgets.Dialogs.Options.Frame:Hide()
        else
            local c = color.Red
            addonDB.Widgets.Dialogs.Options.ScalingInputField:SetTextColor(c.r, c.g, c.b, c.a)
        end
    end)
    AddHover(addonDB.Widgets.Dialogs.Options.Close.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Print Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Print = {}
    addonDB.Widgets.Dialogs.Print.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.Print.Frame, 650, 600)
    addonDB.Widgets.Dialogs.Print.Frame:SetMovable(true)
    addonDB.Widgets.Dialogs.Print.Frame:EnableMouse(true)
    addonDB.Widgets.Dialogs.Print.Frame:RegisterForDrag("LeftButton")
    addonDB.Widgets.Dialogs.Print.Frame:SetScript("OnDragStart", addonDB.Widgets.Addon.StartMoving)
    addonDB.Widgets.Dialogs.Print.Frame:SetScript("OnDragStop", addonDB.Widgets.Addon.StopMovingOrSizing)
    SetPoint(addonDB.Widgets.Dialogs.Print.Frame, "CENTER")
    addonDB.Widgets.Dialogs.Print.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Print.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Print.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.Print.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.Print.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Print Dialog: Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Print.Header = CreateHeading("PRINT", GetWidth(addonDB.Widgets.Dialogs.Print.Frame) - 10, addonDB.Widgets.Dialogs.Print.Frame, 5, -10, true)

    -----------------------------------------------------------------------------------------------------------------------
    -- Print Dialog: Scroll Area 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Print.Scroll = CreateFrame("ScrollFrame", nil, addonDB.Widgets.Dialogs.Print.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    SetPoint(addonDB.Widgets.Dialogs.Print.Scroll, "TOPLEFT", 10, -30)
    SetPoint(addonDB.Widgets.Dialogs.Print.Scroll, "BOTTOMRIGHT", addonDB.Widgets.Dialogs.Print.Frame, "BOTTOMRIGHT", -10, 45)
    addonDB.Widgets.Dialogs.Print.Scroll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Print.Scroll:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Print.Scroll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    addonDB.Widgets.Dialogs.Print.Scroll:SetClipsChildren(true)

    -----------------------------------------------------------------------------------------------------------------------
    -- Print Dialog: EditBox
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Print.EditBox = CreateFrame("EditBox", nil, addonDB.Widgets.Dialogs.Print.Scroll)
    addonDB.Widgets.Dialogs.Print.EditBox:SetMultiLine(true)
    addonDB.Widgets.Dialogs.Print.EditBox:SetFontObject("ChatFontNormal")
    SetWidth(addonDB.Widgets.Dialogs.Print.EditBox, GetWidth(addonDB.Widgets.Dialogs.Print.Scroll))
    addonDB.Widgets.Dialogs.Print.EditBox:SetAutoFocus(false)
    addonDB.Widgets.Dialogs.Print.EditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    addonDB.Widgets.Dialogs.Print.Scroll:SetScrollChild(addonDB.Widgets.Dialogs.Print.EditBox)

    -----------------------------------------------------------------------------------------------------------------------
    -- Print Dialog: Close Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Print.Close = {}
    addonDB.Widgets.Dialogs.Print.Close.Button, addonDB.Widgets.Dialogs.Print.Close.Text = CreateButton(addonDB.Widgets.Dialogs.Print.Frame, "Close", 102, 28, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Dialogs.Print.Close.Button, "BOTTOMRIGHT", addonDB.Widgets.Dialogs.Print.Frame, "BOTTOMRIGHT", -10, 10)
    addonDB.Widgets.Dialogs.Print.Close.Button:SetScript("OnClick", function(self)
        addonDB.Widgets.Dialogs.Print.Frame:Hide()
        addonDB.Widgets.Dialogs.Print.EditBox:SetText("")
    end)
    AddHover(addonDB.Widgets.Dialogs.Print.Close.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Rename Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Rename = {}
    addonDB.Widgets.Dialogs.Rename.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    addonDB.Widgets.Dialogs.Rename.Frame:SetFrameStrata("HIGH")
    SetSize(addonDB.Widgets.Dialogs.Rename.Frame, 250, 90)
    addonDB.Widgets.Dialogs.Rename.Frame:SetMovable(false)
    SetPoint(addonDB.Widgets.Dialogs.Rename.Frame, "CENTER")
    addonDB.Widgets.Dialogs.Rename.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Rename.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Rename.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.Rename.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.Rename.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Rename Dialog: Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Rename.Header = CreateHeading("RENAME", GetWidth(addonDB.Widgets.Dialogs.Rename.Frame) - 10, addonDB.Widgets.Dialogs.Rename.Frame, 5, -10, true)

    -----------------------------------------------------------------------------------------------------------------------
    -- Rename Dialog: Escape Label 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Rename.Escape = CreateLabel("<ESC>: Cancel", addonDB.Widgets.Dialogs.Rename.Frame, 10, 10, color.White, "BOTTOMLEFT")

    -----------------------------------------------------------------------------------------------------------------------
    -- Rename Dialog: Enter Label 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Rename.Enter = CreateLabel("<ENTER>: Confirm", addonDB.Widgets.Dialogs.Rename.Frame, -10, 10, color.White, "BOTTOMRIGHT")

    -----------------------------------------------------------------------------------------------------------------------
    -- Rename Dialog: Inputfield
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Rename.InputField = CreateFrame("EditBox", nil, addonDB.Widgets.Dialogs.Rename.Frame, "InputBoxTemplate")
    SetWidth(addonDB.Widgets.Dialogs.Rename.InputField, GetWidth(addonDB.Widgets.Dialogs.Rename.Frame) - 30)
    SetHeight(addonDB.Widgets.Dialogs.Rename.InputField, 30)
    SetPoint(addonDB.Widgets.Dialogs.Rename.InputField, "TOPLEFT", addonDB.Widgets.Dialogs.Rename.Frame, "TOPLEFT", 17, -30)
    addonDB.Widgets.Dialogs.Rename.InputField:SetAutoFocus(true)
    addonDB.Widgets.Dialogs.Rename.InputField:SetMaxLetters(25)
    addonDB.Widgets.Dialogs.Rename.InputField:SetFont("Fonts\\FRIZQT__.TTF", Scaled(12), "OUTLINE")
    addonDB.Widgets.Dialogs.Rename.InputField:SetScript("OnTextChanged", function(self) 
        local input = self:GetText()
        if #input > 0 then
            if GetValueByFilter(addonDB.Configs, function(k, v) return v.Name == input and self.currentName ~= v.Name end) then
                self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
            else
                self:SetTextColor(color.White.r, color.White.g, color.White.b)
            end
        end
    end)
    addonDB.Widgets.Dialogs.Rename.InputField:SetScript("OnEnterPressed", function(self) 
        local input = self:GetText()

        -------------------------------------------------------------------------------------------------------------------
        -- Return on no input
        -------------------------------------------------------------------------------------------------------------------
        if #input == 0 then
            return
        end

        -------------------------------------------------------------------------------------------------------------------
        -- If Name changed
        -------------------------------------------------------------------------------------------------------------------
        if input ~= self.currentName then
            ---------------------------------------------------------------------------------------------------------------
            -- Return if name already taken
            ---------------------------------------------------------------------------------------------------------------
            if GetValueByFilter(addonDB.Configs, function(k, v) return v.Name == input end) then
                return
            end

            if self.config then
                -----------------------------------------------------------------------------------------------------------
                -- Rename because of Override
                -----------------------------------------------------------------------------------------------------------
                self.config.Name = input
                self.currentName = self.config.Name

                -----------------------------------------------------------------------------------------------------------
                -- Hide all other content
                -----------------------------------------------------------------------------------------------------------
                for k, v in pairs(addonDB.Widgets.Setups) do
                    if v.Name ~= self.currentName then
                        v.Content:Hide()
                        v.Tab.Button.pushed = false
                        local c = color.LightGray
                        v.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                    end
                end

                -----------------------------------------------------------------------------------------------------------
                -- Setup new Raid Entry
                -----------------------------------------------------------------------------------------------------------
                table.insert(addonDB.Configs, self.config)
                SetupNewEntry(self.config, true)
            else
                -----------------------------------------------------------------------------------------------------------
                -- Rename Config and Setup
                -----------------------------------------------------------------------------------------------------------
                local _, config = GetConfigByName(self.currentName)
                config.Name = input

                local _, setup = GetSetupByName(self.currentName)
                setup.Name = input
                setup.Tab.Text:SetText(input)
            end

            ---------------------------------------------------------------------------------------------------------------
            -- Update Tracking Name
            ---------------------------------------------------------------------------------------------------------------
            if addonDB.Tracking.Active and addonDB.Tracking.Name == self.currentName then
                addonDB.Tracking.Name = input
            end
        end

        -------------------------------------------------------------------------------------------------------------------
        -- Hide Frame
        -------------------------------------------------------------------------------------------------------------------
        HideFrame(addonDB.Widgets.Dialogs.Rename.Frame)
        HideFrame(addonDB.Widgets.Dialogs.Rename.Escape)

        -------------------------------------------------------------------------------------------------------------------
        -- Reset Data
        -------------------------------------------------------------------------------------------------------------------
        self.currentName = nil
        self.config = nil
        self:SetText("")
    end)
    addonDB.Widgets.Dialogs.Rename.InputField:SetScript("OnEscapePressed", function(self) 
        if addonDB.Widgets.Dialogs.Rename.Frame:IsShown() and addonDB.Widgets.Dialogs.Rename.Escape:IsShown() then
            self:SetText("")
            self.currentName = nil
            addonDB.Widgets.Dialogs.Rename.Frame:Hide()
        end
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Export Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Export = {}
    addonDB.Widgets.Dialogs.Export.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.Export.Frame, 250, 90)
    addonDB.Widgets.Dialogs.Export.Frame:SetMovable(false)
    SetPoint(addonDB.Widgets.Dialogs.Export.Frame, "CENTER")
    addonDB.Widgets.Dialogs.Export.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Export.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Export.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.Export.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.Export.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Export Dialog: Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Export.Header = CreateHeading("EXPORT", GetWidth(addonDB.Widgets.Dialogs.Export.Frame) - 10, addonDB.Widgets.Dialogs.Export.Frame, 5, -10, true)

    -----------------------------------------------------------------------------------------------------------------------
    -- Export Dialog: Escape Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Export.Escape = CreateLabel("<ESC>: Close", addonDB.Widgets.Dialogs.Export.Frame, 0, 10, color.White, "BOTTOM")

    -----------------------------------------------------------------------------------------------------------------------
    -- Export Dialog: InputField
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Export.InputField = CreateFrame("EditBox", nil, addonDB.Widgets.Dialogs.Export.Frame, "InputBoxTemplate")
    SetWidth(addonDB.Widgets.Dialogs.Export.InputField, GetWidth(addonDB.Widgets.Dialogs.Export.Frame) - 30)
    SetHeight(addonDB.Widgets.Dialogs.Export.InputField, 30)
    SetPoint(addonDB.Widgets.Dialogs.Export.InputField, "TOPLEFT", addonDB.Widgets.Dialogs.Export.Frame, "TOPLEFT", 17, -30)
    addonDB.Widgets.Dialogs.Export.InputField:SetAutoFocus(true)
    addonDB.Widgets.Dialogs.Export.InputField:SetMaxLetters(0)
    addonDB.Widgets.Dialogs.Export.InputField:SetFont("Fonts\\FRIZQT__.TTF", Scaled(12), "OUTLINE")
    addonDB.Widgets.Dialogs.Export.InputField:SetScript("OnEscapePressed", function(self) 
        if addonDB.Widgets.Dialogs.Export.Frame:IsShown() then
            self:SetText("")
            addonDB.Widgets.Dialogs.Export.Frame:Hide()
        end
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Conflict Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Conflict = {}
    addonDB.Widgets.Dialogs.Conflict.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.Conflict.Frame, 250, 80)
    addonDB.Widgets.Dialogs.Conflict.Frame:SetMovable(false)
    SetPoint(addonDB.Widgets.Dialogs.Conflict.Frame, "CENTER")
    addonDB.Widgets.Dialogs.Conflict.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Conflict.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Conflict.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.Conflict.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.Conflict.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Conflict Dialog: Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Conflict.Header = CreateHeading("NAME CONFLICT", GetWidth(addonDB.Widgets.Dialogs.Conflict.Frame) - 10, addonDB.Widgets.Dialogs.Conflict.Frame, 5, -10, true)

    -----------------------------------------------------------------------------------------------------------------------
    -- Conflict Dialog: Update Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Conflict.Update = {}
    addonDB.Widgets.Dialogs.Conflict.Update.Button, addonDB.Widgets.Dialogs.Conflict.Update.Text = CreateButton(addonDB.Widgets.Dialogs.Conflict.Frame, "Update", 102, 35, color.DarkGray, color.LightGray, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Conflict.Update.Button, "TOPLEFT", addonDB.Widgets.Dialogs.Conflict.Frame, "TOPLEFT", 15, -30)
    addonDB.Widgets.Dialogs.Conflict.Update.Button:SetScript("OnClick", function(self)
        RemoveWithFilter(addonDB.Configs, function(k, v) return v.Name == addonDB.Widgets.Dialogs.Conflict.config.Name end)
        local key, setup = GetValueByFilter(addonDB.Widgets.Setups, function(k, v) return v.Name == addonDB.Widgets.Dialogs.Conflict.config.Name end)

        -------------------------------------------------------------------------------------------------------------------
        -- Free All Player Container
        -------------------------------------------------------------------------------------------------------------------
        for ek, ev in pairs(setup.Players) do 
            ev.Container:Hide()
            table.insert(addonDB.Widgets.FreePlayers, ev)
        end
        setup.Players = {}

        -------------------------------------------------------------------------------------------------------------------
        -- Hide Tab Button
        -------------------------------------------------------------------------------------------------------------------
        setup.Tab.Button:Hide()

        -------------------------------------------------------------------------------------------------------------------
        -- Free Setup
        -------------------------------------------------------------------------------------------------------------------
        table.insert(addonDB.Widgets.FreeSetups, setup)
        table.remove(addonDB.Widgets.Setups, key)

        -------------------------------------------------------------------------------------------------------------------
        -- Rearrange and Hide
        -------------------------------------------------------------------------------------------------------------------
        RearrangeFrames(addonDB.Widgets.Setups, "TOPLEFT", 0, -42, function(v) return v.Tab.Button end, 3, -3)
        HideFrame(setup.Content)

        -------------------------------------------------------------------------------------------------------------------
        -- Hide all other Setups
        -------------------------------------------------------------------------------------------------------------------
        for k, v in pairs(addonDB.Widgets.Setups) do
            if v.Name ~= addonDB.Widgets.Dialogs.Conflict.config.Name then
                v.Content:Hide()
                v.Tab.Button.pushed = false
                local c = color.LightGray
                v.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            end
        end

        -------------------------------------------------------------------------------------------------------------------
        -- Setup new Configuration Entry
        -------------------------------------------------------------------------------------------------------------------
        table.insert(addonDB.Configs, addonDB.Widgets.Dialogs.Conflict.config)
        SetupNewEntry(addonDB.Widgets.Dialogs.Conflict.config, true)

        ShareConfiguration(addonDB.Widgets.Dialogs.Conflict.config)

        -------------------------------------------------------------------------------------------------------------------
        -- Hide Frame
        -------------------------------------------------------------------------------------------------------------------
        addonDB.Widgets.Dialogs.Conflict.config = nil
        HideFrame(addonDB.Widgets.Dialogs.Conflict.Frame)
    end)
    AddHover(addonDB.Widgets.Dialogs.Conflict.Update.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Conflict Dialog: Rename Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Conflict.Rename = {}
    addonDB.Widgets.Dialogs.Conflict.Rename.Button, addonDB.Widgets.Dialogs.Conflict.Rename.Text = CreateButton(addonDB.Widgets.Dialogs.Conflict.Frame, "Rename", 102, 35, color.DarkGray, color.LightGray, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Conflict.Rename.Button, "TOPRIGHT", addonDB.Widgets.Dialogs.Conflict.Frame, "TOPRIGHT", -15, -30)
    addonDB.Widgets.Dialogs.Conflict.Rename.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Conflict.Rename.Button:SetScript("OnLeave", function(self)
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Conflict.Rename.Button:SetScript("OnClick", function(self)
        addonDB.Widgets.Dialogs.Rename.InputField.config = addonDB.Widgets.Dialogs.Conflict.config
        addonDB.Widgets.Dialogs.Rename.Escape:Hide()
        addonDB.Widgets.Dialogs.Rename.Frame:Show()

        addonDB.Widgets.Dialogs.Conflict.config = nil
        addonDB.Widgets.Dialogs.Conflict.Frame:Hide()
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Import Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Import = {}
    addonDB.Widgets.Dialogs.Import.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.Import.Frame, 250, 90)
    addonDB.Widgets.Dialogs.Import.Frame:SetMovable(false)
    SetPoint(addonDB.Widgets.Dialogs.Import.Frame, "CENTER")
    addonDB.Widgets.Dialogs.Import.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Import.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Import.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.Import.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.Import.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Import Dialog: Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Import.Header = CreateHeading("IMPORT", GetWidth(addonDB.Widgets.Dialogs.Import.Frame) - 10, addonDB.Widgets.Dialogs.Import.Frame, 5, -10, true)

    -----------------------------------------------------------------------------------------------------------------------
    -- Import Dialog: Escape Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Import.Escape = CreateLabel("<ESC>: Cancel", addonDB.Widgets.Dialogs.Import.Frame, 10, 10, color.White, "BOTTOMLEFT")

    -----------------------------------------------------------------------------------------------------------------------
    -- Import Dialog: Enter Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Import.Enter = CreateLabel("<ENTER>: Confirm", addonDB.Widgets.Dialogs.Import.Frame, -10, 10, color.White, "BOTTOMRIGHT")

    -----------------------------------------------------------------------------------------------------------------------
    -- Import Dialog: InputField
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Import.InputField = CreateFrame("EditBox", nil, addonDB.Widgets.Dialogs.Import.Frame, "InputBoxTemplate")
    SetWidth(addonDB.Widgets.Dialogs.Import.InputField, GetWidth(addonDB.Widgets.Dialogs.Import.Frame) - 30)
    SetHeight(addonDB.Widgets.Dialogs.Import.InputField, 30)
    SetPoint(addonDB.Widgets.Dialogs.Import.InputField, "TOPLEFT", addonDB.Widgets.Dialogs.Import.Frame, "TOPLEFT", 17, -30)
    addonDB.Widgets.Dialogs.Import.InputField:SetAutoFocus(true)
    addonDB.Widgets.Dialogs.Import.InputField:SetMaxLetters(0)
    addonDB.Widgets.Dialogs.Import.InputField:SetFont("Fonts\\FRIZQT__.TTF", Scaled(12), "OUTLINE")
    addonDB.Widgets.Dialogs.Import.InputField:SetScript("OnTextChanged", function(self) 
        self:SetTextColor(color.White.r, color.White.g, color.White.b)
    end)
    addonDB.Widgets.Dialogs.Import.InputField:SetScript("OnEnterPressed", function(self) 
        local input = self:GetText()
        if #input == 0 then
            return
        end

        -----------------------------------------------------------------------------------------------------------------------
        -- Deserialize String
        -----------------------------------------------------------------------------------------------------------------------
        local success, deserialized = Deserialize(self:GetText())

        -----------------------------------------------------------------------------------------------------------------------
        -- Change to Red to signalize Deserialization error
        -----------------------------------------------------------------------------------------------------------------------
        if not success then
            self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
            return
        end

        -----------------------------------------------------------------------------------------------------------------------
        -- Hide and Reset
        -----------------------------------------------------------------------------------------------------------------------
        addonDB.Widgets.Dialogs.Import.Frame:Hide()
        self:SetText("")

        -----------------------------------------------------------------------------------------------------------------------
        -- Check if Config would Override
        -----------------------------------------------------------------------------------------------------------------------
        if GetValueByFilter(addonDB.Configs, function(k, v) return v.Name == deserialized.Name end) then
            addonDB.Widgets.Dialogs.Conflict.config = deserialized
            addonDB.Widgets.Dialogs.Conflict.Frame:Show()
            return
        end

        -----------------------------------------------------------------------------------------------------------------------
        -- Hide All Other Setups
        -----------------------------------------------------------------------------------------------------------------------
        for k, v in pairs(addonDB.Widgets.Setups) do
            if v.Name ~= deserialized.Name then
                v.Content:Hide()
                v.Tab.Button.pushed = false
                local c = color.LightGray
                v.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            end
        end

        -----------------------------------------------------------------------------------------------------------------------
        -- Insert and Activate new Setup
        -----------------------------------------------------------------------------------------------------------------------
        table.insert(addonDB.Configs, deserialized)
        SetupNewEntry(deserialized, true)
    end)
    addonDB.Widgets.Dialogs.Import.InputField:SetScript("OnEscapePressed", function(self) 
        if addonDB.Widgets.Dialogs.Import.Frame:IsShown() then
            self:SetText("")
            addonDB.Widgets.Dialogs.Import.Frame:Hide()
        end
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Activate Raid Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.ActivateRaid = {}
    addonDB.Widgets.Dialogs.ActivateRaid.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.ActivateRaid.Frame, 350, 160)
    addonDB.Widgets.Dialogs.ActivateRaid.Frame:SetMovable(false)
    SetPoint(addonDB.Widgets.Dialogs.ActivateRaid.Frame, "TOP", 0, -250)
    addonDB.Widgets.Dialogs.ActivateRaid.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.ActivateRaid.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.ActivateRaid.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.ActivateRaid.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.ActivateRaid.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Activate Raid Dialog: Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.ActivateRaid.Header = CreateHeading("RAID TABLES", GetWidth(addonDB.Widgets.Dialogs.ActivateRaid.Frame) - 20, addonDB.Widgets.Dialogs.ActivateRaid.Frame, 5, -10, false, 14)

    -----------------------------------------------------------------------------------------------------------------------
    -- Activate Raid Dialog: Label 
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.ActivateRaid.Label = CreateLabel("Start tracking by " .. addonName .. " for this group?", addonDB.Widgets.Dialogs.ActivateRaid.Frame, 0, -35, color.White, "TOP", 14)
    SetWidth(addonDB.Widgets.Dialogs.ActivateRaid.Label, GetWidth(addonDB.Widgets.Dialogs.ActivateRaid.Frame) - 20)

    -----------------------------------------------------------------------------------------------------------------------
    -- Activate Raid Dialog: Sharing
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.ActivateRaid.Share = {}
    addonDB.Widgets.Dialogs.ActivateRaid.Share.Checkbox = CreateFrame("CheckButton", nil, addonDB.Widgets.Dialogs.ActivateRaid.Frame, "ChatConfigCheckButtonTemplate")
    SetSize(addonDB.Widgets.Dialogs.ActivateRaid.Share.Checkbox, 24, 24)
    addonDB.Widgets.Dialogs.ActivateRaid.Share.Checkbox:SetChecked(false)
    SetPoint(addonDB.Widgets.Dialogs.ActivateRaid.Share.Checkbox, "CENTER", -60, -25)
    addonDB.Widgets.Dialogs.ActivateRaid.Share.Checkbox:SetScript("OnClick", function(self) 
        self.EnableShare = self:GetChecked()
    end)

    addonDB.Widgets.Dialogs.ActivateRaid.Share.Label = CreateLabel("Share Updates", addonDB.Widgets.Dialogs.ActivateRaid.Frame, nil, nil, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.ActivateRaid.Share.Label, "LEFT", addonDB.Widgets.Dialogs.ActivateRaid.Share.Checkbox, "RIGHT", 10, 1)

    -----------------------------------------------------------------------------------------------------------------------
    -- Activate Raid Dialog: Raid Selection
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.ActivateRaid.RaidSelection = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.ActivateRaid.Frame, "UIDropDownMenuTemplate")
    SetPoint(addonDB.Widgets.Dialogs.ActivateRaid.RaidSelection, "CENTER", addonDB.Widgets.Dialogs.ActivateRaid.Frame, "CENTER", 35, 5)
    addonDB.Widgets.Dialogs.ActivateRaid.SetupSelection = function()
        DisableTracking()

        -------------------------------------------------------------------------------------------------------------------
        -- Setup Dropdown Menu
        -------------------------------------------------------------------------------------------------------------------
        UIDropDownMenu_Initialize(addonDB.Widgets.Dialogs.ActivateRaid.RaidSelection, function(self, level)
            for i, setup in pairs(addonDB.Widgets.Setups) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = setup.Name
                info.value = setup.Name
                info.func = function(self) 
                    addonDB.Widgets.Dialogs.ActivateRaid.TrackingName = setup.Name
                    UIDropDownMenu_SetSelectedID(addonDB.Widgets.Dialogs.ActivateRaid.RaidSelection, i)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        UIDropDownMenu_SetWidth(addonDB.Widgets.Dialogs.ActivateRaid.RaidSelection, Scaled(100))
        UIDropDownMenu_SetButtonWidth(addonDB.Widgets.Dialogs.ActivateRaid.RaidSelection, Scaled(GetWidth(addonDB.Widgets.Dialogs.ActivateRaid.Frame) - 192))

        local i, setup = GetActiveSetup()
        if not setup then
            i, setup = GetFirstValue(addonDB.Widgets.Setups)
        end

        addonDB.Widgets.Dialogs.ActivateRaid.TrackingName = setup.Name
        UIDropDownMenu_SetSelectedID(addonDB.Widgets.Dialogs.ActivateRaid.RaidSelection, i)
        UIDropDownMenu_JustifyText(addonDB.Widgets.Dialogs.ActivateRaid.RaidSelection, "CENTER")
    end

    -----------------------------------------------------------------------------------------------------------------------
    -- Activate Raid Dialog: Selection Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.ActivateRaid.SelectionLabel = CreateLabel("Raid Name:", addonDB.Widgets.Dialogs.ActivateRaid.Frame, -60, 7, color.Gold, "CENTER", 12)

    -----------------------------------------------------------------------------------------------------------------------
    -- Activate Raid Dialog: Yes Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.ActivateRaid.Yes = {}
    addonDB.Widgets.Dialogs.ActivateRaid.Yes.Button, addonDB.Widgets.Dialogs.ActivateRaid.Yes.Text = CreateButton(addonDB.Widgets.Dialogs.ActivateRaid.Frame, "YES", 102, 28, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Dialogs.ActivateRaid.Yes.Button, "BOTTOMRIGHT", addonDB.Widgets.Dialogs.ActivateRaid.Frame, "BOTTOMRIGHT", -45, 10)
    addonDB.Widgets.Dialogs.ActivateRaid.Yes.Button:SetScript("OnClick", function(self)
        EnableTracking(addonDB.Widgets.Dialogs.ActivateRaid.TrackingName, addonDB.Widgets.Dialogs.ActivateRaid.Share.Checkbox.EnableShare or false)

        for k, v in pairs(addonDB.Widgets.Setups) do
            if v.Name == addonDB.Tracking.Name then
                local c = color.Highlight
                v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
            else
                local c = color.DarkGray
                v.Tab.Button:SetBackdropColor(c.r, c.g, c.b)
            end
        end
        addonDB.Widgets.Dialogs.ActivateRaid.Frame:Hide()
    end)
    AddHover(addonDB.Widgets.Dialogs.ActivateRaid.Yes.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Activate Raid Dialog: No Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.ActivateRaid.No = {}
    addonDB.Widgets.Dialogs.ActivateRaid.No.Button, addonDB.Widgets.Dialogs.ActivateRaid.No.Text = CreateButton(addonDB.Widgets.Dialogs.ActivateRaid.Frame, "NO", 102, 28, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Dialogs.ActivateRaid.No.Button, "BOTTOMLEFT", addonDB.Widgets.Dialogs.ActivateRaid.Frame, "BOTTOMLEFT", 45, 10)
    addonDB.Widgets.Dialogs.ActivateRaid.No.Button:SetScript("OnClick", function(self)
        DisableTracking()
    end)
    AddHover(addonDB.Widgets.Dialogs.ActivateRaid.No.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create New Raid Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.NewRaid = {}
    addonDB.Widgets.Dialogs.NewRaid.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.NewRaid.Frame, 250, 90)
    addonDB.Widgets.Dialogs.NewRaid.Frame:SetMovable(false)
    SetPoint(addonDB.Widgets.Dialogs.NewRaid.Frame, "CENTER")
    addonDB.Widgets.Dialogs.NewRaid.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.NewRaid.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.NewRaid.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.NewRaid.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.NewRaid.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- New Raid Dialog: Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.NewRaid.Header = CreateHeading("NEW RAID", GetWidth(addonDB.Widgets.Dialogs.NewRaid.Frame) - 10, addonDB.Widgets.Dialogs.NewRaid.Frame, 5, -10, true)

    -----------------------------------------------------------------------------------------------------------------------
    -- New Raid Dialog: Escape Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.NewRaid.Escape = CreateLabel("<ESC>: Cancel", addonDB.Widgets.Dialogs.NewRaid.Frame, 10, 10, color.White, "BOTTOMLEFT")

    -----------------------------------------------------------------------------------------------------------------------
    -- New Raid Dialog: Enter Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.NewRaid.Enter = CreateLabel("<ENTER>: Confirm", addonDB.Widgets.Dialogs.NewRaid.Frame, -10, 10, color.White, "BOTTOMRIGHT")

    -----------------------------------------------------------------------------------------------------------------------
    -- New Raid Dialog: InputField
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.NewRaid.InputField = CreateFrame("EditBox", nil, addonDB.Widgets.Dialogs.NewRaid.Frame, "InputBoxTemplate")
    SetWidth(addonDB.Widgets.Dialogs.NewRaid.InputField, GetWidth(addonDB.Widgets.Dialogs.NewRaid.Frame) - 30)
    SetHeight(addonDB.Widgets.Dialogs.NewRaid.InputField, 30)
    SetPoint(addonDB.Widgets.Dialogs.NewRaid.InputField, "TOPLEFT", addonDB.Widgets.Dialogs.NewRaid.Frame, "TOPLEFT", 17, -30)
    addonDB.Widgets.Dialogs.NewRaid.InputField:SetAutoFocus(true)
    addonDB.Widgets.Dialogs.NewRaid.InputField:SetMaxLetters(25)
    addonDB.Widgets.Dialogs.NewRaid.InputField:SetFont("Fonts\\FRIZQT__.TTF", Scaled(12), "OUTLINE")
    addonDB.Widgets.Dialogs.NewRaid.InputField:SetScript("OnTextChanged", function(self) 
        local input = self:GetText()
        if #input > 0 then
            -- Check if name already taken
            local _, config = GetConfigByName(input)
            if config then
                self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
            else
                self:SetTextColor(color.White.r, color.White.g, color.White.b)
            end
        end
    end)
    addonDB.Widgets.Dialogs.NewRaid.InputField:SetScript("OnEnterPressed", function(self) 
        local input = self:GetText()
        local c = color.Gold

        -------------------------------------------------------------------------------------------------------------------
        -- Return if no input
        -------------------------------------------------------------------------------------------------------------------
        if #input == 0 then
            return
        end

        -------------------------------------------------------------------------------------------------------------------
        -- Return if COnfig exists
        -------------------------------------------------------------------------------------------------------------------
        if GetConfigByName(input) then
            return
        end

        -------------------------------------------------------------------------------------------------------------------
        -- Add New Entry
        -------------------------------------------------------------------------------------------------------------------
        local playerName, realm = UnitFullName("player")
        local entry = { 
            ["Sharer"] = playerName.."-"..realm,
            ["Name"] = input,
            ["PlayerInfos"] = {}
        }
        table.insert(addonDB.Configs, entry)
        SetupNewEntry(entry, true)

        -------------------------------------------------------------------------------------------------------------------
        -- Hide all other raid entries
        -------------------------------------------------------------------------------------------------------------------
        for k, v in pairs(addonDB.Widgets.Setups) do
            if v.Name ~= entry.Name then
                v.Content:Hide()
                local cl = color.LightGray
                v.Tab.Button.pushed = false
                v.Tab.Button:SetBackdropBorderColor(cl.r, cl.g, cl.b, cl.a)
            end
        end

        -------------------------------------------------------------------------------------------------------------------
        -- Show Buttons
        -------------------------------------------------------------------------------------------------------------------
        addonDB.Widgets.Export.Button:Show()
        addonDB.Widgets.Save.Button:Show()
        addonDB.Widgets.Print.Button:Show()
        addonDB.Widgets.AddPlayers.Button:Enable()
        addonDB.Widgets.AddPlayers.Text:SetTextColor(c.r, c.g, c.b, c.a)
        addonDB.Widgets.Dialogs.NewRaid.Frame:Hide()
        self:SetText("")
    end)
    addonDB.Widgets.Dialogs.NewRaid.InputField:SetScript("OnEscapePressed", function(self) 
        if addonDB.Widgets.Dialogs.NewRaid.Frame:IsShown() then
            self:SetText("")
            addonDB.Widgets.Dialogs.NewRaid.Frame:Hide()
        end
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Add Players Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.AddPlayers = {}
    addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames = {}
    addonDB.Widgets.Dialogs.AddPlayers.FreePlayerFrames = {}
    addonDB.Widgets.Dialogs.AddPlayers.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.AddPlayers.Frame, 470, 350)
    addonDB.Widgets.Dialogs.AddPlayers.Frame:SetMovable(true)
    addonDB.Widgets.Dialogs.AddPlayers.Frame:EnableMouse(true)
    addonDB.Widgets.Dialogs.AddPlayers.Frame:RegisterForDrag("LeftButton")
    addonDB.Widgets.Dialogs.AddPlayers.Frame:SetScript("OnDragStart", addonDB.Widgets.Addon.StartMoving)
    addonDB.Widgets.Dialogs.AddPlayers.Frame:SetScript("OnDragStop", addonDB.Widgets.Addon.StopMovingOrSizing)
    SetPoint(addonDB.Widgets.Dialogs.AddPlayers.Frame, "CENTER")
    addonDB.Widgets.Dialogs.AddPlayers.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.AddPlayers.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.AddPlayers.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.AddPlayers.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.AddPlayers.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Add Players Dialog: Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.AddPlayers.Header = CreateHeading("ADD PLAYERS", GetWidth(addonDB.Widgets.Dialogs.AddPlayers.Frame) - 10, addonDB.Widgets.Dialogs.AddPlayers.Frame, 5, -10, true)

    -----------------------------------------------------------------------------------------------------------------------
    -- Add Players Dialog: Scroll Area
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.AddPlayers.Scroll = CreateFrame("ScrollFrame", nil, addonDB.Widgets.Dialogs.AddPlayers.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    SetPoint(addonDB.Widgets.Dialogs.AddPlayers.Scroll, "TOPLEFT", 6, -30)
    SetPoint(addonDB.Widgets.Dialogs.AddPlayers.Scroll, "BOTTOMRIGHT", addonDB.Widgets.Dialogs.AddPlayers.Frame, "BOTTOMRIGHT", Agnostic(-27), 100)
    addonDB.Widgets.Dialogs.AddPlayers.Scroll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.AddPlayers.Scroll:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.AddPlayers.Scroll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -----------------------------------------------------------------------------------------------------------------------
    -- Add Players Dialog: Scroll View
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.AddPlayers.ScrollView = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.AddPlayers.Scroll)
    SetWidth(addonDB.Widgets.Dialogs.AddPlayers.ScrollView, GetWidth(addonDB.Widgets.Dialogs.AddPlayers.Scroll))
    SetHeight(addonDB.Widgets.Dialogs.AddPlayers.ScrollView, 1)

    addonDB.Widgets.Dialogs.AddPlayers.Scroll:SetScrollChild(addonDB.Widgets.Dialogs.AddPlayers.ScrollView)

    -----------------------------------------------------------------------------------------------------------------------
    -- Add Players Dialog: Add Callback
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.AddPlayers.onAdd = function(self)
        local input = addonDB.Widgets.Dialogs.AddPlayers.InputField:GetText()

        -------------------------------------------------------------------------------------------------------------------
        -- Return if no input
        -------------------------------------------------------------------------------------------------------------------
        if #input == 0 then
            return
        end

        -------------------------------------------------------------------------------------------------------------------
        -- If Name Already taken
        -------------------------------------------------------------------------------------------------------------------
        if GetValueByFilter(addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames, function(k, v) return v.Name:GetText() == input end) then
            addonDB.Widgets.Dialogs.AddPlayers.InputField:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
            return
        end

        -------------------------------------------------------------------------------------------------------------------
        -- If Name Already taken
        -------------------------------------------------------------------------------------------------------------------
        local setup = GetActiveSetup()
        if GetValueByFilter(setup.Players, function(k, v) return v.PlayerName == input end) then
            self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
            return
        end

        -------------------------------------------------------------------------------------------------------------------
        -- Create Player Frame
        -------------------------------------------------------------------------------------------------------------------
        local player = {}
        local c = classColor[addonDB.Widgets.Dialogs.AddPlayers.ClassSelection.Class]

        if #addonDB.Widgets.Dialogs.AddPlayers.FreePlayerFrames > 0 then
            ---------------------------------------------------------------------------------------------------------------
            -- Reuse freed frame
            ---------------------------------------------------------------------------------------------------------------
            local v = RemoveFirstElement(addonDB.Widgets.Dialogs.AddPlayers.FreePlayerFrames)
            player = v
            player.Container:Show()
            player.Checkbox:SetChecked(true)
            player.Name:SetText(input)
            player.Name:SetTextColor(c.r, c.g, c.b)
            SetPoint(player.Container, "TOPLEFT", 10, -10 + -33 * #addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames)
            table.insert(addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames, player)
            SetHeight(addonDB.Widgets.Dialogs.AddPlayers.ScrollView, 20 + 33 * #addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames)
        else
            ---------------------------------------------------------------------------------------------------------------
            -- Create completely new frame
            ---------------------------------------------------------------------------------------------------------------
            player.Container = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.AddPlayers.ScrollView, "BackdropTemplate")
            SetWidth(player.Container, GetWidth(addonDB.Widgets.Dialogs.AddPlayers.ScrollView) - 20)
            SetHeight(player.Container, 30)
            player.Container:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = math.max(1, Scaled(2)),
            })
            player.Container:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, color.DarkGray.a)
            player.Container:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, color.LightGray.a)
            SetPoint(player.Container, "TOPLEFT", 10, -10 + -33 * #addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames)
            player.Name = CreateLabel(input, player.Container, 100, -9, c)
            player.Checkbox = CreateFrame("CheckButton", nil, player.Container, "ChatConfigCheckButtonTemplate")
            SetSize(player.Checkbox, 24, 24)
            player.Checkbox:SetChecked(true)
            SetPoint(player.Checkbox, "TOPLEFT", 30, -3)
            table.insert(addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames, player)
            SetWidth(player.Container, GetWidth(addonDB.Widgets.Dialogs.AddPlayers.ScrollView) - 20)
        end

        player.Class = addonDB.Widgets.Dialogs.AddPlayers.ClassSelection.Class
        addonDB.Widgets.Dialogs.AddPlayers.InputField:SetText("")
    end

    -----------------------------------------------------------------------------------------------------------------------
    -- Add Players Dialog: InputField
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.AddPlayers.InputField = CreateFrame("EditBox", nil, addonDB.Widgets.Dialogs.AddPlayers.Frame, "InputBoxTemplate")
    SetWidth(addonDB.Widgets.Dialogs.AddPlayers.InputField, 200)
    SetHeight(addonDB.Widgets.Dialogs.AddPlayers.InputField, 40)
    SetPoint(addonDB.Widgets.Dialogs.AddPlayers.InputField, "BOTTOMLEFT", addonDB.Widgets.Dialogs.AddPlayers.Frame, "BOTTOMLEFT", 18, 40)
    addonDB.Widgets.Dialogs.AddPlayers.InputField:SetAutoFocus(false)
    addonDB.Widgets.Dialogs.AddPlayers.InputField:SetMaxLetters(0)
    addonDB.Widgets.Dialogs.AddPlayers.InputField:SetFont("Fonts\\FRIZQT__.TTF", Scaled(12), "OUTLINE")
    addonDB.Widgets.Dialogs.AddPlayers.InputField:SetScript("OnTextChanged", function(self) 
        local input = self:GetText()
        if #input == 0 then
            return
        end

        if GetValueByFilter(addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames, function(k, v) return v.Name:GetText() == input end) then
            addonDB.Widgets.Dialogs.AddPlayers.InputField:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
            return
        end

        local setup = GetActiveSetup()
        if GetValueByFilter(setup.Players, function(k, v) return v.PlayerName == input end) then
            self:SetTextColor(color.Red.r, color.Red.g, color.Red.b)
            return
        end
        self:SetTextColor(color.White.r, color.White.g, color.White.b)
    end)
    addonDB.Widgets.Dialogs.AddPlayers.InputField:SetScript("OnEnterPressed", addonDB.Widgets.Dialogs.AddPlayers.onAdd)

    -----------------------------------------------------------------------------------------------------------------------
    -- Add Players Dialog: Input Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.AddPlayers.InputLabel = CreateLabel("Enter Player Name:", addonDB.Widgets.Dialogs.AddPlayers.InputField, 0, 10, color.Gold, "TOPLEFT")

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
    addonDB.Widgets.Dialogs.AddPlayers.ClassSelection = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.AddPlayers.InputField, "UIDropDownMenuTemplate")
    SetPoint(addonDB.Widgets.Dialogs.AddPlayers.ClassSelection, "LEFT", addonDB.Widgets.Dialogs.AddPlayers.InputField, "RIGHT", -5, -3)
    addonDB.Widgets.Dialogs.AddPlayers.ClassSelection.Class = classColorOptions[1].value
    UIDropDownMenu_Initialize(addonDB.Widgets.Dialogs.AddPlayers.ClassSelection, function(self, level)
        for i, option in pairs(classColorOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = function(self) 
                addonDB.Widgets.Dialogs.AddPlayers.ClassSelection.Class = option.value
                UIDropDownMenu_SetSelectedID(addonDB.Widgets.Dialogs.AddPlayers.ClassSelection, i)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetWidth(addonDB.Widgets.Dialogs.AddPlayers.ClassSelection, Scaled(100))
    UIDropDownMenu_SetButtonWidth(addonDB.Widgets.Dialogs.AddPlayers.ClassSelection, Scaled(124))
    UIDropDownMenu_SetSelectedID(addonDB.Widgets.Dialogs.AddPlayers.ClassSelection, 1)
    UIDropDownMenu_JustifyText(addonDB.Widgets.Dialogs.AddPlayers.ClassSelection, "LEFT")

    -----------------------------------------------------------------------------------------------------------------------
    -- Add Players Dialog: Add Button
    -----------------------------------------------------------------------------------------------------------------------
    --addonDB.Widgets.Dialogs.AddPlayers.Add = {}
    --addonDB.Widgets.Dialogs.AddPlayers.Add.Button, addonDB.Widgets.Dialogs.AddPlayers.Add.Text = CreateButton(addonDB.Widgets.Dialogs.AddPlayers.Frame, "Add", 102, 28, color.DarkGray, color.LightGray)
    --SetPoint(addonDB.Widgets.Dialogs.AddPlayers.Add.Button, "LEFT", addonDB.Widgets.Dialogs.AddPlayers.ClassSelection, "RIGHT", -5, 2)
    --addonDB.Widgets.Dialogs.AddPlayers.Add.Button:SetScript("OnClick", addonDB.Widgets.Dialogs.AddPlayers.onAdd)
    --AddHover(addonDB.Widgets.Dialogs.AddPlayers.Add.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Add Players Dialog: Confirm Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.AddPlayers.Confirm = {}
    addonDB.Widgets.Dialogs.AddPlayers.Confirm.Button, addonDB.Widgets.Dialogs.AddPlayers.Confirm.Text = CreateButton(addonDB.Widgets.Dialogs.AddPlayers.Frame, "Confirm", 102, 28, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Dialogs.AddPlayers.Confirm.Button, "BOTTOMRIGHT", addonDB.Widgets.Dialogs.AddPlayers.Frame, "BOTTOMRIGHT", -10, 10)
    addonDB.Widgets.Dialogs.AddPlayers.Confirm.Button:SetScript("OnClick", function(self)
        local setup = GetActiveSetup()
        local config = GetActiveConfig()

        -------------------------------------------------------------------------------------------------------------------
        -- Create Frames for all New Players
        -------------------------------------------------------------------------------------------------------------------
        for _, playerFrame in pairs(GetAllWithFilter(addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames, function(k, v) return v.Checkbox:GetChecked() end) or {}) do
            -- Create new entry
            local playerInfo = { 
                ["Name"] = playerFrame.Name:GetText(),
                ["Rare"] = 0,
                ["Tier"] = 0,
                ["Normal"] = 0,
                ["Class"] = playerFrame.Class
            }
            -- Create Player Frame
            local player = RemoveFirstElement(addonDB.Widgets.FreePlayers) or {}
            if player.Container then
                player.Container:Show()
                player.Container:SetParent(setup.Table)
            end
            CreatePlayerFrame(player, config, setup, setup.Table, playerInfo, GetWidth(setup.Table) - 10, 10, #config.PlayerInfos * -32)
            -- Deactive order button
            for _, btn in pairs(setup.Order) do
                btn.Button:Enable()
                btn.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
            end
            -- Insert player data
            table.insert(setup.Players, player)
            table.insert(config.PlayerInfos, playerInfo)
        end
        -- Share Configuration Update
        ShareConfiguration(config)

        -------------------------------------------------------------------------------------------------------------------
        -- Free all Frames for next usage
        -------------------------------------------------------------------------------------------------------------------
        for _, playerFrame in pairs(addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames or {}) do
            -- Hide and free
            playerFrame.Container:Hide()
            table.insert(addonDB.Widgets.Dialogs.AddPlayers.FreePlayerFrames, playerFrame)
        end
        addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames = {}

        -------------------------------------------------------------------------------------------------------------------
        -- Hide Dialog
        -------------------------------------------------------------------------------------------------------------------
        addonDB.Widgets.Dialogs.AddPlayers.Frame:Hide()
        addonDB.Widgets.Dialogs.AddPlayers.InputField:SetText("")
    end)
    AddHover(addonDB.Widgets.Dialogs.AddPlayers.Confirm.Button)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll = {}
    addonDB.Widgets.Dialogs.Roll.Items = {}
    addonDB.Widgets.Dialogs.Roll.MainSpecRolls = {}
    addonDB.Widgets.Dialogs.Roll.SecondSpecRolls = {}
    addonDB.Widgets.Dialogs.Roll.TransmogRolls = {}
    addonDB.Widgets.Dialogs.Roll.InvalidRolls = {}
    addonDB.Widgets.Dialogs.Roll.FreeRolls = {}
    addonDB.Widgets.Dialogs.Roll.AssignmentList = {}
    addonDB.Widgets.Dialogs.Roll.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.Roll.Frame, 40 + 64 + 20 + 125 + 20 + 125 + 40, 860)
    SetPoint(addonDB.Widgets.Dialogs.Roll.Frame, "TOPLEFT", addonDB.Widgets.Addon, "TOPRIGHT", 10, 0)
    addonDB.Widgets.Dialogs.Roll.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Roll.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Roll.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Dialogs.Roll.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Dialogs.Roll.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Skip Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.Skip = {}
    addonDB.Widgets.Dialogs.Roll.Skip.Button, addonDB.Widgets.Dialogs.Roll.Skip.Text = CreateButton(addonDB.Widgets.Dialogs.Roll.Frame, "SKIP", 102, 30, color.DarkGray, color.LightGray, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.Skip.Button, "BOTTOMRIGHT", -15, 15)
    addonDB.Widgets.Dialogs.Roll.Skip.Button:SetScript("OnEnter", function(self)
        if addonDB.Widgets.Dialogs.Roll.Roll.Button.rollActive then
            return
        end
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Roll.Skip.Button:SetScript("OnLeave", function(self)
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Roll.Skip.Button:SetScript("OnClick", function(self)
        if addonDB.Widgets.Dialogs.Roll.Roll.Button.rollActive then
            return
        end

        addonDB.Widgets.Dialogs.Roll.ActiveItemLink = nil
        addonDB.Widgets.Dialogs.Roll.TypeSelection = nil

        addonDB.Widgets.Dialogs.Roll.Tier.Button.pushed = false
        addonDB.Widgets.Dialogs.Roll.Tier.Button:Enable()
        addonDB.Widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

        addonDB.Widgets.Dialogs.Roll.Rare.Button.pushed = false
        addonDB.Widgets.Dialogs.Roll.Rare.Button:Enable()
        addonDB.Widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

        addonDB.Widgets.Dialogs.Roll.Normal.Button.pushed = false
        addonDB.Widgets.Dialogs.Roll.Normal.Button:Enable()
        addonDB.Widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

        addonDB.Widgets.Dialogs.Roll.Assignment:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
        addonDB.Widgets.Dialogs.Roll.AssignmentText:SetText("NO ASSIGNMENT YET")
        addonDB.Widgets.Dialogs.Roll.AssignmentText:SetTextColor(color.White.r, color.White.g, color.White.b)

        for k, v in pairs(addonDB.Widgets.Dialogs.Roll.MainSpecRolls) do
            v.Frame:Hide()
            table.insert(addonDB.Widgets.Dialogs.Roll.FreeRolls, v)
        end
        addonDB.Widgets.Dialogs.Roll.MainSpecRolls = {}

        for k, v in pairs(addonDB.Widgets.Dialogs.Roll.SecondSpecRolls) do
            v.Frame:Hide()
            table.insert(addonDB.Widgets.Dialogs.Roll.FreeRolls, v)
        end
        addonDB.Widgets.Dialogs.Roll.SecondSpecRolls = {}

        for k, v in pairs(addonDB.Widgets.Dialogs.Roll.TransmogRolls) do
            v.Frame:Hide()
            table.insert(addonDB.Widgets.Dialogs.Roll.FreeRolls, v)
        end
        addonDB.Widgets.Dialogs.Roll.TransmogRolls = {}

        for k, v in pairs(addonDB.Widgets.Dialogs.Roll.InvalidRolls) do
            v.Frame:Hide()
            table.insert(addonDB.Widgets.Dialogs.Roll.FreeRolls, v)
        end
        addonDB.Widgets.Dialogs.Roll.InvalidRolls = {}

        HandleLootAssignment()
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.Header = CreateHeading("LOOT", GetWidth(addonDB.Widgets.Dialogs.Roll.Frame) - 10, addonDB.Widgets.Dialogs.Roll.Frame, 5, -10, true)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog Player Assignment Field
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.Assignment = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.Roll.Frame, "BackdropTemplate")
    SetPoint(addonDB.Widgets.Dialogs.Roll.Assignment, "TOPLEFT", 50, -155)
    SetSize(addonDB.Widgets.Dialogs.Roll.Assignment, GetWidth(addonDB.Widgets.Dialogs.Roll.Frame) - 100, 30)
    addonDB.Widgets.Dialogs.Roll.Assignment:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Roll.Assignment:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Roll.Assignment:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog Player Assignment Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.AssignmentText = CreateLabel("NO ASSIGNMENT YET", addonDB.Widgets.Dialogs.Roll.Assignment, nil, nil, color.White)
    SetPoint(addonDB.Widgets.Dialogs.Roll.AssignmentText, "CENTER")

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog MainSpec Loot Scroll View
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll = CreateFrame("ScrollFrame", nil, addonDB.Widgets.Dialogs.Roll.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    SetPoint(addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll, "TOPLEFT", 10, -215)
    SetPoint(addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll, "TOPRIGHT", -32, -215)
    SetHeight(addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll, 125)
    SetPoint(addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll, "BOTTOMRIGHT", addonDB.Widgets.Dialogs.Roll.Frame, "TOPRIGHT", Agnostic(-27) - 11, -335)
    addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRollView = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll)
    SetWidth(addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRollView, GetWidth(addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll))
    SetHeight(addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRollView, 1)

    addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll:SetScrollChild(addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRollView)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog MainSpec Roll Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.MainSpecRollLabel = CreateLabel("Main Spec Need (100):", addonDB.Widgets.Dialogs.Roll.Frame, nil, nil, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.MainSpecRollLabel, "BOTTOMLEFT", addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll, "TOPLEFT", 5, 5)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog SecondSpec Loot Scroll View
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll = CreateFrame("ScrollFrame", nil, addonDB.Widgets.Dialogs.Roll.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    SetPoint(addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll, "TOPLEFT", addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll, "BOTTOMLEFT", 0, -30)
    SetPoint(addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll, "TOPRIGHT", addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRoll, "BOTTOMRIGHT", 0, -30)
    SetHeight(addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll, 125)
    addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRollView = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll)
    SetWidth(addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRollView, GetWidth(addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll))
    SetHeight(addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRollView, 1)

    addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll:SetScrollChild(addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRollView)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog MainSpec Roll Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.SecondSpecRollLabel = CreateLabel("Second Spec Rolls (50):", addonDB.Widgets.Dialogs.Roll.Frame, nil, nil, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.SecondSpecRollLabel, "BOTTOMLEFT", addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll, "TOPLEFT", 5, 5)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog Transmog Loot Scroll View
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll = CreateFrame("ScrollFrame", nil, addonDB.Widgets.Dialogs.Roll.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    SetPoint(addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll, "TOPLEFT", addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll, "BOTTOMLEFT", 0, -30)
    SetPoint(addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll, "TOPRIGHT", addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRoll, "BOTTOMRIGHT", 0, -30)
    SetHeight(addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll, 125)
    addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    addonDB.Widgets.Dialogs.Roll.ScrollTransmogRollView = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll)
    SetWidth(addonDB.Widgets.Dialogs.Roll.ScrollTransmogRollView, GetWidth(addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll))
    SetHeight(addonDB.Widgets.Dialogs.Roll.ScrollTransmogRollView, 1)

    addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll:SetScrollChild(addonDB.Widgets.Dialogs.Roll.ScrollTransmogRollView)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog MainSpec Roll Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.TransmogRollLabel = CreateLabel("Transmog Rolls (25):", addonDB.Widgets.Dialogs.Roll.Frame, nil, nil, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.TransmogRollLabel, "BOTTOMLEFT", addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll, "TOPLEFT", 5, 5)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog Invalid Loot Scroll View
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll = CreateFrame("ScrollFrame", nil, addonDB.Widgets.Dialogs.Roll.Frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    SetPoint(addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll, "TOPLEFT", addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll, "BOTTOMLEFT", 0, -30)
    SetPoint(addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll, "TOPRIGHT", addonDB.Widgets.Dialogs.Roll.ScrollTransmogRoll, "BOTTOMRIGHT", 0, -30)
    SetHeight(addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll, 125)
    addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    addonDB.Widgets.Dialogs.Roll.ScrollInvalidRollView = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll)
    SetWidth(addonDB.Widgets.Dialogs.Roll.ScrollInvalidRollView, GetWidth(addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll))
    SetHeight(addonDB.Widgets.Dialogs.Roll.ScrollInvalidRollView, 1)

    addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll:SetScrollChild(addonDB.Widgets.Dialogs.Roll.ScrollInvalidRollView)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog MainSpec Roll Label
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.InvalidRollLabel = CreateLabel("Invalid Rolls:", addonDB.Widgets.Dialogs.Roll.Frame, nil, nil, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.InvalidRollLabel, "BOTTOMLEFT", addonDB.Widgets.Dialogs.Roll.ScrollInvalidRoll, "TOPLEFT", 5, 5)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog Item Icon
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.ItemIcon = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.Roll.Frame, "BackdropTemplate")
    SetSize(addonDB.Widgets.Dialogs.Roll.ItemIcon, 64, 64)
    SetPoint(addonDB.Widgets.Dialogs.Roll.ItemIcon, "TOPLEFT", 40, -40)
    addonDB.Widgets.Dialogs.Roll.ItemIcon:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Dialogs.Roll.ItemIcon:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Dialogs.Roll.ItemIcon:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Roll Dialog Item Texture
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.ItemTexture = addonDB.Widgets.Dialogs.Roll.ItemIcon:CreateTexture(nil, "ARTWORK")
    addonDB.Widgets.Dialogs.Roll.ItemTexture:SetAllPoints()
    addonDB.Widgets.Dialogs.Roll.ActiveItemLink = nil
    SetItemTexture(addonDB.Widgets.Dialogs.Roll.ItemIcon, addonDB.Widgets.Dialogs.Roll.ItemTexture, "|cffa335ee|Hitem:188032::::::::60:269::4:4:7183:6652:1472:6646:1:28:1707:::|h[Thunderous Echo Vambraces]|h|r")

    -----------------------------------------------------------------------------------------------------------------------
    -- Roll Dialog: Roll Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.Roll = {}
    addonDB.Widgets.Dialogs.Roll.Roll.Button, addonDB.Widgets.Dialogs.Roll.Roll.Text = CreateButton(addonDB.Widgets.Dialogs.Roll.Frame, "START ROLL", 125, 40, color.DarkGray, color.LightGray, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.Roll.Button, "LEFT", addonDB.Widgets.Dialogs.Roll.ItemIcon, "RIGHT", 20, 0)
    addonDB.Widgets.Dialogs.Roll.Roll.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Roll.Roll.Button:SetScript("OnLeave", function(self)
        if self.rollActive then
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        else
            local c = color.LightGray
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end
    end)
    addonDB.Widgets.Dialogs.Roll.Roll.Button:SetScript("OnClick", function(self)
        local itemLink = addonDB.Widgets.Dialogs.Roll.ActiveItemLink

        if self.rollActive then
            self.rollActive = false
            local msg = "---- FINISHED ROLL OF " .. itemLink .. " ----"
            SendChatMessage(msg, (addonDB.Testing and "RAID") or "WHISPER", nil, (addonDB.Testing and UnitName("player")) or nil)
            addonDB.Widgets.Dialogs.Roll.Roll.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
            addonDB.Widgets.Dialogs.Roll.Roll.Text:SetText("START ROLL")
        else
            self.rollActive = true
            local msg = "----    START ROLL OF " .. itemLink .. " ----"
            SendChatMessage(msg, (addonDB.Testing and "RAID") or "WHISPER", nil, (addonDB.Testing and UnitName("player")) or nil)
            addonDB.Widgets.Dialogs.Roll.Roll.Button:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
            addonDB.Widgets.Dialogs.Roll.Roll.Text:SetText("STOP ROLL")
        end
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Roll Dialog: Roll CHAT_MSG_SYSTEM Handling
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.Frame:RegisterEvent("CHAT_MSG_SYSTEM")
    addonDB.Widgets.Dialogs.Roll.Frame:SetScript("OnEvent", function(self, event, message)
        if event ~= "CHAT_MSG_SYSTEM" or message == nil or not addonDB.Widgets.Dialogs.Roll.Roll.Button.rollActive then
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
        local rolls = addonDB.Widgets.Dialogs.Roll.InvalidRolls
        local scrollView = addonDB.Widgets.Dialogs.Roll.ScrollInvalidRollView
        if max == 100 then
            rolls = addonDB.Widgets.Dialogs.Roll.MainSpecRolls
            scrollView = addonDB.Widgets.Dialogs.Roll.ScrollMainSpecRollView
        elseif max == 50 then
            rolls = addonDB.Widgets.Dialogs.Roll.SecondSpecRolls
            scrollView = addonDB.Widgets.Dialogs.Roll.ScrollSecondSpecRollView
        elseif max == 25 then
            rolls = addonDB.Widgets.Dialogs.Roll.TransmogRolls
            scrollView = addonDB.Widgets.Dialogs.Roll.ScrollTransmogRollView
        end

        local roll = nil

        -- Prevent players from rolling more than once
        local fullName = name .. "-" .. realm
        if GetValueByFilter(rolls, function(k, v) return v.PlayerLabel:GetText() == fullName end) then
            return
        end
        
        -- Create frame for player roll
        if #addonDB.Widgets.Dialogs.Roll.FreeRolls > 0 then
            roll = RemoveFirstElement(addonDB.Widgets.Dialogs.Roll.FreeRolls)
            roll.Frame:SetParent(scrollView)
            roll.Frame:Show()
        else
            roll = {}
            roll.Frame = CreateFrame("Button", nil, scrollView, "BackdropTemplate")
            SetSize(roll.Frame, GetWidth(scrollView) - 20, 30)
            roll.Frame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = math.max(1, Scaled(2)),
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
            roll.ItemCountLabel = CreateLabel("", roll.Frame, -10, -10, color.Gold, "TOPRIGHT")
            roll.Add = {}
            roll.Add.Button, roll.Add.Text = CreateButton(roll.Frame, "ADD", 70, 25, color.DarkGray, color.LightGray, color.Gold)
            SetPoint(roll.Add.Button, "RIGHT", -10, 0)
            AddHover(roll.Add.Button)
        end

        if max == 100 or (#addonDB.Widgets.Dialogs.Roll.MainSpecRolls == 0 and max == 50) or (#addonDB.Widgets.Dialogs.Roll.MainSpecRolls == 0 and #addonDB.Widgets.Dialogs.Roll.SecondSpecRolls == 0 and max == 25) then
            roll.Frame:SetScript("OnEnter", function(self)
                if not addonDB.Widgets.Dialogs.Roll.Roll.Button.rollActive then
                    local c = color.Gold
                    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                end
            end)
            roll.Frame:SetScript("OnClick", function(self)
                if not addonDB.Widgets.Dialogs.Roll.Roll.Button.rollActive then
                    addonDB.Widgets.Dialogs.Roll.AssignmentText:SetText(fullName)
                    addonDB.Widgets.Dialogs.Roll.AssignmentText:SetTextColor(colour.r, colour.g, colour.b)
                    addonDB.Widgets.Dialogs.Roll.Assignment:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
                    addonDB.Widgets.Dialogs.Roll.Class = class
                    -- Only count main rolls
                    if max == 100 then
                        addonDB.Widgets.Dialogs.Roll.RollType = "MainSpecRoll"
                    elseif max == 50 then
                        addonDB.Widgets.Dialogs.Roll.RollType = "SecondSpecRoll"
                    elseif max == 25 then
                        addonDB.Widgets.Dialogs.Roll.RollType = "TransmogRoll"
                    else
                        addonDB.Widgets.Dialogs.Roll.RollType = "InvalidRoll"
                    end
                end
            end)
        else
            roll.Frame:SetScript("OnEnter", function(self) end)
            roll.Frame:SetScript("OnClick", function(self) end)
        end

        roll.ItemCount = 0
        roll.PlayerLabel:SetText(name .. "-" .. realm)
        roll.PlayerLabel:SetTextColor(colour.r, colour.g, colour.b, colour.a)
        roll.RollLabel:SetText("Roll: " .. rollValue)

        local playerFound = false
        local orderName = nil

        local v = select(2, GetValueByFilter(addonDB.Widgets.Setups, function(k, v) return v.Name == addonDB.Tracking.Name end))
        local p = select(2, GetValueByFilter(v.Players, function(k, w) return w.PlayerName == fullName end))

        if p then
            if max == 100 and addonDB.Widgets.Dialogs.Roll.Tier.Button.pushed then
                local num = tonumber(p.TierText:GetText()) + tonumber(p.TierDiffText:GetText())
                roll.ItemCount = num
                roll.ItemCountLabel:SetText("Items: "..num)
                roll.ItemCountLabel:Show()
                orderName = "Tier Low"
            elseif max == 100 and addonDB.Widgets.Dialogs.Roll.Rare.Button.pushed then
                local num = tonumber(p.RareText:GetText()) + tonumber(p.RareDiffText:GetText())
                roll.ItemCount = num
                roll.ItemCountLabel:SetText("Items: "..num)
                roll.ItemCountLabel:Show()
                orderName = "Rare Low"
            elseif max == 100 and addonDB.Widgets.Dialogs.Roll.Normal.Button.pushed then
                local num = tonumber(p.NormalText:GetText()) + tonumber(p.NormalDiffText:GetText())
                roll.ItemCount = num
                roll.ItemCountLabel:SetText("Items: "..num)
                roll.ItemCountLabel:Show()
                orderName = "Normal Low"
            else
                roll.ItemCountLabel:SetText("")
                roll.ItemCountLabel:Hide()
            end
            roll.Add.Button:Hide()
            playerFound = true
        end

        -- Player missing in setup
        if not playerFound then
            roll.ItemCount = -1
            -- Hide label
            roll.ItemCountLabel:SetText("")
            roll.ItemCountLabel:Hide()
            -- Show button
            roll.Add.Button:Show()
            roll.Add.Button:SetScript("OnClick", function(self)
                -- Add player frame
                local setup = GetActiveSetup()
                local config = GetActiveConfig()

                -- Create new entry
                local playerInfo = { 
                    ["Name"] = fullName,
                    ["Rare"] = 0,
                    ["Tier"] = 0,
                    ["Normal"] = 0,
                    ["Class"] = class
                }

                -- Create Player Frame
                local player = RemoveFirstElement(addonDB.Widgets.FreePlayers) or {}
                if player.Container then
                    player.Container:Show()
                    player.Container:SetParent(setup.Table)
                end
                CreatePlayerFrame(player, config, setup, setup.Table, playerInfo, GetWidth(setup.Table) - 10, 10, #config.PlayerInfos * -32)

                -- Insert player data
                table.insert(setup.Players, player)
                table.insert(config.PlayerInfos, playerInfo)

                -- Sort by order
                if orderName then
                    local _, v = GetValueByFilter(orderConfigs, function(k, v) return v.Name == orderName end)
                    table.sort(setup.Players, v["Callback"])
                    local vOffset = 0
                    local sortedOrder = {}
                    for i, p in pairs(setup.Players) do
                        sortedOrder[p.PlayerName] = i
                        SetPoint(p.Container, "TOPLEFT", 0, vOffset)
                        vOffset = vOffset - 32
                    end
                    SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

                    table.sort(config["PlayerInfos"], function(a, b)
                        return sortedOrder[a.Name] < sortedOrder[b.Name]
                    end)
                end

                -- Remove add button
                local _, r = GetValueByFilter(addonDB.Widgets.Dialogs.Roll.MainSpecRolls, function(k, v) return v.PlayerLabel:GetText() == fullName end)
                if r then
                    r.Add.Button:Hide()
                    r.ItemCount = 0
                    if addonDB.Widgets.Dialogs.Roll.Tier.Button.pushed or addonDB.Widgets.Dialogs.Roll.Rare.Button.pushed or addonDB.Widgets.Dialogs.Roll.Normal.Button.pushed then
                        r.ItemCountLabel:SetText("Items: 0")
                        r.ItemCountLabel:Show()
                    end

                    table.sort(addonDB.Widgets.Dialogs.Roll.MainSpecRolls, function(a, b) 
                        if a.ItemCount == nil and b.ItemCount == nil then
                            return a.Value > b.Value
                        end
                        if a.ItemCount == nil then
                            return false 
                        end
                        if b.ItemCount == nil then
                            return true 
                        end
                        return a.ItemCount < b.ItemCount or (a.ItemCount == b.ItemCount and a.Value > b.Value)
                    end)
                    RearrangeFrames(addonDB.Widgets.Dialogs.Roll.MainSpecRolls, "TOPLEFT", 0, -32, function(f) return f.Frame end, 10, -5)
                end

                _, r = GetValueByFilter(addonDB.Widgets.Dialogs.Roll.SecondSpecRolls, function(k, v) return v.PlayerLabel:GetText() == fullName end)
                if r then
                    r.Add.Button:Hide()
                end

                _, r = GetValueByFilter(addonDB.Widgets.Dialogs.Roll.TransmogRolls, function(k, v) return v.PlayerLabel:GetText() == fullName end)
                if r then
                    r.Add.Button:Hide()
                end

                _, r = GetValueByFilter(addonDB.Widgets.Dialogs.Roll.InvalidRolls, function(k, v) return v.PlayerLabel:GetText() == fullName end)
                if r then
                    r.Add.Button:Hide()
                end
            end)
        end

        roll.Value = rollValue

        table.insert(rolls, roll)
        table.sort(rolls, function(a, b) 
            if a.ItemCount == nil and b.ItemCount == nil then
                return a.Value > b.Value
            end
            if a.ItemCount == nil then
                return false 
            end
            if b.ItemCount == nil then
                return true 
            end
            return a.ItemCount < b.ItemCount or (a.ItemCount == b.ItemCount and a.Value > b.Value)
        end)

        RearrangeFrames(rolls, "TOPLEFT", 0, -32, function(v) return v.Frame end, 10, -5)

        if #addonDB.Widgets.Dialogs.Roll.MainSpecRolls > 0 then
            for _, r in pairs(addonDB.Widgets.Dialogs.Roll.SecondSpecRolls) do
                r.Frame:SetScript("OnClick", function(self) end)
                r.Frame:SetScript("OnEnter", function(self) end)
            end
        end

        if #addonDB.Widgets.Dialogs.Roll.MainSpecRolls > 0 or #addonDB.Widgets.Dialogs.Roll.SecondSpecRolls > 0 then
            for _, r in pairs(addonDB.Widgets.Dialogs.Roll.TransmogRolls) do
                r.Frame:SetScript("OnClick", function(self) end)
                r.Frame:SetScript("OnEnter", function(self) end)
            end
        end
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Roll Dialog: Tier Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.Tier = {}
    addonDB.Widgets.Dialogs.Roll.Tier.Button, addonDB.Widgets.Dialogs.Roll.Tier.Text = CreateButton(addonDB.Widgets.Dialogs.Roll.Frame, "TIER", 102, 25, color.DarkGray, color.LightGray, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.Tier.Button, "TOP", 0, -120)
    addonDB.Widgets.Dialogs.Roll.Tier.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Roll.Tier.Button:SetScript("OnLeave", function(self)
        if self.pushed then
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        else
            local c = color.LightGray
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end
    end)
    addonDB.Widgets.Dialogs.Roll.Tier.Button:SetScript("OnClick", function(self)
        if not self.pushed then
            self.pushed = true
            self:Disable()
            addonDB.Widgets.Dialogs.Roll.TypeSelection = "Tier"
            self:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
            addonDB.Widgets.Dialogs.Roll.Rare.Button.pushed = false
            addonDB.Widgets.Dialogs.Roll.Rare.Button:Enable()
            addonDB.Widgets.Dialogs.Roll.Normal.Button.pushed = false
            addonDB.Widgets.Dialogs.Roll.Normal.Button:Enable()
            addonDB.Widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
            addonDB.Widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

            local setup = GetActiveSetup()
            local c = color.Gold
            -- Set orderButton active and update order
            setup.Order["Tier Low"].Button.pushed = true
            setup.Order["Tier Low"].Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
            setup.Order["Tier Low"].Button:Disable()

            -- update order of rolls
            for _, roll in pairs(addonDB.Widgets.Dialogs.Roll.MainSpecRolls) do
                -- Update priorities in rolls
                for _, player in pairs(setup.Players) do
                    if player.PlayerName == roll.PlayerLabel:GetText() then
                        local num = tonumber(player.TierText:GetText()) + tonumber(player.TierDiffText:GetText())
                        roll.ItemCount = num
                        roll.ItemCountLabel:SetText("Items: ".. num)
                        roll.ItemCountLabel:Show()
                        break
                    end
                end
            end

            table.sort(addonDB.Widgets.Dialogs.Roll.MainSpecRolls, function(a, b) 
                if a.ItemCount == nil and b.ItemCount == nil then
                    return a.Value > b.Value
                end
                if a.ItemCount == nil then
                    return false 
                end
                if b.ItemCount == nil then
                    return true 
                end
                return a.ItemCount < b.ItemCount or (a.ItemCount == b.ItemCount and a.Value > b.Value)
            end)

            local vOffset = -5
            for _, r in pairs(addonDB.Widgets.Dialogs.Roll.MainSpecRolls) do
                SetPoint(r.Frame, "TOPLEFT", 10, vOffset)
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
            vOffset = 0

            local sortedOrder = {}
            for i, player in pairs(setup.Players) do
                sortedOrder[player.PlayerName] = i
                SetPoint(player.Container, "TOPLEFT", 0, vOffset)
                vOffset = vOffset - 32
            end
            SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

            for k, config in pairs(addonDB.Configs) do
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
        end
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Roll Dialog: Rare Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Dialogs.Roll.Rare = {}
    addonDB.Widgets.Dialogs.Roll.Rare.Button, addonDB.Widgets.Dialogs.Roll.Rare.Text = CreateButton(addonDB.Widgets.Dialogs.Roll.Frame, "RARE", 102, 25, color.DarkGray, color.LightGray, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.Rare.Button, "RIGHT", addonDB.Widgets.Dialogs.Roll.Tier.Button, "LEFT", -14, 0)
    addonDB.Widgets.Dialogs.Roll.Rare.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Roll.Rare.Button:SetScript("OnLeave", function(self)
        if self.pushed then
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        else
            local c = color.LightGray
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end
    end)
    addonDB.Widgets.Dialogs.Roll.Rare.Button:SetScript("OnClick", function(self)
        if not self.pushed then
            self.pushed = true
            self:Disable()
            addonDB.Widgets.Dialogs.Roll.TypeSelection = "Rare"
            self:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
            addonDB.Widgets.Dialogs.Roll.Tier.Button.pushed = false 
            addonDB.Widgets.Dialogs.Roll.Tier.Button:Enable()
            addonDB.Widgets.Dialogs.Roll.Normal.Button.pushed = false 
            addonDB.Widgets.Dialogs.Roll.Normal.Button:Enable()
            addonDB.Widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
            addonDB.Widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

            for _, setup in pairs(addonDB.Widgets.Setups) do
                if setup.Tab.Button.pushed then
                    local c = color.Gold
                    -- Set orderButton active and update order
                    setup.Order["Rare Low"].Button.pushed = true
                    setup.Order["Rare Low"].Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                    setup.Order["Rare Low"].Button:Disable()

                    -- update order of rolls
                    for _, roll in pairs(addonDB.Widgets.Dialogs.Roll.MainSpecRolls) do
                        -- Update priorities in rolls
                        for _, player in pairs(setup.Players) do
                            if player.PlayerName == roll.PlayerLabel:GetText() then
                                local num = tonumber(player.RareText:GetText()) + tonumber(player.RareDiffText:GetText())
                                roll.ItemCount = num
                                roll.ItemCountLabel:SetText("Items: ".. num)
                                roll.ItemCountLabel:Show()
                                break
                            end
                        end
                    end

                    table.sort(addonDB.Widgets.Dialogs.Roll.MainSpecRolls, function(a, b) 
                        if a.ItemCount == nil and b.ItemCount == nil then
                            return a.Value > b.Value
                        end
                        if a.ItemCount == nil then
                            return false 
                        end
                        if b.ItemCount == nil then
                            return true 
                        end
                        return a.ItemCount < b.ItemCount or (a.ItemCount == b.ItemCount and a.Value > b.Value)
                    end)

                    local vOffset = -5
                    for _, r in pairs(addonDB.Widgets.Dialogs.Roll.MainSpecRolls) do
                        SetPoint(r.Frame, "TOPLEFT", 10, vOffset)
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
                        SetPoint(player.Container, "TOPLEFT", 0, vOffset)
                        vOffset = vOffset - 32
                    end
                    SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

                    for k, config in pairs(addonDB.Configs) do
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
    addonDB.Widgets.Dialogs.Roll.Normal = {}
    addonDB.Widgets.Dialogs.Roll.Normal.Button, addonDB.Widgets.Dialogs.Roll.Normal.Text = CreateButton(addonDB.Widgets.Dialogs.Roll.Frame, "NORMAL", 102, 25, color.DarkGray, color.LightGray, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.Normal.Button, "LEFT", addonDB.Widgets.Dialogs.Roll.Tier.Button, "RIGHT", 14, 0)
    addonDB.Widgets.Dialogs.Roll.Normal.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Roll.Normal.Button:SetScript("OnLeave", function(self)
        if self.pushed then
            local c = color.Gold
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        else
            local c = color.LightGray
            self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end
    end)
    addonDB.Widgets.Dialogs.Roll.Normal.Button:SetScript("OnClick", function(self)
        if not self.pushed then
            self.pushed = true
            self:Disable()
            addonDB.Widgets.Dialogs.Roll.TypeSelection = "Normal"
            self:SetBackdropBorderColor(color.Gold.r, color.Gold.g, color.Gold.b)
            addonDB.Widgets.Dialogs.Roll.Tier.Button.pushed = false
            addonDB.Widgets.Dialogs.Roll.Tier.Button:Enable()
            addonDB.Widgets.Dialogs.Roll.Rare.Button.pushed = false
            addonDB.Widgets.Dialogs.Roll.Rare.Button:Enable()
            addonDB.Widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
            addonDB.Widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

            for _, setup in pairs(addonDB.Widgets.Setups) do
                if setup.Tab.Button.pushed then
                    local c = color.Gold
                    -- Set orderButton active and update order
                    setup.Order["Normal Low"].Button.pushed = true
                    setup.Order["Normal Low"].Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                    setup.Order["Normal Low"].Button:Disable()

                    -- update order of rolls
                    for _, roll in pairs(addonDB.Widgets.Dialogs.Roll.MainSpecRolls) do
                        -- Update priorities in rolls
                        for _, player in pairs(setup.Players) do
                            if player.PlayerName == roll.PlayerLabel:GetText() then
                                local num = tonumber(player.NormalText:GetText()) + tonumber(player.NormalDiffText:GetText())
                                roll.ItemCount = num
                                roll.ItemCountLabel:SetText("Items: ".. num)
                                roll.ItemCountLabel:Show()
                                break
                            end
                        end
                    end

                    table.sort(addonDB.Widgets.Dialogs.Roll.MainSpecRolls, function(a, b) 
                        if a.ItemCount == nil and b.ItemCount == nil then
                            return a.Value > b.Value
                        end
                        if a.ItemCount == nil then
                            return false 
                        end
                        if b.ItemCount == nil then
                            return true 
                        end
                        return a.ItemCount < b.ItemCount or (a.ItemCount == b.ItemCount and a.Value > b.Value)
                    end)

                    local vOffset = -5
                    for _, r in pairs(addonDB.Widgets.Dialogs.Roll.MainSpecRolls) do
                        SetPoint(r.Frame, "TOPLEFT", 10, vOffset)
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
                        SetPoint(player.Container, "TOPLEFT", 0, vOffset)
                        vOffset = vOffset - 32
                    end
                    SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

                    for k, config in pairs(addonDB.Configs) do
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
    addonDB.Widgets.Dialogs.Roll.Assign = {}
    addonDB.Widgets.Dialogs.Roll.Assign.Button, addonDB.Widgets.Dialogs.Roll.Assign.Text = CreateButton(addonDB.Widgets.Dialogs.Roll.Frame, "ASSIGN", 125, 40, color.DarkGray, color.LightGray, color.Gold)
    SetPoint(addonDB.Widgets.Dialogs.Roll.Assign.Button, "LEFT", addonDB.Widgets.Dialogs.Roll.Roll.Button, "RIGHT", 20, 0)
    addonDB.Widgets.Dialogs.Roll.Assign.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Roll.Assign.Button:SetScript("OnLeave", function(self)
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Dialogs.Roll.Assign.Button:SetScript("OnClick", function(self)
        if addonDB.Widgets.Dialogs.Roll.Roll.Button.rollActive or addonDB.Widgets.Dialogs.Roll.AssignmentText:GetText() == "NO ASSIGNMENT YET"  or addonDB.Widgets.Dialogs.Roll.TypeSelection == nil then
            return
        end

        local playerName = addonDB.Widgets.Dialogs.Roll.AssignmentText:GetText()
        if addonDB.Widgets.Dialogs.Roll.RollType == "MainSpecRoll" then
            for _, setup in pairs(addonDB.Widgets.Setups) do
                if setup.Tab.Button.pushed then
                    for _, player in pairs(setup.Players) do
                        if player.PlayerName == playerName then
                            if addonDB.Widgets.Dialogs.Roll.TypeSelection == "Tier" then
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
                            elseif addonDB.Widgets.Dialogs.Roll.TypeSelection == "Rare" then
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
                            elseif addonDB.Widgets.Dialogs.Roll.TypeSelection == "Normal" then
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
                                print("[ERROR] RaidTables: No loot category selected!")
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
                                    SetPoint(player.Container, "TOPLEFT", 0, vOffset)
                                    vOffset = vOffset - 32
                                end
                                SetPoint(setup.TableBottomLine, "TOPLEFT", 5, vOffset + 2)

                                for k, config in pairs(addonDB.Configs) do
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
            ItemLink = addonDB.Widgets.Dialogs.Roll.ActiveItemLink,
            PlayerName = playerName,
            RollType = addonDB.Widgets.Dialogs.Roll.RollType,
            Class = addonDB.Widgets.Dialogs.Roll.Class
        }
        table.insert(addonDB.Widgets.Dialogs.Roll.AssignmentList, assignment)

        addonDB.Widgets.Dialogs.Roll.ActiveItemLink = nil
        addonDB.Widgets.Dialogs.Roll.TypeSelection = nil

        addonDB.Widgets.Dialogs.Roll.Tier.Button.pushed = false
        addonDB.Widgets.Dialogs.Roll.Tier.Button:Enable()
        addonDB.Widgets.Dialogs.Roll.Tier.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

        addonDB.Widgets.Dialogs.Roll.Rare.Button.pushed = false
        addonDB.Widgets.Dialogs.Roll.Rare.Button:Enable()
        addonDB.Widgets.Dialogs.Roll.Rare.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

        addonDB.Widgets.Dialogs.Roll.Normal.Button.pushed = false
        addonDB.Widgets.Dialogs.Roll.Normal.Button:Enable()
        addonDB.Widgets.Dialogs.Roll.Normal.Button:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)

        addonDB.Widgets.Dialogs.Roll.Assignment:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b)
        addonDB.Widgets.Dialogs.Roll.AssignmentText:SetText("NO ASSIGNMENT YET")
        addonDB.Widgets.Dialogs.Roll.AssignmentText:SetTextColor(color.White.r, color.White.g, color.White.b)

        for k, v in pairs(addonDB.Widgets.Dialogs.Roll.MainSpecRolls) do
            v.Frame:Hide()
            table.insert(addonDB.Widgets.Dialogs.Roll.FreeRolls, v)
        end
        addonDB.Widgets.Dialogs.Roll.MainSpecRolls = {}
        for k, v in pairs(addonDB.Widgets.Dialogs.Roll.SecondSpecRolls) do
            v.Frame:Hide()
            table.insert(addonDB.Widgets.Dialogs.Roll.FreeRolls, v)
        end
        addonDB.Widgets.Dialogs.Roll.SecondSpecRolls = {}
        for k, v in pairs(addonDB.Widgets.Dialogs.Roll.TransmogRolls) do
            v.Frame:Hide()
            table.insert(addonDB.Widgets.Dialogs.Roll.FreeRolls, v)
        end
        addonDB.Widgets.Dialogs.Roll.TransmogRolls = {}
        for k, v in pairs(addonDB.Widgets.Dialogs.Roll.InvalidRolls) do
            v.Frame:Hide()
            table.insert(addonDB.Widgets.Dialogs.Roll.FreeRolls, v)
        end
        addonDB.Widgets.Dialogs.Roll.InvalidRolls = {}

        HandleLootAssignment()
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Summary Dialog
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Summary = {}
    addonDB.Widgets.Summary.Items = {}
    addonDB.Widgets.Summary.FreeItems = {}
    addonDB.Widgets.Summary.Frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    SetSize(addonDB.Widgets.Summary.Frame, 280, 430)
    SetPoint(addonDB.Widgets.Summary.Frame, "CENTER", 0, 0)
    addonDB.Widgets.Summary.Frame:SetMovable(true)
    addonDB.Widgets.Summary.Frame:EnableMouse(true)
    addonDB.Widgets.Summary.Frame:RegisterForDrag("LeftButton")
    addonDB.Widgets.Summary.Frame:SetScript("OnDragStart", addonDB.Widgets.Summary.Frame.StartMoving)
    addonDB.Widgets.Summary.Frame:SetScript("OnDragStop", addonDB.Widgets.Summary.Frame.StopMovingOrSizing)
    addonDB.Widgets.Summary.Frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = math.max(1, Scaled(2)),
    })
    addonDB.Widgets.Summary.Frame:SetBackdropColor(0, 0, 0, 1)
    addonDB.Widgets.Summary.Frame:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, 1)
    addonDB.Widgets.Summary.Frame:SetFrameStrata("DIALOG")
    addonDB.Widgets.Summary.Frame:Hide()

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Summary Dialog Header
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Summary.Header = CreateHeading("SUMMARY", GetWidth(addonDB.Widgets.Summary.Frame) - 10, addonDB.Widgets.Summary.Frame, 5, -10, true)

    -----------------------------------------------------------------------------------------------------------------------
    -- Create Summary Dialog Close Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Summary.Close = {}
    addonDB.Widgets.Summary.Close.Button, addonDB.Widgets.Summary.Close.Text = CreateButton(addonDB.Widgets.Summary.Frame, "CLOSE", 102, 30, color.DarkGray, color.LightGray, color.Gold)
    SetPoint(addonDB.Widgets.Summary.Close.Button, "BOTTOMRIGHT", addonDB.Widgets.Summary.Frame, "BOTTOMRIGHT", -10, 10)
    addonDB.Widgets.Summary.Close.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Summary.Close.Button:SetScript("OnLeave", function(self)
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Summary.Close.Button:SetScript("OnClick", function(self)
        addonDB.Widgets.Dialogs.Roll.AssignmentList = {}
        addonDB.Widgets.Summary.Frame:Hide()
        -- Free all frames
        for _, w in pairs(addonDB.Widgets.Summary.Items) do
            table.insert(addonDB.Widgets.Summary.FreeItems, w)
            w.Frame:Hide()
        end
        addonDB.Widgets.Summary.Items = {}
        -- Show Roll frame again if rolls came up while summary was shown
        HandleLootAssignment()
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Setup New Raid Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.NewRaid = {}
    addonDB.Widgets.NewRaid.Button, addonDB.Widgets.NewRaid.Text= CreateButton(addonDB.Widgets.Addon, "New RAID", 102, 35, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.NewRaid.Button, "BOTTOMLEFT", 6, 66)
    addonDB.Widgets.NewRaid.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.NewRaid.Button:SetScript("OnLeave", function(self)
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.NewRaid.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        addonDB.Widgets.Dialogs.NewRaid.Frame:Show()
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Setup Import Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Import = {}
    addonDB.Widgets.Import.Button, addonDB.Widgets.Import.Text = CreateButton(addonDB.Widgets.Addon, "Import", 102, 35, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Import.Button, "BOTTOMLEFT", 6, 25)
    addonDB.Widgets.Import.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Import.Button:SetScript("OnLeave", function(self)
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Import.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        addonDB.Widgets.Dialogs.Import.Frame:Show()
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Setup AddPlayers Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.AddPlayers = {}
    addonDB.Widgets.AddPlayers.Button, addonDB.Widgets.AddPlayers.Text = CreateButton(addonDB.Widgets.Addon, "Add Players", 102, 35, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.AddPlayers.Button, "BOTTOMLEFT", 112, 66)
    addonDB.Widgets.AddPlayers.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.AddPlayers.Button:SetScript("OnLeave", function(self)
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.AddPlayers.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end

        for _, setup in pairs(addonDB.Widgets.Setups) do
            if setup.Tab.Button.pushed then
                local units = GetUnregisteredPlayers(setup)
                for _, unit in pairs(units) do
                    -- Create frame
                    local player = {}
                    player.Class = unit.Class
                    local c = classColor[unit.Class]
                    if #addonDB.Widgets.Dialogs.AddPlayers.FreePlayerFrames > 0 then
                        for k, v in pairs(addonDB.Widgets.Dialogs.AddPlayers.FreePlayerFrames) do
                            player = v
                            player.Container:Show()
                            player.Checkbox:SetChecked(false)
                            player.Name:SetText(unit.Name)
                            player.Name:SetTextColor(c.r, c.g, c.b)
                            SetPoint(player.Container, "TOPLEFT", 10, -10 + -33 * #addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames)
                            table.insert(addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames, player)
                            table.remove(addonDB.Widgets.Dialogs.AddPlayers.FreePlayerFrames, k)
                            break 
                        end
                    else
                        player.Container = CreateFrame("Frame", nil, addonDB.Widgets.Dialogs.AddPlayers.ScrollView, "BackdropTemplate")
                        SetWidth(player.Container, GetWidth(addonDB.Widgets.Dialogs.AddPlayers.ScrollView) - 20)
                        SetHeight(player.Container, 30)
                        player.Container:SetBackdrop({
                            bgFile = "Interface\\Buttons\\WHITE8x8",
                            edgeFile = "Interface\\Buttons\\WHITE8x8",
                            edgeSize = math.max(1, Scaled(2)),
                        })
                        player.Container:SetBackdropColor(color.DarkGray.r, color.DarkGray.g, color.DarkGray.b, color.DarkGray.a)
                        player.Container:SetBackdropBorderColor(color.LightGray.r, color.LightGray.g, color.LightGray.b, color.LightGray.a)
                        SetPoint(player.Container, "TOPLEFT", 10, -10 + -33 * #addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames)
                        player.Name = CreateLabel(unit.Name, player.Container, 100, -9, classColor[unit.Class])
                        player.Checkbox = CreateFrame("CheckButton", nil, player.Container, "ChatConfigCheckButtonTemplate")
                        SetSize(player.Checkbox, 24, 24)
                        player.Checkbox:SetChecked(false)
                        SetPoint(player.Checkbox, "TOPLEFT", 30, -3)
                        table.insert(addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames, player)
                    end
                end
                break;
            end
        end

        addonDB.Widgets.Dialogs.AddPlayers.Frame:Show()
    end)

    -----------------------------------------------------------------------------------------------------------------------
    -- Setup Options Button
    -----------------------------------------------------------------------------------------------------------------------
    addonDB.Widgets.Options = {}
    addonDB.Widgets.Options.Button, addonDB.Widgets.Options.Text = CreateButton(addonDB.Widgets.Addon, "Options", 102, 35, color.DarkGray, color.LightGray)
    SetPoint(addonDB.Widgets.Options.Button, "BOTTOMLEFT", 112, 25)
    addonDB.Widgets.Options.Button:SetScript("OnEnter", function(self)
        local c = color.Gold
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Options.Button:SetScript("OnLeave", function(self)
        local c = color.LightGray
        self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    addonDB.Widgets.Options.Button:SetScript("OnClick", function(self)
        if IsDialogShown() then
            return
        end
        addonDB.Widgets.Dialogs.Options.Frame:ClearAllPoints()
        SetPoint(addonDB.Widgets.Dialogs.Options.Frame, "CENTER", addonDB.Widgets.Addon, "CENTER", 0, 0)
        addonDB.Widgets.Dialogs.Options.TierIdInputField:SetText(ArrayToString(addonDB.Options.TierItems))
        addonDB.Widgets.Dialogs.Options.RareIdInputField:SetText(ArrayToString(addonDB.Options.RareItems))
        addonDB.Widgets.Dialogs.Options.Frame:Show()
    end)

end

-----------------------------------------------------------------------------------------------------------------------
-- Register Addon Events
-----------------------------------------------------------------------------------------------------------------------
addonDB.Widgets.Addon:RegisterEvent("ADDON_LOADED")
addonDB.Widgets.Addon:RegisterEvent("PLAYER_LOGOUT")
addonDB.Widgets.Addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addonDB.Widgets.Addon:RegisterEvent("START_LOOT_ROLL")
addonDB.Widgets.Addon:RegisterEvent("RAID_INSTANCE_WELCOME")
addonDB.Widgets.Addon:RegisterEvent("GROUP_ROSTER_UPDATE")

-----------------------------------------------------------------------------------------------------------------------
-- Callback for Event Handling
-----------------------------------------------------------------------------------------------------------------------
addonDB.Widgets.Addon:SetScript("OnEvent", function(self, event, arg1, ...) 
    if event == "ADDON_LOADED" and arg1 == addonName then
        ---------------------------------------------------------------------------------------------------------------
        -- Get SavedVariables
        ---------------------------------------------------------------------------------------------------------------
        local savedVariable = RaidTablesDB or {}
        addonDB.Options = MergeTables(addonDB.Options or {}, savedVariable.Options or {})
        addonDB.Configs = MergeTables(addonDB.Configs or {}, savedVariable.Configs or {})

        ---------------------------------------------------------------------------------------------------------------
        -- Set Minimap Position
        ---------------------------------------------------------------------------------------------------------------
        addonDB.Widgets.Minimap.Button:SetPoint("CENTER", Minimap, "BOTTOMLEFT", addonDB.Options.Minimap.X, addonDB.Options.Minimap.Y)

        ---------------------------------------------------------------------------------------------------------------
        -- Setup User Interface
        ---------------------------------------------------------------------------------------------------------------
        SetupUserInterface()

        ---------------------------------------------------------------------------------------------------------------
        -- Setup Configuration Frames
        ---------------------------------------------------------------------------------------------------------------
        local hasEntries = false
        for k, v in pairs(addonDB.Configs) do
            SetupNewEntry(v, k == 1)
            hasEntries = true
        end

        if not hasEntries then
            local c = color.LightGray
            addonDB.Widgets.Export.Button:Hide()
            addonDB.Widgets.Save.Button:Hide()
            addonDB.Widgets.Print.Button:Hide()
            addonDB.Widgets.AddPlayers.Button:Disable()
            addonDB.Widgets.AddPlayers.Text:SetTextColor(c.r, c.g, c.b, c.a)
        end
        
        ---------------------------------------------------------------------------------------------------------------
        -- Registery Addon Message
        ---------------------------------------------------------------------------------------------------------------
        addonDB.ChatMsgRegistered = C_ChatInfo.RegisterAddonMessagePrefix("RTConfig") 
        addonDB.ChatMsgRegistered = addonDB.ChatMsgRegistered and C_ChatInfo.RegisterAddonMessagePrefix("RTSummary") 

        if not addonDB.ChatMsgRegistered then
            print("[ERROR] RaidTables: Addon Chat Message Registration FAILED.")
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        addonDB.LastEncodedConfig = nil

    elseif event == "PLAYER_ENTERING_WORLD" then
        if IsInRaid() and not addonDB.Tracking.Active and not addonDB.Widgets.Dialogs.ActivateRaid.Frame:IsShown() then
            addonDB.Widgets.Dialogs.ActivateRaid.SetupSelection()
            addonDB.Widgets.Dialogs.ActivateRaid.Frame:Show()
        end

    elseif event == "PLAYER_LOGOUT" then
        RaidTablesDB = {}
        RaidTablesDB.Configs = addonDB.Configs
        RaidTablesDB.Options = addonDB.Options

    elseif event == "RAID_INSTANCE_WELCOME" then
        if not addonDB.Tracking.Active and not addonDB.Widgets.Dialogs.ActivateRaid.Frame:IsShown() then
            addonDB.Widgets.Dialogs.ActivateRaid.SetupSelection()
            addonDB.Widgets.Dialogs.ActivateRaid.Frame:Show()
        elseif addonDB.Tracking.Active then
            ShareConfiguration(select(2, GetConfigByName(addonDB.Tracking.Name)))
        end

    elseif event == "START_LOOT_ROLL" and arg1 then
        if addonDB.Tracking.Active and IsInRaid() then
            local itemLink = GetLootRollItemLink(arg1)
            addonDB.Widgets.Dialogs.Roll.Items = addonDB.Widgets.Dialogs.Roll.Items or {}
            table.insert(addonDB.Widgets.Dialogs.Roll.Items, itemLink)

            for _, s in pairs(addonDB.Widgets.Setups) do
                if addonDB.Tracking.Name == nil and s.Tab.Button.pushed then
                    addonDB.Tracking.Name = s.Name
                elseif s.Name == addonDB.Tracking.Name then
                    -- Activate the tracked Raid Tab
                    s.Tab.Button.pushed = true
                    s.Tab.Button:Disable()
                    local c = color.Gold
                    s.Tab.Button:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
                    s.Content:Show()
                    if addonDB.Tracking.Active and addonDB.Tracking.Name == s.Tab.Text:GetText() then
                        addonDB.Widgets.Share.Frame:Show()
                    else
                        addonDB.Widgets.Share.Frame:Hide()
                    end
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
SLASH_RAID_TABLES_COMMAND1 = "/rtables"
local function SlashCommandHandler(msg)
    if msg == "help" then
        print("LootTables - Help Menu")
        print(" ")
        print("Options:")
        print("  help: Show this help menu.")
        print("  stats: Show stats of the addon.")
    elseif msg == "scale up" then
        addonDB.Options.Scaling = addonDB.Options.Scaling + 0.1
        print("Scaling after Reload: " .. addonDB.Options.Scaling)
    elseif msg == "scale down" then
        addonDB.Options.Scaling = addonDB.Options.Scaling - 0.1
        print("Scaling after Reload: " .. addonDB.Options.Scaling)
    elseif msg == "msg test" then
        if addonDB.ChatMsgRegistered then
            for _, v in pairs(addonDB.Configs) do
                for _, p in pairs(v.PlayerInfos) do
                    local success = C_ChatInfo.SendAddonMessage("RTConfig", p.Name .. ":" .. p.Class .. ":"..p.Rare..":"..p.Tier..":"..p.Normal, "PARTY", UnitName("player"))
                    if success then
                        print("[SUCCESS] RaidTables: Message transmitted!")
                    else
                        print("[FAILURE] RaidTables: Message NOT transmitted!")
                    end
                    return
                end
            end
        end
    elseif msg == "stats" then
        print("Created Frames = "..createdFrameCount)
        print("Raid Configs = "..#addonDB.Configs)
        print("Free Raid Entities = "..#addonDB.Widgets.FreeSetups)
        print("Free Player Entities = "..#addonDB.Widgets.FreePlayers)
        print("Player List Items = "..#addonDB.Widgets.Dialogs.AddPlayers.PlayerFrames)
        print("Free Player List Items = "..#addonDB.Widgets.Dialogs.AddPlayers.FreePlayerFrames)
    elseif msg == "roll test" then
        addonDB.Testing = true

        local item = "|cffa335ee|Hitem:196590::::::::60:577::6:4:7188:6652:1485:6646:1:28:752:::|h[Dreadful Topaz Forgestone]|h|r"
        table.insert(addonDB.Widgets.Dialogs.Roll.Items, item)
        item = "|cffa335ee|Hitem:19019::::::::120:265::5::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r"
        table.insert(addonDB.Widgets.Dialogs.Roll.Items, item)
        item = "|cffa335ee|Hitem:188032::::::::60:269::4:4:7183:6652:1472:6646:1:28:1707:::|h[Thunderous Echo Vambraces]|h|r"
        table.insert(addonDB.Widgets.Dialogs.Roll.Items, item)

        for _, s in pairs(addonDB.Widgets.Setups) do
            if addonDB.Tracking.Name == nil and s.Tab.Button.pushed then
                EnableTracking(s.Name, false)
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
        if not addonDB.Widgets.Addon:IsShown() then
            addonDB.Widgets.Addon:Show()
        else 
            addonDB.Widgets.Addon:Hide()
        end
    end
end
SlashCmdList.RAID_TABLES_COMMAND = SlashCommandHandler

-----------------------------------------------------------------------------------------------------------------------
-- Create Minimap Button
-----------------------------------------------------------------------------------------------------------------------
addonDB.Widgets.Minimap.Button = CreateFrame("Button", addonName, Minimap)
SetPoint(addonDB.Widgets.Minimap.Button, "CENTER", Minimap, "BOTTOMLEFT", 10, -10)
addonDB.Widgets.Minimap.Overlay = addonDB.Widgets.Minimap.Button:CreateTexture(nil, "OVERLAY")
addonDB.Widgets.Minimap.Overlay:SetSize(50, 50)
addonDB.Widgets.Minimap.Overlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
addonDB.Widgets.Minimap.Overlay:SetPoint("TOPLEFT", addonDB.Widgets.Minimap.Button, "TOPLEFT", 0, 0)
addonDB.Widgets.Minimap.Background = addonDB.Widgets.Minimap.Button:CreateTexture(nil, "BACKGROUND")
addonDB.Widgets.Minimap.Background:SetSize(24, 24)
addonDB.Widgets.Minimap.Background:SetTexture(136467) --"Interface\\Minimap\\UI-Minimap-Background"
addonDB.Widgets.Minimap.Background:SetPoint("CENTER", addonDB.Widgets.Minimap.Button, "CENTER", 0, 1)
addonDB.Widgets.Minimap.Icon = addonDB.Widgets.Minimap.Button:CreateTexture(nil, "ARTWORK")
addonDB.Widgets.Minimap.Icon:SetSize(18, 18)
addonDB.Widgets.Minimap.Icon:SetTexture("Interface\\AddOns\\RaidTables\\img\\RaidTables.png")
addonDB.Widgets.Minimap.Icon:SetPoint("CENTER", addonDB.Widgets.Minimap.Button, "CENTER", 0, 1)
addonDB.Widgets.Minimap.Button:SetMovable(true)
addonDB.Widgets.Minimap.Button:EnableMouse(true)
addonDB.Widgets.Minimap.Button:RegisterForDrag("LeftButton")
addonDB.Widgets.Minimap.Button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(addonName)
    GameTooltip:AddLine("Click to show ".. addonName .. " frame", 1, 1, 1)
    GameTooltip:Show()
end)
addonDB.Widgets.Minimap.Button:SetScript("OnLeave", function() GameTooltip:Hide() end)
addonDB.Widgets.Minimap.Button:SetScript("OnClick", function(self)
    if addonDB.Widgets.Addon:IsShown() then
        if IsDialogShown() then
            return
        end
        addonDB.Widgets.Addon:Hide()
    else
        addonDB.Widgets.Addon:Show()
    end
end)
addonDB.Widgets.Minimap.Button:SetScript("OnDragStart", function(self)
    self.moving = true
    self:StartMoving()
end)
addonDB.Widgets.Minimap.Button:SetScript("OnDragStop", function(self)
    self.moving = false
    self:StopMovingOrSizing()
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local left = Minimap:GetLeft()
    local bottom = Minimap:GetBottom()

    x = x / scale
    y = y / scale

    addonDB.Options.Minimap.X = x - left
    addonDB.Options.Minimap.Y = y - bottom
end)
addonDB.Widgets.Minimap.Button:SetScript("OnUpdate", function(self)
    if self.moving then
        local x, y = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local left = Minimap:GetLeft()
        local right = Minimap:GetRight()
        local top = Minimap:GetTop()
        local bottom = Minimap:GetBottom()

        x = x / scale
        y = y / scale

        if x > left and x < right and y > bottom and y < top then
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "BOTTOMLEFT", x - left, y - bottom)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------
-- Hide Addon Frame Initially
-----------------------------------------------------------------------------------------------------------------------
addonDB.Widgets.Addon:Hide()
