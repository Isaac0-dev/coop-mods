# Mods
This is an archive of mods for sm64ex-coop by Isaac0-dev.
Check branches for mods or romhack ports that may not be listed here.

### Collision Minimap
This is an experimental mod that draws on screen a minimap in the top right corner, showing a map that's automatically generated based off collision it finds in the level. The map is oriented the same direction as the camera.
Inspired by Zelda botw, I've added an arrow in the center of the map to represent your player. You can also see other players on your map (please don't use in hns), and if you have OMM Rebirth enabled, you can see cappy on the map as well.

Explanation: The primary method used of finding collision is through ray casts, however it won't do any ray casting unless Mario stands on a surface that is not already in the collision map; if this happens, it will trigger a chain reaction of ray casts to find more surfaces. It stores surfaces it finds in a Lua table, and then renders each surface on screen.. Or rather the outline of the surface triangle using very thin rectangles.
