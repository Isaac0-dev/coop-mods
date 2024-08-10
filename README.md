# Mods
This is an archive of mods for sm64ex-coop by Isaac0-dev.
Check branches for mods or romhack ports that may not be listed here.

### Collision Minimap
This is an experimental mod that draws on screen a minimap in the top right corner, showing a map that's automatically generated based off collision it finds in the level. The map is oriented the same direction as the camera.
Inspired by Zelda botw, I've added an arrow in the center of the map to represent your player. You can also see other players on your map (please don't use in hns), and if you have OMM Rebirth enabled, you can see cappy on the map as well.

Explanation: The primary method used of finding collision is through ray casts, however it won't do any ray casting unless Mario stands on a surface that is not already in the collision map; if this happens, it will trigger a chain reaction of ray casts to find more surfaces. It stores surfaces it finds in a Lua table, and then renders each surface on screen.. Or rather the outline of the surface triangle using very thin rectangles.

### LiveSplit64
This is a simple coop mod that I made in an attempt to make a LiveSplit clone. For those who don't know: "LiveSplit is a timer program for speedrunners that is both easy to use and full of features." - https://livesplit.org/
I made this because I had the idea to be able to see each other's splits on the same LiveSplit window.
This coop mod syncs with each player, so you can see when someone splits in real time.
It comes built in with an autosplitter, so hopefully no need to split manually at the moment.
To open a simple menu, press D-pad up and C-up at the same time. On this menu, you can move the timer around to where you want. There are a few buttons, allowing you to start/stop and reset the timer, and edit splits.
Splits are saved thanks to mod storage on the host's machine only, but splits are synced when players join.
I'd love some feedback on this mod! This was just something I decided to make as a fun challenge, so it's not exactly overflowing with features at the moment.
I hope this mod is useful!
