extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const NPCScript = preload("res://scripts/npc.gd")
const CarScript = preload("res://scripts/car.gd")

var player: Variant
var hud: CanvasLayer
var status_label: Label
var mission_label: Label
var wanted := 0
var credits := 350
var mission_index := 0
var enemies_defeated := 0
var inventory := {"Аптечка": 2, "Патроны": 90, "Кредиты": 350}
var mission_stage := 0
var police_timer := 0.0
var police_units := 0
var game_started := false
var network := NetworkManager.new()
var menu_layer: CanvasLayer
var inventory_label: Label
var network_label: Label
var locations: Array[Dictionary] = []

func _ready() -> void:
    randomize()
    _build_environment()
    _build_city()
    _spawn_cars()
    _spawn_people()
    _spawn_player()
    add_child(network)
    network.connection_message.connect(_on_network_message)
    _build_locations()
    _build_hud()
    _build_main_menu()
    _load_progress()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.015, 0.025, 0.09)
    sky_mat.sky_horizon_color = Color(0.12, 0.025, 0.12)
    sky_mat.ground_bottom_color = Color(0.012, 0.015, 0.025)
    sky_mat.ground_horizon_color = Color(0.04, 0.025, 0.08)
    env.sky.sky_material = sky_mat
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.25, 0.28, 0.42)
    env.ambient_light_energy = 0.65
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_color = Color(0.45, 0.55, 1.0)
    sun.light_energy = 0.28
    add_child(sun)

    # A single continuous collision floor supports walking and driving across all streets.
    var floor_body := StaticBody3D.new()
    floor_body.position = Vector3(0, -0.6, 0)
    var floor_mesh := MeshInstance3D.new()
    var floor_box := BoxMesh.new()
    floor_box.size = Vector3(520, 1, 520)
    floor_mesh.mesh = floor_box
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color(0.035, 0.045, 0.075)
    floor_mesh.material_override = floor_mat
    floor_body.add_child(floor_mesh)
    var floor_col := CollisionShape3D.new()
    var floor_shape := BoxShape3D.new()
    floor_shape.size = Vector3(520, 1, 520)
    floor_col.shape = floor_shape
    floor_body.add_child(floor_col)
    add_child(floor_body)

func _build_city() -> void:
    for i in range(-5, 6):
        var road_x := i * 42.0
        var road_z := i * 42.0
        _add_box(Vector3(road_x, -0.05, 0), Vector3(12, 0.12, 520), Color(0.075, 0.085, 0.12))
        _add_box(Vector3(0, -0.04, road_z), Vector3(520, 0.12, 12), Color(0.075, 0.085, 0.12))
        for j in range(-12, 13):
            _add_box(Vector3(road_x, 0.025, j * 20.0), Vector3(0.18, 0.03, 7), Color(0.85, 0.72, 0.35))
            _add_box(Vector3(j * 20.0, 0.025, road_z), Vector3(7, 0.03, 0.18), Color(0.85, 0.72, 0.35))

    for gx in range(-5, 5):
        for gz in range(-5, 5):
            if abs(gx) < 1 and abs(gz) < 1:
                continue
            var center := Vector3(gx * 42.0 + 21.0, 0, gz * 42.0 + 21.0)
            var h := randf_range(12.0, 48.0)
            var w := randf_range(17.0, 26.0)
            var d := randf_range(17.0, 26.0)
            var base_color := Color.from_hsv(randf_range(0.56, 0.78), randf_range(0.25, 0.55), randf_range(0.16, 0.32))
            var neon := [Color(0.05, 0.8, 1.0), Color(1.0, 0.08, 0.48), Color(0.5, 0.2, 1.0)].pick_random()
            _create_building(center, w, h, d, base_color, neon)

func _create_building(center: Vector3, width: float, height: float, depth: float, base_color: Color, neon: Color) -> void:
    _add_solid_box(center + Vector3(0, height * 0.5, 0), Vector3(width, height, depth), base_color)
    # Roof cap, facade bands, illuminated windows and vertical neon signage.
    # Roof is a separate solid body so its overhang also blocks the player.
    _add_solid_box(center + Vector3(0, height + 0.18, 0), Vector3(width + 0.7, 0.36, depth + 0.7), Color(0.025, 0.035, 0.08))
    for floor_index in range(1, int(height / 3.8)):
        var y := floor_index * 3.8
        _add_box(center + Vector3(0, y, depth * 0.5 + 0.035), Vector3(width * 0.88, 0.12, 0.07), neon, true)
        var window_count := maxi(2, int(width / 3.2))
        for window_index in range(window_count):
            var x := -width * 0.38 + float(window_index) * (width * 0.76 / float(window_count - 1))
            var window_color := Color(0.08, 0.65, 0.95) if (window_index + floor_index) % 3 != 0 else Color(1.0, 0.48, 0.12)
            _add_box(center + Vector3(x, y + 1.0, depth * 0.5 + 0.045), Vector3(1.15, 1.55, 0.08), window_color, true)
            _add_box(center + Vector3(x, y + 1.0, -depth * 0.5 - 0.045), Vector3(1.15, 1.55, 0.08), window_color, true)
    _add_box(center + Vector3(width * 0.5 + 0.045, height * 0.48, 0), Vector3(0.08, 0.22, depth * 0.76), neon, true)
    _add_box(center + Vector3(-width * 0.5 - 0.045, height * 0.48, 0), Vector3(0.08, 0.22, depth * 0.76), neon, true)
    # Ground-floor entrance and sign.
    _add_box(center + Vector3(0, 1.25, depth * 0.5 + 0.07), Vector3(1.8, 2.5, 0.12), Color(0.015, 0.09, 0.14), true)
    _add_box(center + Vector3(0, 2.8, depth * 0.5 + 0.12), Vector3(width * 0.55, 0.3, 0.16), neon, true)

func _spawn_cars() -> void:
    # Cars are placed on nearby streets as well as farther city roads.
    for i in range(18):
        var car: CharacterBody3D = CharacterBody3D.new()
        car.set_script(CarScript)
        if i < 8:
            var lane := [-42.0, 0.0, 42.0].pick_random()
            if randf() < 0.5:
                car.position = Vector3(lane + randf_range(-2.0, 2.0), 0.2, randf_range(-38.0, 38.0))
            else:
                car.position = Vector3(randf_range(-38.0, 38.0), 0.2, lane + randf_range(-2.0, 2.0))
        else:
            var road := randi_range(-5, 5) * 42.0
            car.position = Vector3(road + randf_range(-2.0, 2.0), 0.2, randf_range(-190.0, 190.0))
        car.rotation.y = [0.0, PI / 2.0].pick_random()
        add_child(car)

func _spawn_people() -> void:
    # Keep a visible population near the starting area; the rest populate nearby blocks.
    for i in range(34):
        var npc: CharacterBody3D = CharacterBody3D.new()
        npc.set_script(NPCScript)
        if i < 18:
            npc.position = Vector3(randf_range(-13.0, 13.0), 0.1, randf_range(-13.0, 13.0))
        else:
            var road := [-42.0, 0.0, 42.0].pick_random()
            npc.position = Vector3(road + randf_range(-3.0, 3.0), 0.1, randf_range(-38.0, 38.0))
        npc.is_hostile = randf() < 0.3
        npc.is_police = false
        npc.archetype_id = randi_range(1, 52)
        add_child(npc)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    player.position = Vector3(4, 0.3, 4)
    player.main_world = self
    add_child(player)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 14)
    panel.add_theme_stylebox_override("panel", _panel_style())
    hud.add_child(panel)
    var vbox := VBoxContainer.new()
    panel.add_child(vbox)
    var title := Label.new()
    title.text = "NEON DISTRICT  //  NIGHT CITY"
    title.add_theme_color_override("font_color", Color(0.15, 0.9, 1))
    title.add_theme_font_size_override("font_size", 18)
    vbox.add_child(title)
    status_label = Label.new()
    status_label.text = "Загрузка..."
    vbox.add_child(status_label)
    mission_label = Label.new()
    mission_label.position = Vector2(16, 105)
    mission_label.text = "ЗАДАНИЕ 01: Найди транспорт и исследуй город"
    mission_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.7))
    hud.add_child(mission_label)
    var help := Label.new()
    help.position = Vector2(16, 145)
    help.text = "WASD — движение/руль  |  Мышь — обзор  |  ЛКМ — огонь\nE — сесть/выйти  |  F — удар  |  Shift — бег  |  Esc — курсор"
    help.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
    hud.add_child(help)
    inventory_label = Label.new()
    inventory_label.position = Vector2(16, 195)
    inventory_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65))
    hud.add_child(inventory_label)
    _update_mission_text()

func _panel_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.015, 0.025, 0.07, 0.88)
    s.border_color = Color(0.05, 0.75, 0.95, 0.8)
    s.set_border_width_all(1)
    s.set_corner_radius_all(8)
    s.content_margin_left = 12
    s.content_margin_right = 12
    s.content_margin_top = 8
    s.content_margin_bottom = 8
    return s

func _process(delta: float) -> void:
    if not game_started:
        return
    police_timer -= delta
    if wanted > 0 and police_timer <= 0.0 and police_units < wanted * 2:
        _spawn_police()
        police_timer = maxf(2.0, 8.0 - wanted)
    if is_instance_valid(player) and is_instance_valid(status_label):
        status_label.text = "HP: %d   ПАТРОНЫ: %d   €: %d\nРОЗЫСК: %s   УСТРАНЕНО: %d" % [
            player.health, player.ammo, credits, "★".repeat(wanted), enemies_defeated
        ]
        if is_instance_valid(inventory_label):
            inventory_label.text = "ИНВЕНТАРЬ  |  Аптечки: %d  |  Патроны: %d" % [int(inventory.get("Аптечка", 0)), player.ammo]

func add_crime(amount: int = 1) -> void:
    wanted = clampi(wanted + amount, 0, 5)

func _build_locations() -> void:
    locations = [
        {"name":"Магазин 24/7", "position":Vector3(18, 0, 8), "kind":"shop"},
        {"name":"Гараж Риппер", "position":Vector3(-18, 0, 10), "kind":"garage"},
        {"name":"Убежище", "position":Vector3(8, 0, -18), "kind":"safehouse"}
    ]
    for place in locations:
        var pos: Vector3 = place.position
        _add_solid_box(pos + Vector3(0, 2, 0), Vector3(8, 4, 7), Color(0.035, 0.07, 0.13))
        _add_box(pos + Vector3(0, 3.2, 3.56), Vector3(5.5, 0.35, 0.12), Color(0.05, 0.9, 1.0), true)
        var area := Area3D.new()
        area.name = str(place.name)
        area.position = pos
        var shape := CollisionShape3D.new()
        var sphere := SphereShape3D.new()
        sphere.radius = 5.0
        shape.shape = sphere
        area.add_child(shape)
        add_child(area)

func interact_with_world() -> void:
    if not player:
        return
    for place in locations:
        if player.global_position.distance_to(place.position) < 6.0:
            match place.kind:
                "shop":
                    if credits >= 40:
                        credits -= 40
                        player.ammo += 30
                        inventory["Патроны"] = player.ammo
                        mission_progress("shop")
                        mission_progress("buy")
                        _notify("Куплено 30 патронов за 40 кредитов")
                    else:
                        _notify("Недостаточно кредитов: нужно 40")
                "garage":
                    if credits >= 100:
                        credits -= 100
                        player.health = 100
                        _notify("Ремонт и обслуживание завершены")
                    else:
                        _notify("Для ремонта нужно 100 кредитов")
                "safehouse":
                    wanted = 0
                    player.health = 100
                    mission_progress("safehouse")
                    save_progress()
                    _notify("Розыск сброшен. Прогресс сохранён")
            return
    _notify("Подойди к магазину, гаражу или убежищу и нажми E")

func _spawn_police() -> void:
    var cop: Variant = CharacterBody3D.new()
    cop.set_script(NPCScript)
    cop.is_hostile = true
    cop.is_police = true
    cop.position = player.global_position + Vector3(randf_range(-24, 24), 0.2, randf_range(-24, 24))
    add_child(cop)
    police_units += 1

func _build_main_menu() -> void:
    menu_layer = CanvasLayer.new()
    add_child(menu_layer)
    var shade := ColorRect.new()
    shade.color = Color(0.005, 0.008, 0.025, 0.94)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(shade)
    var panel := VBoxContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-190, -190)
    panel.size = Vector2(380, 380)
    panel.add_theme_constant_override("separation", 12)
    menu_layer.add_child(panel)
    var heading := Label.new()
    heading.text = "NEON DISTRICT 3D\nNIGHT CITY"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 30)
    heading.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
    panel.add_child(heading)
    _menu_button(panel, "НОВАЯ ИГРА", _start_game)
    _menu_button(panel, "СОХРАНИТЬ ПРОГРЕСС", save_progress)
    _menu_button(panel, "ЗАГРУЗИТЬ ПРОГРЕСС", _load_progress)
    _menu_button(panel, "СОЗДАТЬ СЕТЕВУЮ СЕССИЮ", _host_session)
    var address := LineEdit.new()
    address.name = "ServerAddress"
    address.placeholder_text = "IP сервера для подключения"
    address.text = "127.0.0.1"
    panel.add_child(address)
    var join := Button.new()
    join.text = "ПОДКЛЮЧИТЬСЯ"
    join.pressed.connect(func(): _join_session(address.text))
    panel.add_child(join)
    network_label = Label.new()
    network_label.text = "Одиночная игра готова. Онлайн требует доступный сервер."
    network_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(network_label)

func _menu_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
    var b := Button.new()
    b.text = caption
    b.custom_minimum_size.y = 38
    b.pressed.connect(action)
    parent.add_child(b)

func _start_game() -> void:
    game_started = true
    menu_layer.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _notify("Город открыт. Изучай районы и выполняй задания")

func _host_session() -> void:
    var err := network.host_game()
    if err == OK:
        network_label.text = "Сервер запущен на порту 24567. Для интернета нужен проброс порта/хостинг."

func _join_session(address: String) -> void:
    network.join_game(address)

func _on_network_message(message: String) -> void:
    if is_instance_valid(network_label):
        network_label.text = message

func _notify(message: String) -> void:
    if is_instance_valid(mission_label):
        mission_label.text = message

func save_progress() -> void:
    if is_instance_valid(player):
        inventory["Патроны"] = player.ammo
        player.save_game()
    var cfg := ConfigFile.new()
    cfg.set_value("world", "credits", credits)
    cfg.set_value("world", "wanted", wanted)
    cfg.set_value("world", "defeated", enemies_defeated)
    cfg.set_value("world", "mission_stage", mission_stage)
    cfg.set_value("world", "inventory", inventory)
    cfg.save("user://neon_district_progress.cfg")
    _notify("Прогресс сохранён")

func _load_progress() -> void:
    var cfg := ConfigFile.new()
    if cfg.load("user://neon_district_progress.cfg") != OK:
        return
    credits = int(cfg.get_value("world", "credits", credits))
    wanted = int(cfg.get_value("world", "wanted", wanted))
    enemies_defeated = int(cfg.get_value("world", "defeated", enemies_defeated))
    mission_stage = int(cfg.get_value("world", "mission_stage", mission_stage))
    inventory = cfg.get_value("world", "inventory", inventory)
    if is_instance_valid(player):
        player.load_game()
        player.ammo = int(inventory.get("Патроны", player.ammo))
    _update_mission_text()

func _update_mission_text() -> void:
    var missions := ["ЗАДАНИЕ 1: Доберись до магазина 24/7", "ЗАДАНИЕ 2: Купи боеприпасы", "ЗАДАНИЕ 3: Победи 3 противников", "ЗАДАНИЕ 4: Вернись в убежище"]
    mission_label.text = missions[mini(mission_stage, missions.size() - 1)]

func mission_progress(event_name: String) -> void:
    var expected := ["shop", "buy", "combat", "safehouse"]
    if mission_stage < expected.size() and event_name == expected[mission_stage]:
        mission_stage += 1
        _update_mission_text()
        credits += 150
        _notify("Задание выполнено! Награда: 150 кредитов")
        save_progress()

func on_npc_removed(was_police: bool) -> void:
    if was_police:
        police_units = maxi(0, police_units - 1)

func award(amount: int) -> void:
    credits += amount
    enemies_defeated += 1
    if enemies_defeated >= 3:
        mission_progress("combat")

func _add_box(pos: Vector3, size: Vector3, color: Color, emissive := false) -> void:
    var n := _box(pos, size, color, emissive)
    add_child(n)

func _add_solid_box(pos: Vector3, size: Vector3, color: Color, emissive := false) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    body.add_child(_box(Vector3.ZERO, size, color, emissive))
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

func _box(pos: Vector3, size: Vector3, color: Color, emissive := false) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.8
    mi.material_override = mat
    return mi
