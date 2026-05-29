SLASH_LOCPIN1 = "/loc"
SLASH_LOCPINP1 = "/locpin"
SLASH_LOCDIAG1 = "/locdiag"
SLASH_LOCPROBE1 = "/locprobe"

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

-- Classic Era outdoor zones and capital city map IDs.
-- Keys are normalized by normalizeZone(), so use lowercase aliases here.
local ZONES = {
    ["current"] = "current",

    -- Eastern Kingdoms
    ["alterac mountains"] = 1416,
    ["alterac"] = 1416,
    ["arathi highlands"] = 1417,
    ["arathi"] = 1417,
    ["badlands"] = 1418,
    ["blasted lands"] = 1419,
    ["blasted"] = 1419,
    ["tirisfal glades"] = 1420,
    ["tirisfal"] = 1420,
    ["silverpine forest"] = 1421,
    ["silverpine"] = 1421,
    ["western plaguelands"] = 1422,
    ["wpl"] = 1422,
    ["eastern plaguelands"] = 1423,
    ["epl"] = 1423,
    ["hillsbrad foothills"] = 1424,
    ["hillsbrad"] = 1424,
    ["the hinterlands"] = 1425,
    ["hinterlands"] = 1425,
    ["dun morogh"] = 1426,
    ["searing gorge"] = 1427,
    ["searing"] = 1427,
    ["burning steppes"] = 1428,
    ["burning"] = 1428,
    ["elwynn forest"] = 1429,
    ["elwynn"] = 1429,
    ["deadwind pass"] = 1430,
    ["deadwind"] = 1430,
    ["duskwood"] = 1431,
    ["loch modan"] = 1432,
    ["redridge mountains"] = 1433,
    ["redridge"] = 1433,
    ["stranglethorn vale"] = 1434,
    ["stranglethorn"] = 1434,
    ["stv"] = 1434,
    ["swamp of sorrows"] = 1435,
    ["sos"] = 1435,
    ["westfall"] = 1436,
    ["wetlands"] = 1437,
    ["stormwind"] = 1453,
    ["stormwind city"] = 1453,
    ["ironforge"] = 1455,
    ["undercity"] = 1458,
    ["uc"] = 1458,

    -- Kalimdor
    ["durotar"] = 1411,
    ["mulgore"] = 1412,
    ["the barrens"] = 1413,
    ["barrens"] = 1413,
    ["teldrassil"] = 1438,
    ["darkshore"] = 1439,
    ["ashenvale"] = 1440,
    ["thousand needles"] = 1441,
    ["1k needles"] = 1441,
    ["stonetalon mountains"] = 1442,
    ["stonetalon"] = 1442,
    ["desolace"] = 1443,
    ["feralas"] = 1444,
    ["dustwallow marsh"] = 1445,
    ["dustwallow"] = 1445,
    ["tanaris"] = 1446,
    ["azshara"] = 1447,
    ["felwood"] = 1448,
    ["ungoro crater"] = 1449,
    ["un'goro crater"] = 1449,
    ["un'goro"] = 1449,
    ["ungoro"] = 1449,
    ["moonglade"] = 1450,
    ["silithus"] = 1451,
    ["winterspring"] = 1452,
    ["orgrimmar"] = 1454,
    ["org"] = 1454,
    ["thunder bluff"] = 1456,
    ["tb"] = 1456,
    ["darnassus"] = 1457,
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

local function bitFromBool(v)
    return v and 1 or 0
end

local function appendBit(bits, v)
    bits[#bits + 1] = bitFromBool(v)
end

local function bitsToString(bits)
    local out = {}

    for i = 1, #bits do
        out[i] = bits[i] == 1 and "1" or "0"
    end

    return table.concat(out)
end

local function bitsToHex(bits)
    local hex = "0123456789ABCDEF"
    local out = {}
    local nibble = 0
    local nibbleBits = 0

    for i = 1, #bits do
        nibble = (nibble * 2) + (bits[i] == 1 and 1 or 0)
        nibbleBits = nibbleBits + 1

        if nibbleBits == 4 then
            out[#out + 1] = hex:sub(nibble + 1, nibble + 1)
            nibble = 0
            nibbleBits = 0
        end
    end

    if nibbleBits > 0 then
        nibble = nibble * (2 ^ (4 - nibbleBits))
        out[#out + 1] = hex:sub(nibble + 1, nibble + 1)
    end

    return table.concat(out)
end

local function status(v)
    return v and "OK" or "FAIL"
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

    if shownMapID and shownMapID ~= LocPin.mapID then
        if LocPin.marker then LocPin.marker:Hide() end
        return
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

local function probeLine(group, check, ok, details)
    print(string.format(
        "LP11508|%s|%s|%s|%s",
        tostring(group or "GEN"),
        tostring(check or "unknown"),
        ok and "OK" or "FAIL",
        tostring(details or "")
    ))
end

local function runMapProbe()
    local pass, total = 0, 0
    local function check(name, ok, details)
        total = total + 1
        if ok then pass = pass + 1 end
        probeLine("MAP", name, ok, details)
    end

    local currentMapID = getCurrentZoneMapID()
    local shownMapID = getShownMapID()

    check("C_Map.GetBestMapForUnit", C_Map and C_Map.GetBestMapForUnit, "current=" .. tostring(currentMapID))
    check("WorldMapFrame.GetMapID", WorldMapFrame and WorldMapFrame.GetMapID, "shown=" .. tostring(shownMapID))
    check("WorldMapFrame.SetMapID", WorldMapFrame and WorldMapFrame.SetMapID, "set-capability")

    if WorldMapFrame and WorldMapFrame.SetMapID and currentMapID then
        local before = getShownMapID()
        WorldMapFrame:SetMapID(currentMapID)
        local after = getShownMapID()
        check("SetMapID-roundtrip", after == currentMapID, "before=" .. tostring(before) .. ",after=" .. tostring(after))
    else
        check("SetMapID-roundtrip", false, "missing SetMapID or current mapID")
    end

    return pass, total
end

local function runCanvasProbe()
    local pass, total = 0, 0
    local function check(name, ok, details)
        total = total + 1
        if ok then pass = pass + 1 end
        probeLine("CANVAS", name, ok, details)
    end

    local W = WorldMapFrame
    local S = W and W.ScrollContainer
    local child = S and S.Child
    local canvasFromFunc = S and S.GetCanvas and S:GetCanvas() or nil
    local canvas = getMapCanvas()

    check("WorldMapFrame", W, "exists=" .. status(W))
    check("ScrollContainer", S, "exists=" .. status(S))
    check("ScrollContainer.Child", child, "exists=" .. status(child))
    check("ScrollContainer.GetCanvas", S and S.GetCanvas, "exists=" .. status(S and S.GetCanvas))
    check("getMapCanvas", canvas, "type=" .. tostring(type(canvas)))

    if canvas and canvas.GetWidth and canvas.GetHeight then
        local w = canvas:GetWidth() or 0
        local h = canvas:GetHeight() or 0
        check("canvas-dimensions", w > 0 and h > 0, string.format("w=%.2f,h=%.2f", w, h))
    else
        check("canvas-dimensions", false, "canvas width/height methods unavailable")
    end

    if child then
        check("canvas-path", true, "path=ScrollContainer.Child")
    elseif canvasFromFunc then
        check("canvas-path", true, "path=ScrollContainer:GetCanvas()")
    elseif canvas then
        check("canvas-path", true, "path=WorldMapFrame fallback")
    else
        check("canvas-path", false, "no canvas path")
    end

    return pass, total
end

local function runMarkerProbe()
    local pass, total = 0, 0
    local function check(name, ok, details)
        total = total + 1
        if ok then pass = pass + 1 end
        probeLine("MARKER", name, ok, details)
    end

    local frame = CreateFrame and CreateFrame("Frame")
    check("CreateFrame", frame, "exists=" .. status(frame))

    local tex = frame and frame.CreateTexture and frame:CreateTexture(nil, "OVERLAY")
    check("CreateTexture", tex, "exists=" .. status(tex))

    check("Texture.SetTexture", tex and tex.SetTexture, "exists=" .. status(tex and tex.SetTexture))
    check("Texture.SetPoint", tex and tex.SetPoint, "exists=" .. status(tex and tex.SetPoint))
    check("Texture.SetSize", tex and tex.SetSize, "exists=" .. status(tex and tex.SetSize))
    check("Texture.SetParent", tex and tex.SetParent, "exists=" .. status(tex and tex.SetParent))
    check("Texture.Show", tex and tex.Show, "exists=" .. status(tex and tex.Show))
    check("Texture.Hide", tex and tex.Hide, "exists=" .. status(tex and tex.Hide))

    if tex and tex.SetTexture then
        tex:SetTexture(PIN_TEXTURES.circle)
        check("Texture.SetTexture-call", true, "texture assigned")
    else
        check("Texture.SetTexture-call", false, "cannot assign texture")
    end

    return pass, total
end

local function runTooltipProbe()
    local pass, total = 0, 0
    local function check(name, ok, details)
        total = total + 1
        if ok then pass = pass + 1 end
        probeLine("TOOLTIP", name, ok, details)
    end

    check("GameTooltip", GameTooltip, "exists=" .. status(GameTooltip))
    check("SetOwner", GameTooltip and GameTooltip.SetOwner, "exists=" .. status(GameTooltip and GameTooltip.SetOwner))
    check("AddLine", GameTooltip and GameTooltip.AddLine, "exists=" .. status(GameTooltip and GameTooltip.AddLine))
    check("Show", GameTooltip and GameTooltip.Show, "exists=" .. status(GameTooltip and GameTooltip.Show))
    check("Hide", GameTooltip and GameTooltip.Hide, "exists=" .. status(GameTooltip and GameTooltip.Hide))

    return pass, total
end

local function getDiagnosticBits()
    local bits = {}
    local W = WorldMapFrame
    local S = W and W.ScrollContainer
    local F = CreateFrame and CreateFrame("Frame")
    local TX = F and F.CreateTexture and F:CreateTexture(nil, "OVERLAY")
    local currentMapID = getCurrentZoneMapID()
    local shownMapID = getShownMapID()
    local canvas = getMapCanvas()

    appendBit(bits, C_Map)
    appendBit(bits, C_Map and C_Map.GetBestMapForUnit)
    appendBit(bits, C_Map and C_Map.SetUserWaypoint)
    appendBit(bits, C_Map and C_Map.ClearUserWaypoint)
    appendBit(bits, UiMapPoint)
    appendBit(bits, CreateVector2D)
    appendBit(bits, W)
    appendBit(bits, W and W.GetMapID)
    appendBit(bits, W and W.SetMapID)
    appendBit(bits, S)
    appendBit(bits, S and S.Child)
    appendBit(bits, S and S.GetCanvas)
    appendBit(bits, CreateFrame)
    appendBit(bits, F and F.CreateTexture)
    appendBit(bits, TX)
    appendBit(bits, TX and TX.SetTexture)
    appendBit(bits, TX and TX.SetAtlas)
    appendBit(bits, TX and TX.SetTexCoord)
    appendBit(bits, TX and TX.SetVertexColor)
    appendBit(bits, TX and TX.SetSize)
    appendBit(bits, TX and TX.SetPoint)
    appendBit(bits, TX and TX.SetParent)
    appendBit(bits, TX and TX.Show)
    appendBit(bits, TX and TX.Hide)
    appendBit(bits, TX and TX.SetDrawLayer)
    appendBit(bits, ToggleWorldMap)
    appendBit(bits, currentMapID)
    appendBit(bits, shownMapID)
    appendBit(bits, canvas)
    appendBit(bits, canvas and canvas.GetWidth and canvas.GetHeight)

    if canvas and canvas.GetWidth and canvas.GetHeight then
        local w = canvas:GetWidth() or 0
        local h = canvas:GetHeight() or 0
        appendBit(bits, w > 0 and h > 0)
    else
        appendBit(bits, false)
    end

    appendBit(bits, GameTooltip)
    appendBit(bits, GameTooltip and GameTooltip.SetOwner)
    appendBit(bits, GameTooltip and GameTooltip.AddLine)
    appendBit(bits, GameTooltip and GameTooltip.Show)
    appendBit(bits, GameTooltip and GameTooltip.Hide)

    return bits, currentMapID, shownMapID
end

local function printDiagnosticShort(prefix)
    local bits, currentMapID, shownMapID = getDiagnosticBits()
    local hex = bitsToHex(bits)

    print(string.format(
        "%s %s %s %s n=%d",
        prefix or "LPB1",
        hex,
        tostring(currentMapID),
        tostring(shownMapID),
        #bits
    ))
end

local function printDiagnosticFull(prefix)
    local bits, currentMapID, shownMapID = getDiagnosticBits()
    local binary = bitsToString(bits)
    local hex = bitsToHex(bits)

    print(string.format(
        "%s|v1|n=%d|b=%s|h=%s|cur=%s|shown=%s",
        prefix or "LPB11508",
        #bits,
        binary,
        hex,
        tostring(currentMapID),
        tostring(shownMapID)
    ))
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

SlashCmdList["LOCDIAG"] = function(msg)
    msg = trim(msg or "")

    if msg == "" or normalizeZone(msg) == "short" then
        printDiagnosticShort("LPB1")
        return
    end

    if normalizeZone(msg) == "binary" or normalizeZone(msg) == "full" then
        printDiagnosticFull("LPB11508")
        return
    end

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

    if normalizeZone(msg) == "verbose" then
        local mapPass, mapTotal = runMapProbe()
        local canvasPass, canvasTotal = runCanvasProbe()
        local markerPass, markerTotal = runMarkerProbe()
        local tooltipPass, tooltipTotal = runTooltipProbe()
        local pass = mapPass + canvasPass + markerPass + tooltipPass
        local total = mapTotal + canvasTotal + markerTotal + tooltipTotal

        print(string.format("LP11508|SUMMARY|diag-verbose|OK|%d/%d checks passed", pass, total))
    end
end

SlashCmdList["LOCPROBE"] = function(msg)
    local which = normalizeZone(msg)
    if which == "" then which = "all" end

    local pass, total = 0, 0

    if which == "map" or which == "all" then
        local p, t = runMapProbe()
        pass = pass + p
        total = total + t
    end

    if which == "canvas" or which == "all" then
        local p, t = runCanvasProbe()
        pass = pass + p
        total = total + t
    end

    if which == "marker" or which == "all" then
        local p, t = runMarkerProbe()
        pass = pass + p
        total = total + t
    end

    if which == "tooltip" or which == "all" then
        local p, t = runTooltipProbe()
        pass = pass + p
        total = total + t
    end

    if total == 0 then
        print("Usage: /locprobe [map|canvas|marker|tooltip|all]")
        return
    end

    print(string.format("LP11508|SUMMARY|locprobe-%s|OK|%d/%d checks passed", which, pass, total))
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnUpdate", function()
    if WorldMapFrame and WorldMapFrame:IsShown() then
        updateMarker()
    end
end)