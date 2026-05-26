SLASH_LOCPIN1 = "/loc"
SLASH_LOCPINP1 = "/locpin"
SLASH_LOCDIAG1 = "/locdiag"

local LocPin = {
    x = nil,
    y = nil,
    mapID = nil,
    zoneName = nil,
    name = nil,
    desc = nil,
    pinType = "circle",
    marker = nil,
}

-- Add more zones here as needed.
-- These are the important early Alliance / Paladin-route zones.
local ZONES = {
    ["current"] = "current",

    ["dun morogh"] = 1426,
    ["elwynn forest"] = 1429,
    ["loch modan"] = 1432,
    ["westfall"] = 1436,
    ["redridge mountains"] = 1433,
    ["redridge"] = 1433,
    ["duskwood"] = 1431,
    ["wetlands"] = 1437,

    ["stormwind"] = 1453,
    ["stormwind city"] = 1453,
    ["ironforge"] = 1455,

    ["darkshore"] = 1439,
    ["ashenvale"] = 1440,
    ["silverpine forest"] = 1421,
    ["silverpine"] = 1421,

    ["arathi highlands"] = 1417,
    ["arathi"] = 1417,
    ["stranglethorn vale"] = 1434,
    ["stv"] = 1434,
}

local PIN_TEXTURES = {
    star = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    circle = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
    diamond = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
    triangle = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
    moon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
    square = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
    x = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    skull = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",

    quest = "Interface\\GossipFrame\\AvailableQuestIcon",
    turnin = "Interface\\GossipFrame\\ActiveQuestIcon",
}

local function bit(v)
    return v and "1" or "0"
end

local function trim(s)
    return (s or ""):match("^%s*(.-)%s*$")
end

local function normalizeZone(s)
    s = trim(s or ""):lower()
    s = s:gsub("%s+", " ")
    return s
end

local function consumeToken(s)
    s = trim(s or "")

    if s:sub(1, 1) == '"' then
        local value, rest = s:match('^"([^"]*)"%s*(.*)$')
        return value, rest
    end

    local value, rest = s:match("^(%S+)%s*(.*)$")
    return value, rest
end

local function getCurrentZoneMapID()
    if C_Map and C_Map.GetBestMapForUnit then
        return C_Map.GetBestMapForUnit("player")
    end
    return nil
end

local function getShownMapID()
    if WorldMapFrame and WorldMapFrame.GetMapID then
        return WorldMapFrame:GetMapID()
    end
    return nil
end

local function resolveZone(zoneName)
    local key = normalizeZone(zoneName)

    if key == "" or key == "current" then
        return getCurrentZoneMapID(), "Current Zone"
    end

    local mapID = ZONES[key]

    if mapID == "current" then
        return getCurrentZoneMapID(), "Current Zone"
    end

    if mapID then
        return mapID, zoneName
    end

    return nil, zoneName
end

local function parseCoords(s)
    s = trim(s or "")

    local x, y, rest = s:match("^([%d%.]+)%s*,%s*([%d%.]+)%s*(.*)$")

    if not x or not y then
        x, y, rest = s:match("^([%d%.]+)%s+([%d%.]+)%s*(.*)$")
    end

    x = tonumber(x)
    y = tonumber(y)

    if not x or not y then
        return nil, nil, s
    end

    return x, y, rest
end

local function getMapCanvas()
    if not WorldMapFrame then return nil end

    if WorldMapFrame.ScrollContainer then
        if WorldMapFrame.ScrollContainer.Child then
            return WorldMapFrame.ScrollContainer.Child
        end

        if WorldMapFrame.ScrollContainer.GetCanvas then
            return WorldMapFrame.ScrollContainer:GetCanvas()
        end
    end

    return WorldMapFrame
end

local function ensureMapOpenOnPinnedZone()
    if not WorldMapFrame then
        print("LocPin: WorldMapFrame not available.")
        return false
    end

    if not WorldMapFrame:IsShown() then
        if ToggleWorldMap then
            ToggleWorldMap()
        else
            WorldMapFrame:Show()
        end
    end

    if LocPin.mapID and WorldMapFrame.SetMapID then
        WorldMapFrame:SetMapID(LocPin.mapID)
    end

    return true
end

local function applyPinTexture()
    if not LocPin.marker or not LocPin.marker.icon then return end

    local pinType = LocPin.pinType or "circle"
    local texture = PIN_TEXTURES[pinType] or PIN_TEXTURES.circle

    LocPin.marker.icon:SetTexture(texture)
end

local function ensureMarker()
    if LocPin.marker then return LocPin.marker end

    local canvas = getMapCanvas()

    if not canvas then
        print("LocPin: map canvas not found. Open your map once and try again.")
        return nil
    end

    local marker = CreateFrame("Frame", "LocPinMarker", canvas)
    marker:SetSize(52, 52)
    marker:SetFrameStrata("TOOLTIP")
    marker:EnableMouse(true)
    marker:Hide()

    marker.icon = marker:CreateTexture(nil, "OVERLAY")
    marker.icon:SetSize(24, 24)
    marker.icon:SetPoint("CENTER", marker, "CENTER", 0, 4)

    marker.label = marker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    marker.label:SetTextColor(1, 1, 1)
    marker.label:SetPoint("TOP", marker.icon, "BOTTOM", 0, -1)

    marker:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(LocPin.name or "LocPin", 1, 1, 1)

        if LocPin.zoneName then
            GameTooltip:AddLine(LocPin.zoneName, 0.8, 0.8, 0.8)
        end

        if LocPin.x and LocPin.y then
            GameTooltip:AddLine(string.format("%.1f, %.1f", LocPin.x * 100, LocPin.y * 100), 1, 0.82, 0)
        end

        if LocPin.desc and LocPin.desc ~= "" then
            GameTooltip:AddLine(LocPin.desc, 0.9, 0.9, 0.9, true)
        end

        GameTooltip:Show()
    end)

    marker:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    LocPin.marker = marker
    applyPinTexture()

    return marker
end

local function updateMarker()
    if not LocPin.x or not LocPin.y or not LocPin.mapID then
        if LocPin.marker then LocPin.marker:Hide() end
        return
    end

    local shownMapID = getShownMapID()

    if WorldMapFrame and WorldMapFrame:IsShown() and WorldMapFrame.SetMapID and shownMapID ~= LocPin.mapID then
        WorldMapFrame:SetMapID(LocPin.mapID)
    end

    local canvas = getMapCanvas()
    if not canvas then return end

    local marker = ensureMarker()
    if not marker then return end

    applyPinTexture()

    marker:SetParent(canvas)
    marker:ClearAllPoints()

    local w = canvas:GetWidth() or 0
    local h = canvas:GetHeight() or 0

    if w <= 0 or h <= 0 then
        marker:Hide()
        return
    end

    marker:SetPoint("CENTER", canvas, "TOPLEFT", LocPin.x * w, -LocPin.y * h)

    if LocPin.name and LocPin.name ~= "" then
        marker.label:SetText(LocPin.name)
    else
        marker.label:SetText(string.format("%.1f, %.1f", LocPin.x * 100, LocPin.y * 100))
    end

    marker:Show()
end

local function setPin(mapID, zoneName, x, y, name, pinType, desc)
    if not mapID then
        print("LocPin: missing mapID.")
        return
    end

    if x < 0 or x > 100 or y < 0 or y > 100 then
        print("LocPin: coordinates must be between 0 and 100.")
        return
    end

    LocPin.mapID = mapID
    LocPin.zoneName = zoneName
    LocPin.x = x / 100
    LocPin.y = y / 100
    LocPin.name = name or "Pin"
    LocPin.pinType = pinType or "circle"
    LocPin.desc = desc or ""

    ensureMapOpenOnPinnedZone()
    updateMarker()

    print(string.format(
        "LocPin: %s %.1f, %.1f in %s.",
        LocPin.name or "Pin",
        x,
        y,
        LocPin.zoneName or "mapID " .. tostring(mapID)
    ))
end

local function clearPin()
    LocPin.x = nil
    LocPin.y = nil
    LocPin.mapID = nil
    LocPin.zoneName = nil
    LocPin.name = nil
    LocPin.desc = nil
    LocPin.pinType = "circle"

    if LocPin.marker then
        LocPin.marker:Hide()
    end

    print("LocPin: cleared pin.")
end

-- Simple command for you:
-- /loc 81.2,30.1
-- /loc 81.2 30.1
-- /loc clears
SlashCmdList["LOCPIN"] = function(msg)
    msg = msg or ""

    if msg:match("^%s*$") then
        clearPin()
        return
    end

    local x, y = parseCoords(msg)

    if not x or not y then
        print("Usage: /loc 81.2,30.1")
        print("Or:    /loc 81.2 30.1")
        print("Use /loc with no coordinates to clear.")
        return
    end

    local mapID = getCurrentZoneMapID()

    if not mapID then
        print("LocPin: could not determine current zone map.")
        return
    end

    setPin(mapID, "Current Zone", x, y, "Pin", "circle", "")
end

-- Rich pin command:
-- /locpin Keeshan "Redridge Mountains" 28.5,12.1 circle "Corporal Keeshan - Missing In Action"
-- /locpin "Corporal Keeshan" "Redridge Mountains" 28.5 12.1 circle "Missing In Action"
SlashCmdList["LOCPINP"] = function(msg)
    msg = msg or ""

    if msg:match("^%s*$") then
        clearPin()
        return
    end

    local name, rest = consumeToken(msg)
    local zoneName

    zoneName, rest = consumeToken(rest)

    local x, y
    x, y, rest = parseCoords(rest)

    local pinType
    pinType, rest = consumeToken(rest)

    local desc = trim(rest or "")

    if desc:sub(1, 1) == '"' then
        desc = desc:match('^"([^"]*)"%s*$') or desc
    end

    if not name or not zoneName or not x or not y then
        print('Usage: /locpin Name "Zone Name" 81.2,30.1 circle "Description"')
        print('Example: /locpin Keeshan "Redridge Mountains" 28.5,12.1 circle "Missing In Action"')
        return
    end

    pinType = normalizeZone(pinType or "circle")

    if not PIN_TEXTURES[pinType] then
        print("LocPin: unknown pin type '" .. tostring(pinType) .. "', using circle.")
        pinType = "circle"
    end

    local mapID, resolvedZoneName = resolveZone(zoneName)

    if not mapID then
        print("LocPin: unknown zone '" .. tostring(zoneName) .. "'. Add it to the ZONES table.")
        return
    end

    setPin(mapID, resolvedZoneName, x, y, name, pinType, desc)
end

SlashCmdList["LOCDIAG"] = function()
    local W = WorldMapFrame
    local S = W and W.ScrollContainer
    local F = CreateFrame and CreateFrame("Frame")
    local TX = F and F.CreateTexture and F:CreateTexture(nil, "OVERLAY")

    print("LD:" ..
        bit(C_Map) ..
        bit(C_Map and C_Map.GetBestMapForUnit) ..
        bit(C_Map and C_Map.SetUserWaypoint) ..
        bit(C_Map and C_Map.ClearUserWaypoint) ..
        bit(UiMapPoint) ..
        bit(CreateVector2D) ..
        bit(W) ..
        bit(W and W.GetMapID) ..
        bit(W and W.SetMapID) ..
        bit(S) ..
        bit(S and S.Child) ..
        bit(S and S.GetCanvas) ..
        bit(CreateFrame) ..
        bit(F and F.CreateTexture) ..
        bit(TX) ..
        bit(TX and TX.SetTexture) ..
        bit(TX and TX.SetAtlas) ..
        bit(TX and TX.SetTexCoord) ..
        bit(TX and TX.SetVertexColor) ..
        bit(TX and TX.SetSize) ..
        bit(TX and TX.SetPoint) ..
        bit(TX and TX.SetParent) ..
        bit(TX and TX.Show) ..
        bit(TX and TX.Hide) ..
        bit(TX and TX.SetDrawLayer) ..
        bit(ToggleWorldMap)
    )

    print("CurrentZoneMapID:" .. tostring(getCurrentZoneMapID()))
    print("ShownMapID:" .. tostring(getShownMapID()))
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnUpdate", function()
    if WorldMapFrame and WorldMapFrame:IsShown() then
        updateMarker()
    end
end)