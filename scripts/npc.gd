extends CharacterBody3D

var health := 100
var is_hostile := false
var is_police := false
var wander_dir := Vector3.ZERO
var change_timer := 0.0
var attack_timer := 0.0

func _ready() -> void:
    add_to_group("people")
    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.32
    capsule.height = 1.55
    mesh.mesh = capsule
    mesh.position.y = 0.78
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.05, 0.25, 1.0) if is_police else (Color(0.85, 0.12, 0.38) if is_hostile else Color(0.7, 0.75, 0.85))
    mesh.material_override = mat
    add_child(mesh)
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.32
    shape.height = 1.55
    col.shape = shape
    col.position.y = 0.78
    add_child(col)
    _choose_direction()

func _physics_process(delta: float) -> void:
    change_timer -= delta
    attack_timer -= delta
    if change_timer <= 0.0:
        _choose_direction()
    if is_hostile:
        var player := get_tree().get_first_node_in_group("player")
        if player and global_position.distance_to(player.global_position) < (28.0 if is_police else 16.0):
            wander_dir = (player.global_position - global_position).normalized()
            if attack_timer <= 0.0:
                player.set("health", max(0, int(player.get("health")) - (5 if is_police else 3)))
                attack_timer = 1.0
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
