extends CharacterBody3D

var health := 100
var is_hostile := false
var is_police := false
var wander_dir := Vector3.ZERO
var change_timer := 0.0
var attack_timer := 0.0
var visual_root: Node3D
var visual_animation: AnimationPlayer
var archetype_id := 1
var visual_model_path := ""

func _ready() -> void:
    add_to_group("people")
    visual_root = Node3D.new()
    visual_root.name = "CharacterVisual"
    add_child(visual_root)
    var role := "police" if is_police else ("hostile" if is_hostile else "civilian")
    var variant := clampi(archetype_id, 1, 52)
    visual_model_path = "res://assets/models/npcs/%s_%02d.glb" % [role, variant]
    if not ResourceLoader.exists(visual_model_path):
        visual_model_path = "res://assets/models/npc.glb"
    if ResourceLoader.exists(visual_model_path):
        var packed := load(visual_model_path) as PackedScene
        if packed:
            var imported := packed.instantiate()
            visual_root.add_child(imported)
            visual_animation = _find_animation_player(imported)
            # Keep the imported render model aligned to the existing capsule collider.
            imported.position = Vector3.ZERO
            _play_visual_animation(["Idle", "idle"])
    else:
        var outfit_color := Color(0.035, 0.12, 0.55) if is_police else (Color(0.72, 0.08, 0.19) if is_hostile else [Color(0.08, 0.42, 0.5), Color(0.48, 0.22, 0.62), Color(0.72, 0.42, 0.12), Color(0.16, 0.42, 0.25)].pick_random())
        var skin := _npc_material(Color(0.68, 0.45, 0.32))
        var outfit := _npc_material(outfit_color, is_police or is_hostile)
        var trousers := _npc_material(Color(0.035, 0.045, 0.085))
        _npc_part(CapsuleMesh.new(), Vector3(0, 1.0, 0), Vector3(0.72, 0.8, 0.42), outfit)
        _npc_part(SphereMesh.new(), Vector3(0, 1.62, 0), Vector3(0.44, 0.48, 0.42), skin)
        _npc_part(CapsuleMesh.new(), Vector3(-0.2, 0.42, 0), Vector3(0.22, 0.65, 0.23), trousers)
        _npc_part(CapsuleMesh.new(), Vector3(0.2, 0.42, 0), Vector3(0.22, 0.65, 0.23), trousers)
        _npc_part(CapsuleMesh.new(), Vector3(-0.43, 1.0, 0), Vector3(0.18, 0.62, 0.18), outfit)
        _npc_part(CapsuleMesh.new(), Vector3(0.43, 1.0, 0), Vector3(0.18, 0.62, 0.18), outfit)
        if is_police:
            _npc_part(BoxMesh.new(), Vector3(0, 1.9, 0), Vector3(0.5, 0.12, 0.48), _npc_material(Color(0.04, 0.18, 0.95), true))
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.32
    shape.height = 1.55
    col.shape = shape
    col.position.y = 0.78
    add_child(col)
    _choose_direction()

func _find_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer:
        return root
    for child in root.get_children():
        var found := _find_animation_player(child)
        if found:
            return found
    return null

func _play_visual_animation(candidates: Array[String]) -> void:
    if not visual_animation:
        return
    for candidate in candidates:
        if visual_animation.has_animation(candidate):
            if visual_animation.current_animation != candidate:
                visual_animation.play(candidate)
            return

func _npc_material(color: Color, glow := false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.7
    if glow:
        material.emission_enabled = true
        material.emission = color * 0.25
    return material

func _npc_part(mesh_resource: PrimitiveMesh, part_position: Vector3, part_scale: Vector3, material: Material) -> void:
    var part := MeshInstance3D.new()
    part.mesh = mesh_resource
    part.position = part_position
    part.scale = part_scale
    part.material_override = material
    visual_root.add_child(part)

func _physics_process(delta: float) -> void:
    change_timer -= delta
    attack_timer -= delta
    if change_timer <= 0.0:
        _choose_direction()
    if is_hostile:
        var player := get_tree().get_first_node_in_group("player")
        if player and global_position.distance_to(player.global_position) < (28.0 if is_police else 16.0):
            wander_dir = (player.global_position - global_position).normalized()
            if attack_timer <= 0.0 and global_position.distance_to(player.global_position) < 1.8:
                player.set("health", max(0, int(player.get("health")) - (5 if is_police else 3)))
                attack_timer = 1.0
    if wander_dir.length() > 0.1:
        visual_root.rotation.y = atan2(wander_dir.x, wander_dir.z)
        _play_visual_animation(["Run", "run", "Jog", "jog"] if is_hostile else ["Walk", "walk", "Jog", "jog"])
    else:
        _play_visual_animation(["Idle", "idle"])
    velocity.x = wander_dir.x * (2.8 if is_hostile else 1.5)
    velocity.z = wander_dir.z * (2.8 if is_hostile else 1.5)
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    else:
        velocity.y = -0.2
    move_and_slide()

func _choose_direction() -> void:
    change_timer = randf_range(1.5, 4.0)
    wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        var world := get_tree().current_scene
        if world.has_method("award"):
            world.call("award", 50 if is_police else 25)
        if world.has_method("add_crime"):
            world.call("add_crime", 1)
        if world.has_method("on_npc_removed"):
            world.call("on_npc_removed", is_police)
        queue_free()
