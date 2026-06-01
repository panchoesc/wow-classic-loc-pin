# LocPin

Minimal World of Warcraft Classic Era addon for creating quick world map pins via chat commands.

## Installation

LocPin must be installed as a WoW addon folder named `LocPin`.

### 1. Download the addon

Download this repository from GitHub, either by cloning it or using **Code → Download ZIP**.

If you downloaded a ZIP, unzip it first.

### 2. Create the addon folder

Create or copy the addon into a folder named:

```text
LocPin
```

The important part is that these files are directly inside the `LocPin` folder:

```text
LocPin/LocPin.toc
LocPin/LocPin.lua
```

Do **not** leave the files nested like this:

```text
LocPin/wow-classic-loc-pin/LocPin.toc
```

### 3. Copy `LocPin` into your AddOns directory

macOS Classic Era path:

```text
/Applications/World of Warcraft/_classic_era_/Interface/AddOns/LocPin
```

Windows Classic Era path:

```text
C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\LocPin
```

Final layout should look like:

```text
Interface/AddOns/LocPin/LocPin.toc
Interface/AddOns/LocPin/LocPin.lua
```

### 4. Restart or reload WoW

Start WoW Classic Era, or run this in chat if the game is already open:

```text
/reload
```

Then confirm **LocPin** is enabled in the AddOns list.

## Commands

### Quick pins

Add a pin in your current zone:

```text
/loc 50,50
```

Run the command again to add more pins in the current zone. Quick pins are named
`Pin 1`, `Pin 2`, and so on.

Clear all session pins:

```text
/loc
```

### Main command

Show help:

```text
/lp help
```

Add a pin in your current zone:

```text
/lp here 50,50
```

Add a named pin in a specific zone:

```text
/lp pin "Keeshan" "Redridge Mountains" 28.5,12.1 quest "Missing In Action"
```

List session pins:

```text
/lp list
```

Jump back to the latest active pin's map:

```text
/lp show
```

Jump to a specific pin's map by ID or name:

```text
/lp show 2
/lp show "Keeshan"
```

Remove one pin by ID or name:

```text
/lp remove 2
/lp remove "Keeshan"
```

Clear all session pins:

```text
/lp clear
```

Show zone/alias examples:

```text
/lp zones
```

## Examples

```text
/lp pin "STV Camp" stv 35,45 skull "Camp location"
/lp pin "Ironforge Bank" ironforge 35,60 square "Bank/AH area"
/lp pin "Un'Goro Route" ungoro 44,66 diamond "Route marker"
/lp list
/lp show 2
/lp remove 2
```

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

- Uses `C_Map.GetBestMapForUnit("player")` for current-zone pins.
- Pins are session-only and do not persist through `/reload` or logout.
- Supports Classic Era outdoor zones and capital cities by name.
- Common aliases include `stv`, `wpl`, `epl`, `org`, `tb`, `uc`, and `ungoro`.
- Draws a custom overlay marker on the world map canvas.
- Each marker shows a tooltip with ID, name, zone, coordinates, and description when hovered.
- Browsing to another map will hide pins from other maps instead of locking your map view.
