# Super Speed (Cyberpunk 2077 mod)

Press a key and everything around V slows down while V keeps full speed, and V
also runs faster. With the default settings V moves about **10x faster than
everyone else**.

It combines two effects, and each one can be switched off:

| Effect | What it does | Default |
| --- | --- | --- |
| Slow world | Everything except V runs slower (the same system the Sandevistan uses) | 20% speed |
| Fast legs | V's top running speed and acceleration are multiplied | 2x |

## Easy install (Steam on Windows)

1. Download [`Install-SuperSpeed.bat`](Install-SuperSpeed.bat) and double-click it.
   If Windows says "Windows protected your PC", click **More info → Run anyway**.
2. It finds your game, offers to install the two modding tools the mod needs
   (RED4ext and Cyber Engine Tweaks) from their official GitHub pages, and
   adds the mod. Close the game before running it.
3. Start the game and follow the "Next" steps it prints: pick a CET overlay
   key, then set your Super Speed keys under **Bindings**.

If it can't find the game, it asks you to paste the game folder path.

## What you need (manual install)

- Cyberpunk 2077 on PC (Steam, GOG or Epic)
- **RED4ext**, from [GitHub releases](https://github.com/WopsS/RED4ext/releases).
  Cyber Engine Tweaks needs it.
- **Cyber Engine Tweaks (CET)**, from [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/107) or
  [GitHub releases](https://github.com/maximegmd/CyberEngineTweaks/releases).
  Its version must match your game version.

## Manual install

1. **Install RED4ext, then CET**, if you don't have them. Unzip each one into
   your game folder (in Steam: right-click Cyberpunk 2077 → Manage → Browse
   local files). Start the game once; CET asks you to choose a key for its overlay.
2. **Get this mod.** Download
   [this branch as a ZIP](https://github.com/bjtmm/dayssince/archive/refs/heads/claude/cyberpunk-speed-mod-b0znjq.zip)
   and unzip it.
3. **Copy the `bin` folder** from inside `cyberpunk-super-speed` into the game
   folder. Say yes when Windows asks to merge folders. The mod ends up at:
   `Cyberpunk 2077\bin\x64\plugins\cyber_engine_tweaks\mods\SuperSpeed\init.lua`
4. **Set your keys.** Start the game, open the CET overlay, go to
   **Bindings**, and set one or both:
   - **Toggle super speed**: press once for on, again for off
   - **Hold for super speed**: on only while the key is held down
5. Load a save and press your key.

## Settings window

While the CET overlay is open, a **Super Speed** window appears with:

- On/off button
- **Slow world** on/off and **World speed** slider (0.05 = nearly frozen, 1.0 = normal)
- **Fast legs** on/off and **Run speed** slider (1x to 5x)
- **Normal world speed while driving**: cars are part of the world, so with
  slow world on they would crawl. This pauses slow world while you're in a vehicle.
- **Top speed stat** line: shows whether the run speed boost is reaching V

Slider changes last until you quit the game. To change the starting values,
edit the `settings` block at the top of `init.lua`.

## Things to know

- **No Sandevistan visuals yet.** The slow-down works the same way, but the
  colour filter and afterimage trails are separate effects that this mod
  doesn't add yet.
- **Bullets and thrown things slow down** once they leave V's hands, because
  they become part of the world. Your shots hang in the air and then fly when
  you switch it off.
- **Turn it off for cutscenes and conversations**, which aren't made to run in
  slow motion.
- Turning it off undoes everything. Uninstall by deleting the `SuperSpeed` folder.

## If something doesn't work

Open the CET overlay → **Console** and look for lines starting with
`[SuperSpeed]`. Send those, plus the **Top speed stat** line from the window,
and we can fix it from there.
