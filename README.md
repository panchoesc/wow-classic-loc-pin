# LocPin

Minimal World of Warcraft Classic Era addon for creating quick world map pins via chat commands.

## Commands

- `/loc x,y` — place a pin at coordinates in your current zone.
- `/loc x y` — same as above, space-separated.
- `/loc` — clear the current pin.
- `/locpin Name "Zone Name" x,y pinType "Description"` — place a named pin in a specified zone.
- `/locdiag` — print one short binary-encoded client API diagnostic line for screenshots.
- `/locdiag short` — same as `/locdiag`.
- `/locdiag full` — print the full labeled binary diagnostic line.
- `/locdiag binary` — same as `/locdiag full`.
- `/locdiag legacy` — print the older compact `LD:` bit string plus current/shown map IDs.
- `/locdiag verbose` — run expanded grouped diagnostics and summary for interface 11508 assumptions.
- `/locprobe [map|canvas|marker|tooltip|all]` — run deterministic API probes and print stable structured lines.

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
- `/locpin` supports Classic Era outdoor zones and capital cities by name, plus common aliases such as `stv`, `wpl`, `epl`, `org`, `tb`, and `uc`.
- Does not rely on `C_Map.SetUserWaypoint` or `C_Map.ClearUserWaypoint`.
- Draws a custom overlay marker on the world map canvas.
- The pin shows a tooltip with name, zone, coordinates, and description when hovered.

## API diagnostics output format (11508)

Screenshot-friendly diagnostic output uses one short line:

- `LPB1 <hex bits> <currentMapID> <shownMapID> n=36`

Example:

- `LPB1 C7EFFFFFF 1455 947 n=36`

The full labeled diagnostic output is available with `/locdiag full`:

- `LPB11508|v1|n=36|b=<binary bits>|h=<hex bits>|cur=<mapID>|shown=<mapID>`

The hex value is the same bitset as the full `b=` binary payload, encoded in uppercase hex for easier transcription.

Use `/locdiag legacy` if you need the previous `LD:` output format.

Verbose probe lines:

- `LP11508|GROUP|CHECK|OK|details`
- `LP11508|GROUP|CHECK|FAIL|details`

Groups currently include:

- `MAP`
- `CANVAS`
- `MARKER`
- `TOOLTIP`
- `SUMMARY`

See `docs/API-11508.md` for the compatibility workflow.
