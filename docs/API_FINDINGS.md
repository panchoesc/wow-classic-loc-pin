# LocPin API Compatibility Guide (WoW Classic Era 11508)

This document is intended for LocPin development, debugging, and compatibility
testing. Normal installation and usage instructions live in `README.md`.

Most users do not need this document. Use it when troubleshooting map behavior,
checking Classic Era API compatibility, or sharing diagnostic/probe output.

This document tracks **observed runtime API behavior** for `## Interface: 11508`.

The goal is to avoid assumptions from mixed-era docs and rely on what the client
actually exposes when the addon runs.

## Scope

This guide currently focuses on APIs used by `LocPin`:

- Map resolution and map switching
- World map canvas discovery
- Frame/texture creation for custom markers
- Tooltip APIs used by marker hover

## Observed runtime results

These results were captured in-game on a Classic Era `## Interface: 11508`
client while testing LocPin.

### Short diagnostic capture

With the world map closed:

- `LPB1 C7EFFFFFF 1455 947 n=36`

Decoded summary:

- Current zone map ID resolved: `1455` (`Ironforge` in LocPin's zone table)
- Shown world map ID while closed/unfocused: `947`
- Diagnostic payload length: `36` meaningful bits
- Native waypoint APIs are not available
- Custom marker APIs are available

### Canvas probe capture

`/locprobe canvas` produced:

```text
LP11508|CANVAS|WorldMapFrame|OK|exists=OK
LP11508|CANVAS|ScrollContainer|OK|exists=OK
LP11508|CANVAS|ScrollContainer.Child|OK|exists=OK
LP11508|CANVAS|ScrollContainer.GetCanvas|FAIL|exists=FAIL
LP11508|CANVAS|getMapCanvas|OK|type=table
LP11508|CANVAS|canvas-dimensions|OK|w=1002.00,h=668.00
LP11508|CANVAS|canvas-path|OK|path=ScrollContainer.Child
LP11508|SUMMARY|locprobe-canvas|OK|7 checks passed
```

### Functional marker test

`/loc 50,50` successfully displayed a marker on the map.

This confirms LocPin's custom overlay marker strategy works on the observed
Classic Era 11508 client.

## Probe commands

Run these in-game:

- `/lp diag`
- `/lp diag full`
- `/lp diag legacy`
- `/lp diag verbose`
- `/lp probe map`
- `/lp probe canvas`
- `/lp probe marker`
- `/lp probe tooltip`
- `/lp probe all`
- `/lp status`
- `/lp debug`

Compatibility aliases remain available:

- `/locdiag`
- `/locdiag short`
- `/locdiag full`
- `/locdiag binary`
- `/locdiag legacy`
- `/locdiag verbose`
- `/locprobe map`
- `/locprobe canvas`
- `/locprobe marker`
- `/locprobe tooltip`
- `/locprobe all`

Human-readable LocPin messages use a colored addon prefix. Machine-readable
diagnostic lines such as `LPB1 ...` and `LP11508|...` intentionally remain plain
and stable for copying, screenshots, and comparison.

## Screenshot-friendly binary diagnostic format

`/lp diag` and `/locdiag` print a single short fixed-order hex payload that is
easier to share from a screenshot than many probe lines:

- `LPB1 <hex bits> <currentMapID> <shownMapID> n=36`

Observed example:

- `LPB1 C7EFFFFFF 1455 947 n=36`

Fields:

- `LPB1` identifies the short LocPin binary diagnostic v1 format.
- `<hex bits>` is the diagnostic bitset encoded as uppercase hexadecimal, padded on the right to the next nibble.
- `<currentMapID>` is `C_Map.GetBestMapForUnit("player")` at capture time.
- `<shownMapID>` is `WorldMapFrame:GetMapID()` at capture time.
- `n=36` is the number of meaningful bits in the payload.

`/lp diag short` and `/locdiag short` are aliases for the default short diagnostic.

`/lp diag full` and `/locdiag full` print the full labeled payload:

- `LPB11508|v1|n=36|b=<binary bits>|h=<hex bits>|cur=<mapID>|shown=<mapID>`

Full fields:

- `LPB11508` identifies the LocPin binary diagnostic for interface `11508`.
- `v1` identifies the bit layout version below.
- `n=36` is the number of meaningful bits.
- `b=` is the canonical binary bitset, where `1` means present/pass and `0` means missing/fail.
- `h=` is the same bitset encoded as uppercase hexadecimal, padded on the right to the next nibble.
- `cur=` is `C_Map.GetBestMapForUnit("player")` at capture time.
- `shown=` is `WorldMapFrame:GetMapID()` at capture time.

`/locdiag binary` is an alias for `/locdiag full`.

`/lp diag legacy` and `/locdiag legacy` print the previous `LD:` bit string and current/shown map IDs.

### Binary diagnostic v1 bit layout

| Bit | Meaning |
|-----|---------|
| 1 | `C_Map` exists |
| 2 | `C_Map.GetBestMapForUnit` exists |
| 3 | `C_Map.SetUserWaypoint` exists |
| 4 | `C_Map.ClearUserWaypoint` exists |
| 5 | `UiMapPoint` exists |
| 6 | `CreateVector2D` exists |
| 7 | `WorldMapFrame` exists |
| 8 | `WorldMapFrame.GetMapID` exists |
| 9 | `WorldMapFrame.SetMapID` exists |
| 10 | `WorldMapFrame.ScrollContainer` exists |
| 11 | `WorldMapFrame.ScrollContainer.Child` exists |
| 12 | `WorldMapFrame.ScrollContainer.GetCanvas` exists |
| 13 | `CreateFrame` exists |
| 14 | test frame supports `CreateTexture` |
| 15 | test texture was created |
| 16 | test texture supports `SetTexture` |
| 17 | test texture supports `SetAtlas` |
| 18 | test texture supports `SetTexCoord` |
| 19 | test texture supports `SetVertexColor` |
| 20 | test texture supports `SetSize` |
| 21 | test texture supports `SetPoint` |
| 22 | test texture supports `SetParent` |
| 23 | test texture supports `Show` |
| 24 | test texture supports `Hide` |
| 25 | test texture supports `SetDrawLayer` |
| 26 | `ToggleWorldMap` exists |
| 27 | current zone map ID resolved |
| 28 | shown world map ID resolved |
| 29 | `getMapCanvas()` resolved a canvas |
| 30 | canvas has width/height methods |
| 31 | canvas dimensions are currently non-zero |
| 32 | `GameTooltip` exists |
| 33 | `GameTooltip.SetOwner` exists |
| 34 | `GameTooltip.AddLine` exists |
| 35 | `GameTooltip.Show` exists |
| 36 | `GameTooltip.Hide` exists |

## Stable output format

`/lp diag verbose`, `/lp probe`, `/locdiag verbose`, and `/locprobe` still print detailed stable probe lines:

- `LP11508|GROUP|CHECK|OK|details`
- `LP11508|GROUP|CHECK|FAIL|details`

Summary lines:

- `LP11508|SUMMARY|...|OK|pass/total checks passed`

Verbose probe mode can include return-shape diagnostics for selected API calls,
using compact details such as:

- `returnCount=1,v1=number:1433`
- `error=function missing`

This helps distinguish between APIs that are missing, APIs that error, and APIs
that exist but return an unexpected shape.

## Decoded API availability

The observed `LPB1 C7EFFFFFF 1455 947 n=36` diagnostic indicates the following
API state for the tested client.

### Available APIs / capabilities

These are present and usable for LocPin's current implementation:

- `C_Map`
- `C_Map.GetBestMapForUnit("player")`
- `CreateVector2D`
- `WorldMapFrame`
- `WorldMapFrame:GetMapID()`
- `WorldMapFrame:SetMapID(mapID)`
- `WorldMapFrame.ScrollContainer`
- `WorldMapFrame.ScrollContainer.Child`
- `CreateFrame`
- `Frame:CreateTexture(...)`
- Texture object creation
- Texture methods:
  - `SetTexture`
  - `SetAtlas`
  - `SetTexCoord`
  - `SetVertexColor`
  - `SetSize`
  - `SetPoint`
  - `SetParent`
  - `Show`
  - `Hide`
  - `SetDrawLayer`
- `ToggleWorldMap`
- Current zone map ID resolution
- Shown world map ID resolution
- `getMapCanvas()` resolution through LocPin's fallback wrapper
- Canvas width/height methods
- Non-zero canvas dimensions during probe
- `GameTooltip`
- Tooltip methods:
  - `SetOwner`
  - `AddLine`
  - `Show`
  - `Hide`

### Missing APIs / capabilities

These are not available in the observed Classic Era 11508 client:

- `C_Map.SetUserWaypoint`
- `C_Map.ClearUserWaypoint`
- `UiMapPoint`
- `WorldMapFrame.ScrollContainer:GetCanvas()`

The missing waypoint APIs mean LocPin cannot rely on Blizzard's native user
waypoint flow on this client. The add-on must continue to draw its own map
marker with frames/textures.

The missing `ScrollContainer:GetCanvas()` method means the expected canvas path
for this client is `WorldMapFrame.ScrollContainer.Child`.

## Method explanations and LocPin usage

### `C_Map.GetBestMapForUnit("player")`

Used by LocPin to determine the player's current zone map ID. This powers the
simple command:

```text
/loc 50,50
```

When this API returns a map ID, LocPin can place the pin in the current zone
without requiring the user to type a zone name.

Observed status: **OK**.

### `C_Map.SetUserWaypoint`, `C_Map.ClearUserWaypoint`, and `UiMapPoint`

These APIs would normally support Blizzard-style native waypoints in newer or
other-era clients. They are absent in the observed Classic Era 11508 runtime.

Observed status: **FAIL / unavailable**.

Implementation implication:

- Do not build LocPin around native user waypoints for this interface.
- Keep the custom overlay marker implementation.

### `WorldMapFrame:GetMapID()`

Used to inspect which map the world map is currently showing. This allows LocPin
to detect whether the visible map differs from the pinned map.

Observed status: **OK**.

### `WorldMapFrame:SetMapID(mapID)`

Used to switch the world map to the map that contains the active pin. This is
important for `/locpin`, where a command can target a specific supported zone.

Observed status: **OK**.

Implementation implication:

- LocPin can open/switch the world map to the pinned zone before drawing the
  marker.
- Map switching should be a one-time action when a pin is created. LocPin should
  not repeatedly force `SetMapID` while a pin is active, because that prevents
  normal map browsing.

### `ToggleWorldMap`

Used by LocPin to open the world map if it is not currently visible.

Observed status: **OK**.

### `WorldMapFrame.ScrollContainer`

The parent scroll/container object for the world map canvas.

Observed status: **OK**.

### `WorldMapFrame.ScrollContainer.Child`

The confirmed drawable map canvas path on the observed Classic Era 11508 client.
LocPin can parent the marker frame to this object and position it using canvas
width/height.

Observed status: **OK**.

Observed dimensions during canvas probe:

- Width: `1002.00`
- Height: `668.00`

Implementation implication:

- This should be the primary canvas path for interface `11508`.
- Coordinate conversion should continue to use:

```lua
xPixels = normalizedX * canvas:GetWidth()
yPixels = normalizedY * canvas:GetHeight()
```

with the marker anchored relative to the canvas top-left.

### `WorldMapFrame.ScrollContainer:GetCanvas()`

An alternate canvas accessor seen in some UI code or client eras. It is not
available in the observed Classic Era 11508 runtime.

Observed status: **FAIL / unavailable**.

Implementation implication:

- Keep it only as a fallback for other builds.
- Do not treat it as the expected path for this client.

### `CreateFrame`

Used to create LocPin's custom marker frame and the diagnostic probe frames.

Observed status: **OK**.

### `Frame:CreateTexture(...)` and texture methods

Used to draw the visible marker icon. LocPin currently uses built-in raid target
and quest textures, then sizes/positions the texture inside the marker frame.

Observed status: **OK** for texture creation and required texture methods.

Implementation implication:

- Custom map marker rendering is supported.
- The marker can be shown/hidden, sized, parented, positioned, and assigned a
  texture.

### `GameTooltip` and tooltip methods

Used to show pin details when hovering the marker:

- Name
- Zone
- Coordinates
- Description

Observed status: **OK**.

Implementation implication:

- Hover text is supported for custom markers.

## Compatibility matrix

| Group   | Check                     | Status | Details |
|---------|---------------------------|--------|---------|
| MAP     | C_Map.GetBestMapForUnit   | OK     | Confirmed by `LPB1`; observed `cur=1455` |
| MAP     | WorldMapFrame.GetMapID    | OK     | Confirmed by `LPB1`; observed `shown=947` while map closed |
| MAP     | WorldMapFrame.SetMapID    | OK     | Confirmed by `LPB1` |
| MAP     | SetMapID-roundtrip        | TBD    | Run `/locprobe map` if roundtrip detail is needed |
| CANVAS  | WorldMapFrame             | OK     | `exists=OK` |
| CANVAS  | ScrollContainer           | OK     | `exists=OK` |
| CANVAS  | ScrollContainer.Child     | OK     | Confirmed primary canvas path |
| CANVAS  | ScrollContainer.GetCanvas | FAIL   | `exists=FAIL` |
| CANVAS  | getMapCanvas              | OK     | `type=table` |
| CANVAS  | canvas-dimensions         | OK     | `w=1002.00,h=668.00` |
| CANVAS  | canvas-path               | OK     | `path=ScrollContainer.Child` |
| MARKER  | CreateFrame               | OK     | Confirmed by `LPB1` |
| MARKER  | CreateTexture             | OK     | Confirmed by `LPB1` |
| MARKER  | Texture.SetTexture        | OK     | Confirmed by `LPB1` |
| MARKER  | Texture.SetPoint          | OK     | Confirmed by `LPB1` |
| MARKER  | Texture.SetSize           | OK     | Confirmed by `LPB1` |
| MARKER  | Texture.SetParent         | OK     | Confirmed by `LPB1` |
| MARKER  | Texture.Show              | OK     | Confirmed by `LPB1` |
| MARKER  | Texture.Hide              | OK     | Confirmed by `LPB1` |
| MARKER  | Texture.SetTexture-call   | OK     | Functional marker test passed with `/loc 50,50` |
| TOOLTIP | GameTooltip               | OK     | Confirmed by `LPB1` |
| TOOLTIP | SetOwner                  | OK     | Confirmed by `LPB1` |
| TOOLTIP | AddLine                   | OK     | Confirmed by `LPB1` |
| TOOLTIP | Show                      | OK     | Confirmed by `LPB1` |
| TOOLTIP | Hide                      | OK     | Confirmed by `LPB1` |

## Implementation conclusion

For the observed Classic Era 11508 client, LocPin should continue using a custom
world-map overlay marker rather than native user waypoints.

The supported implementation path is:

1. Resolve the current map with `C_Map.GetBestMapForUnit("player")`.
2. Open the map with `ToggleWorldMap` when needed.
3. Switch maps with `WorldMapFrame:SetMapID(mapID)` when targeting a specific
   zone. This should happen when the pin is created, not continuously while the
   pin remains active.
4. Resolve the drawable map canvas through `WorldMapFrame.ScrollContainer.Child`.
5. Create a marker frame with `CreateFrame`.
6. Create and assign a marker texture with `Frame:CreateTexture` and
   `Texture:SetTexture`.
7. Convert normalized coordinates to canvas pixels using `GetWidth()` and
   `GetHeight()`.
8. Show hover details using `GameTooltip`

When the user browses to a different map, LocPin should hide the active marker
instead of snapping the world map back to the pinned map. The marker can reappear
when the pinned map is shown again.

LocPin's public command API should prefer the consolidated `/lp` root command:

1. `/lp here <x,y>` for current-zone pins.
2. `/lp pin <name> <zone> <x,y> [type] [description]` for rich pins.
3. `/lp clear` to clear the active pin.
4. `/lp show` to explicitly jump back to the pinned map.
5. `/lp status` and `/lp debug` for human-readable troubleshooting.
6. `/lp diag ...` and `/lp probe ...` for machine-readable compatibility checks.

Older commands such as `/loc`, `/locpin`, `/locdiag`, and `/locprobe` remain as
compatibility aliases.

The unavailable waypoint APIs should be treated as unsupported for this client.
Any future implementation that tries to use native waypoints must first prove
availability through `/locdiag` or `/locprobe` on the target interface version.

## Known fallback strategy in LocPin

`getMapCanvas()` fallback order:

1. `WorldMapFrame.ScrollContainer.Child`
2. `WorldMapFrame.ScrollContainer:GetCanvas()`
3. `WorldMapFrame`

This fallback chain is intentional and should be preserved unless probes show a
clear better path for Classic Era 11508.

## Workflow after a game update

1. Confirm `## Interface` in `LocPin.toc`.
2. Run `/locdiag` and save the screenshot-friendly `LPB1` line.
3. If any bit changed or more detail is needed, run `/locprobe all`.
4. Compare output with previous saved results.
5. Update this matrix and note regressions.
6. Adjust wrappers/fallbacks before adding new features.