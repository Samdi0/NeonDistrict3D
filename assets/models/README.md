# 3D model asset slots — NEON DISTRICT 3D

This project now supports imported glTF 2.0 / GLB scenes. Put the licensed files in this folder with these exact names:

| File | Used by | Required content |
|---|---|---|
| `player.glb` | Player | Humanoid skinned mesh, skeleton, materials and an AnimationPlayer |
| `npc.glb` | Pedestrians, hostile NPCs and police | Humanoid skinned mesh, skeleton, materials and an AnimationPlayer |
| `car.glb` | Drivable vehicles | Vehicle body, wheels and materials |

If a file is absent, the game keeps its procedural fallback. Character collisions are separate Godot physics shapes and remain active when a GLB is loaded. Imported mesh geometry is visual; it does not automatically become a physics collider.

## Animation clip names

The scripts look for the first matching clip name in the imported AnimationPlayer:

- Idle: `Idle` or `idle`
- Walking: `Walk`, `walk`, `Jog`, `jog`
- Running: `Run`, `run`, `Jog`, `jog`
- Shooting: `Shoot`, `shoot`, `Rifle_Aim_Shoot`, `Pistol_Shoot`
- Melee: `Punch`, `punch`, `Melee`, `Attack`

The animation library in an imported character must already be compatible with that character's skeleton. Godot will not automatically retarget an unrelated rig just because the clip has a similar name.

## Asset sources and licensing

Good starting point for a stylized, game-ready CC0 pipeline:

- Quaternius Universal Base Characters: https://quaternius.com/packs/universalbasecharacters.html
- Quaternius Universal Animation Library: https://quaternius.com/packs/universalanimationlibrary.html
- Quaternius Downtown City MegaKit: https://quaternius.com/packs/downtowncitymegakit.html
- Quaternius Cars Pack: https://quaternius.com/packs/cars.html

Check the current license on each pack page before shipping. Quaternius assets are stylized/low-poly, not photorealistic GTA V assets. They are suitable for a coherent indie-game art style, not a claim of GTA V fidelity.

## 2K PBR texture requirements

For the intended high-quality asset pass, use 2048x2048 maps where available:
- Base Color / Albedo
- Normal (OpenGL convention for Godot)
- Roughness
- Metallic (where appropriate)
- Ambient Occlusion

Use glTF PBR materials and embed textures in GLB for a self-contained asset. Keep Web/mobile texture variants at 1K or lower to control download size and memory.

## Current status

The GLB loading hooks and animation state selection are implemented. The actual third-party GLB files are **not bundled yet**: this repository currently contains no downloaded character, vehicle or city asset pack. Until the files above are added, procedural visuals remain visible. No claim of 2K textures, fully rigged animation, or GTA V-level realism should be made until those files are installed and tested in Godot.
