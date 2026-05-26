# LocPin

Minimal World of Warcraft Classic Era addon for creating quick world map pins via chat commands.

## Commands

- `/loc x,y` — place a pin at coordinates in your current zone.
- `/loc x y` — same as above, space-separated.
- `/loc` — clear the current pin.
- `/locpin Name "Zone Name" x,y pinType "Description"` — place a named pin in a specified zone.
- `/locdiag` — print compact client API diagnostic bits.

## Supported pin types

- `star`
- `circle`
- `diamond`
- `triangle`
- `moon`
- `square`
- `x`
- `skull`
- `quest`
- `turnin`

## Notes

- Uses `C_Map.GetBestMapForUnit("player")` for the current zone.
- Does not rely on `C_Map.SetUserWaypoint` or `C_Map.ClearUserWaypoint`.
- Draws a custom overlay marker on the world map canvas.
- The pin shows a tooltip with name, zone, coordinates, and description when hovered.
