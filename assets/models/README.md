# NEON DISTRICT 3D — Character asset import

## Copyright-safe character direction

Do **not** copy, rip, extract, convert, or redistribute GTA V / Rockstar pedestrian models, protagonist models, textures, voices, logos, or animations. The GTA V NPC roster and its specific models are Rockstar copyrighted game assets. This project instead uses original character identities and independently licensed assets with a distinct visual design.

The current code supports up to 52 character variants per role using these optional paths:

- `res://assets/models/npcs/civilian_01.glb` … `civilian_52.glb`
- `res://assets/models/npcs/hostile_01.glb` … `hostile_52.glb`
- `res://assets/models/npcs/police_01.glb` … `police_52.glb`

Each GLB should include a textured skinned humanoid, skeleton and AnimationPlayer. Keep the existing Godot CharacterBody3D and capsule collider as the gameplay root; the GLB is visual-only. The loader falls back to `assets/models/npc.glb`, then to procedural visuals if a role variant is absent.

## Candidate legal source

Quaternius Ultimate Animated Character Pack lists 52 animated, textured characters in FBX, OBJ and Blend formats and marks the pack CC0 on its pack page:
https://quaternius.com/packs/ultimatedanimatedcharacter.html

Important: the listed download formats are FBX/OBJ/Blend, not GLB. Convert the selected FBX/Blend characters to GLB in Blender or import FBX into Godot and validate materials, skeletons and animation clips. Keep the pack's included license file and a dated copy of the source page with the project. Confirm the license attached to the exact downloaded version before commercial release.

For locomotion and combat clips, Quaternius Universal Animation Library offers 120+ retarget-friendly humanoid animations for Godot:
https://quaternius.itch.io/universal-animation-library

## Animation naming

Character clips should use one of the names the runtime searches:
- Idle: `Idle` / `idle`
- Walk: `Walk` / `walk`
- Run: `Run` / `run` / `Jog` / `jog`
- Shoot: `Shoot` / `shoot` / `Rifle_Aim_Shoot` / `Pistol_Shoot`

Animation clips must be authored for, or correctly retargeted to, the exact imported skeleton. Merely renaming an incompatible animation does not retarget it.

## Current implementation status

The runtime loader and 52-slot role-specific naming convention are implemented. The actual character pack archives and converted GLB assets are **not included in this repository yet**. Therefore the game will still use fallback procedural models until the files are downloaded, converted, checked in, and tested in Godot. No claim is made that GTA V NPC models have been imported.
