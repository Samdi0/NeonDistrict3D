extends CharacterBody3D

var occupied := false
var drive_speed := 0.0
var steering := 0.0
var car_color := Color(0.85, 0.05, 0.3)

func _ready() -> void:
    add_to_group("cars")
    car_color = [Color(0.85, 0.05, 0.3), Color(0.05, 0.75, 0.95), Color(0.8, 0.55, 0.08), Color(0.35, 0.2, 0.9)].pick_random()
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
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.0, 1.3, 4.0)
    collision.shape = shape
    collision.position.y = 0.7
    add_child(collision)

func drive(throttle: float, steer: float, delta: float) -> void:
    drive_speed = move_toward(drive_speed, throttle * 20.0, 16.0 * delta)
    rotation.y -= steer * 1.35 * delta * sign(drive_speed if absf(drive_speed) > 0.1 else 1.0)
    var forward := -global_basis.z
    velocity.x = forward.x * drive_speed
    velocity.z = forward.z * drive_speed
    move_and_slide()
