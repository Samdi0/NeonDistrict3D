extends CharacterBody3D

var occupied := false
var drive_speed := 0.0
var steering := 0.0
var car_color := Color(0.85, 0.05, 0.3)

func _ready() -> void:
    add_to_group("cars")
    car_color = [Color(0.85, 0.05, 0.3), Color(0.05, 0.75, 0.95), Color(0.8, 0.55, 0.08), Color(0.35, 0.2, 0.9)].pick_random()
    var model_path := "res://assets/models/car.glb"
    if ResourceLoader.exists(model_path):
        var packed := load(model_path) as PackedScene
        if packed:
            add_child(packed.instantiate())
    var body := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(2.0, 0.75, 4.0)
    body.mesh = box
    body.position.y = 0.65
    var mat := StandardMaterial3D.new()
    mat.albedo_color = car_color
    mat.metallic = 0.55
    mat.roughness = 0.25
    body.material_override = mat
    add_child(body)
    var cabin := MeshInstance3D.new()
    var cab := BoxMesh.new()
    cab.size = Vector3(1.55, 0.7, 1.8)
    cabin.mesh = cab
    cabin.position = Vector3(0, 1.28, -0.15)
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(0.04, 0.16, 0.22, 0.8)
    glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cabin.material_override = glass
    add_child(cabin)
    # Front/rear bumpers, grille, headlights and four visible wheels.
    _car_part(BoxMesh.new(), Vector3(0, 0.42, -2.02), Vector3(1.9, 0.22, 0.16), Color(0.12, 0.14, 0.2))
    _car_part(BoxMesh.new(), Vector3(0, 0.42, 2.02), Vector3(1.9, 0.22, 0.16), Color(0.12, 0.14, 0.2))
    _car_part(BoxMesh.new(), Vector3(0, 0.62, -2.11), Vector3(0.72, 0.22, 0.05), Color(0.025, 0.035, 0.045))
    _car_part(BoxMesh.new(), Vector3(-0.66, 0.78, -2.06), Vector3(0.42, 0.2, 0.08), Color(0.45, 0.85, 1.0), true)
    _car_part(BoxMesh.new(), Vector3(0.66, 0.78, -2.06), Vector3(0.42, 0.2, 0.08), Color(0.45, 0.85, 1.0), true)
    _car_part(BoxMesh.new(), Vector3(-0.66, 0.78, 2.06), Vector3(0.42, 0.2, 0.08), Color(1.0, 0.025, 0.08), true)
    _car_part(BoxMesh.new(), Vector3(0.66, 0.78, 2.06), Vector3(0.42, 0.2, 0.08), Color(1.0, 0.025, 0.08), true)
    for x in [-0.98, 0.98]:
        for z in [-1.28, 1.28]:
            _car_part(CylinderMesh.new(), Vector3(x, 0.43, z), Vector3(0.22, 0.16, 0.22), Color(0.012, 0.015, 0.025))
            _car_part(CylinderMesh.new(), Vector3(x * 1.01, 0.43, z), Vector3(0.12, 0.17, 0.12), Color(0.35, 0.4, 0.48))
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.0, 1.3, 4.0)
    collision.shape = shape
    collision.position.y = 0.7
    add_child(collision)
    # Keep the vehicle collision independent from visual details (glass, lights and wheels).

func _car_part(mesh_resource: PrimitiveMesh, part_position: Vector3, part_scale: Vector3, color: Color, glow := false) -> void:
    var part := MeshInstance3D.new()
    part.mesh = mesh_resource
    part.position = part_position
    part.scale = part_scale
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.38
    if glow:
        material.emission_enabled = true
        material.emission = color
    part.material_override = material
    add_child(part)

func drive(throttle: float, steer: float, delta: float) -> void:
    drive_speed = move_toward(drive_speed, throttle * 20.0, 16.0 * delta)
    rotation.y -= steer * 1.35 * delta * sign(drive_speed if absf(drive_speed) > 0.1 else 1.0)
    var forward := -global_basis.z
    velocity.x = forward.x * drive_speed
    velocity.z = forward.z * drive_speed
    move_and_slide()
