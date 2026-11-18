extends Node3D

@onready var player: PrototypePlayer = $Player
@onready var camera_rig: CombatCameraRig = $CameraRig
@onready var spawner: ZombieSpawner = $ZombieSpawner
@onready var hud: CombatHUD = $HUD


func _ready() -> void:
	_build_environment()
	camera_rig.target = player
	camera_rig.global_position = player.global_position
	camera_rig._apply_camera()
	player.camera = camera_rig.view
	spawner.player = player
	hud.player = player
	hud.spawner = spawner
	spawner.start()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("20262a")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("7f8b91")
	settings.ambient_light_energy = 0.55
	environment.environment = settings
	add_child(environment)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-58, 35, 0)
	sunlight.light_energy = 1.4
	sunlight.shadow_enabled = true
	add_child(sunlight)
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.collision_layer = 1
	ground.collision_mask = 0
	add_child(ground)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(80, 0.2, 80)
	collision.shape = shape
	collision.position.y = -0.1
	ground.add_child(collision)
	var surface := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	surface.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("515759")
	floor_material.roughness = 1.0
	surface.material_override = floor_material
	ground.add_child(surface)
	var stripe_material := StandardMaterial3D.new()
	stripe_material.albedo_color = Color("41494b")
	stripe_material.roughness = 1.0
	for coordinate in range(-30, 31, 10):
		_add_marking(ground, Vector3(coordinate, 0.012, 0), Vector3(0.055, 0.02, 80), stripe_material)
		_add_marking(ground, Vector3(0, 0.012, coordinate), Vector3(80, 0.02, 0.055), stripe_material)


func _add_marking(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> void:
	var line := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	line.mesh = mesh
	line.position = at
	line.material_override = material
	parent.add_child(line)
