extends CharacterBody3D

var health := 100
var ammo := 90
var speed := 7.0
var mouse_sensitivity := 0.0025
var camera_pivot: Node3D
var camera: Camera3D
var body_mesh: Node3D
var visual_animation: AnimationPlayer
var current_car: Variant
var main_world: Variant
var attack_cooldown := 0.0
var first_person := false
var save_path := "user://neon_district_save.cfg"

func _ready() -> void:
    add_to_group("player")
    _setup_input()
    _make_player()
    _make_camera()

func _setup_input() -> void:
    var binds := {
        "move_forward": KEY_W,
        "move_back": KEY_S,
        "move_left": KEY_A,
        "move_right": KEY_D,
        "jump": KEY_SPACE
    }
    for action in binds:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var key_event := InputEventKey.new()
        key_event.physical_keycode = binds[action]
        InputMap.action_add_event(action, key_event)

func _make_player() -> void:
    body_mesh = Node3D.new()
    body_mesh.name = "CharacterVisual"
    add_child(body_mesh)
    var model_path := "res://assets/models/player.glb"
    if ResourceLoader.exists(model_path):
        var packed := load(model_path) as PackedScene
        if packed:
            var imported := packed.instantiate()
            body_mesh.add_child(imported)
            visual_animation = _find_animation_player(imported)
            _play_visual_animation(["Idle", "idle"])
            return
    var torso_mat := _character_material(Color(0.025, 0.48, 0.62), true)
    var pants_mat := _character_material(Color(0.025, 0.035, 0.09))
    var skin_mat := _character_material(Color(0.72, 0.48, 0.34))
    _add_character_part(CapsuleMesh.new(), Vector3(0, 1.15, 0), Vector3(0.72, 0.85, 0.42), torso_mat)
    _add_character_part(SphereMesh.new(), Vector3(0, 1.78, 0), Vector3(0.48, 0.52, 0.46), skin_mat)
    _add_character_part(CapsuleMesh.new(), Vector3(-0.22, 0.48, 0), Vector3(0.22, 0.72, 0.24), pants_mat)
    _add_character_part(CapsuleMesh.new(), Vector3(0.22, 0.48, 0), Vector3(0.22, 0.72, 0.24), pants_mat)
    _add_character_part(CapsuleMesh.new(), Vector3(-0.48, 1.15, 0), Vector3(0.2, 0.68, 0.2), torso_mat)
    _add_character_part(CapsuleMesh.new(), Vector3(0.48, 1.15, 0), Vector3(0.2, 0.68, 0.2), torso_mat)
    _add_character_part(BoxMesh.new(), Vector3(0, 0.12, -0.08), Vector3(0.75, 0.2, 0.95), pants_mat)

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

func _character_material(color: Color, glow := false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.62
    if glow:
        material.emission_enabled = true
        material.emission = color * 0.35
    return material

func _add_character_part(mesh_resource: PrimitiveMesh, part_position: Vector3, part_scale: Vector3, material: Material) -> void:
    var part := MeshInstance3D.new()
    part.mesh = mesh_resource
    part.position = part_position
    part.scale = part_scale
    part.material_override = material
    body_mesh.add_child(part)

func _make_camera() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.position.y = 1.55
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0, 1.0, 5.8)
    camera.rotation.x = deg_to_rad(-10)
    camera.current = true
    camera_pivot.add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
    if main_world and not main_world.game_started:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-55), deg_to_rad(30))
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        elif event.keycode == KEY_E:
            if current_car:
                var car := current_car
                current_car = null
                car.set("occupied", false)
                global_position += car.global_basis.x * 2.0
                body_mesh.visible = true
            else:
                _try_enter_car()
                if current_car == null and main_world:
                    main_world.interact_with_world()
        elif event.keycode == KEY_I:
            if main_world and main_world.has_method("_notify"):
                main_world._notify("Инвентарь: аптечки %d | патроны %d | кредиты %d" % [int(main_world.inventory.get("Аптечка", 0)), ammo, main_world.credits])
        elif event.keycode == KEY_H:
            if main_world and int(main_world.inventory.get("Аптечка", 0)) > 0 and health < 100:
                main_world.inventory["Аптечка"] -= 1
                health = mini(100, health + 50)
                main_world._notify("Аптечка использована: +50 HP")
        elif event.keycode == KEY_F:
            _punch()
        elif event.keycode == KEY_V:
            _toggle_camera()
        elif event.keycode == KEY_F5:
            if main_world:
                main_world.save_progress()
            else:
                save_game()
        elif event.keycode == KEY_F9:
            if main_world:
                main_world._load_progress()
            else:
                load_game()
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        _shoot()

func _physics_process(delta: float) -> void:
    if main_world and not main_world.game_started:
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    if current_car:
        _drive_car(delta)
        return
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var forward := -camera_pivot.global_basis.z
    var right := camera_pivot.global_basis.x
    var direction := (right * input_dir.x + forward * -input_dir.y).normalized()
    var run_speed := speed * (1.55 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
    velocity.x = direction.x * run_speed
    velocity.z = direction.z * run_speed
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = 8.5
    else:
        velocity.y = -0.2
    if direction.length() > 0.1:
        body_mesh.rotation.y = atan2(direction.x, direction.z)
        _play_visual_animation(["Run", "run", "Jog", "jog"] if run_speed > speed else ["Walk", "walk", "Jog", "jog"])
    else:
        _play_visual_animation(["Idle", "idle"])
    move_and_slide()

func _toggle_camera() -> void:
    first_person = not first_person
    if first_person:
        camera.position = Vector3(0, 0.55, -0.12)
        camera.rotation = Vector3.ZERO
        body_mesh.visible = false
    else:
        camera.position = Vector3(0, 1.0, 5.8)
        camera.rotation.x = deg_to_rad(-10)
        body_mesh.visible = current_car == null

func save_game() -> void:
    var config := ConfigFile.new()
    config.set_value("player", "health", health)
    config.set_value("player", "ammo", ammo)
    config.set_value("player", "position", global_position)
    if main_world:
        config.set_value("player", "credits", main_world.credits)
        config.set_value("player", "wanted", main_world.wanted)
    config.save(save_path)

func load_game() -> void:
    var config := ConfigFile.new()
    if config.load(save_path) != OK:
        return
    health = int(config.get_value("player", "health", 100))
    ammo = int(config.get_value("player", "ammo", 90))
    global_position = config.get_value("player", "position", Vector3(4, 0.3, 4))
    if main_world:
        main_world.credits = int(config.get_value("player", "credits", 350))
        main_world.wanted = int(config.get_value("player", "wanted", 0))

func _drive_car(_delta: float) -> void:
    var throttle := Input.get_axis("move_back", "move_forward")
    var steering := Input.get_axis("move_left", "move_right")
    current_car.call("drive", throttle, steering, _delta)
    global_position = current_car.global_position + Vector3.UP * 1.0
    camera_pivot.global_position = global_position

func _try_enter_car() -> void:
    var nearest: Node3D
    var best := 4.5
    for n in get_tree().get_nodes_in_group("cars"):
        var d := global_position.distance_to(n.global_position)
        if d < best and not n.get("occupied"):
            best = d
            nearest = n
    if nearest:
        current_car = nearest
        current_car.set("occupied", true)
        body_mesh.visible = false

func _shoot() -> void:
    if ammo <= 0 or current_car:
        return
    ammo -= 1
    _play_visual_animation(["Shoot", "shoot", "Rifle_Aim_Shoot", "Pistol_Shoot"])
    var from := camera.global_position
    var to := from + -camera.global_basis.z * 160.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var target: Object = hit.get("collider")
        if target and target.has_method("take_damage"):
            target.take_damage(50)
            if main_world:
                main_world.add_crime(1)
                main_world._notify("Попадание! Осталось патронов: %d" % ammo)

func _punch() -> void:
    if attack_cooldown > 0.0:
        return
    attack_cooldown = 0.55
    _play_visual_animation(["Punch", "punch", "Melee", "Attack"])
    for npc in get_tree().get_nodes_in_group("people"):
        if global_position.distance_to(npc.global_position) < 2.2 and npc.has_method("take_damage"):
            npc.take_damage(35)
            if main_world:
                main_world.add_crime(1)
            break
