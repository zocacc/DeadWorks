extends Node3D
class_name HumanoidVisual

@export var zombie := false

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: MeshInstance3D
var head: MeshInstance3D
var _walk_phase := 0.0
var _motion := 0.0
var _attack_time := 0.0
var _hurt_time := 0.0
var _death_time := 0.0
var _dead := false
var _materials: Array[StandardMaterial3D] = []
var _base_colors: Array[Color] = []


func _ready() -> void:
	var cloth := _material(Color("64747a") if not zombie else Color("686d69"))
	var dark := _material(Color("424a4d") if not zombie else Color("535753"))
	var skin := _material(Color("a8a8a1") if not zombie else Color("9aaba0"))
	var boots := _material(Color("343b3d"))
	torso = _box(self, Vector3(0, 1.20, 0), Vector3(0.58, 0.69, 0.36), cloth)
	_box(self, Vector3(0, 0.83, 0), Vector3(0.54, 0.17, 0.33), dark)
	head = _sphere(self, Vector3(0, 1.82, 0), Vector3(0.22, 0.24, 0.22), skin)
	_box(self, Vector3(0, 1.98, 0.03), Vector3(0.40, 0.08, 0.34), dark)
	left_arm = _limb_pivot(Vector3(-0.39, 1.47, 0))
	right_arm = _limb_pivot(Vector3(0.39, 1.47, 0))
	_box(left_arm, Vector3(0, -0.27, 0), Vector3(0.19, 0.52, 0.22), cloth)
	_box(right_arm, Vector3(0, -0.27, 0), Vector3(0.19, 0.52, 0.22), cloth)
	_box(left_arm, Vector3(0, -0.58, 0), Vector3(0.15, 0.15, 0.17), skin)
	_box(right_arm, Vector3(0, -0.58, 0), Vector3(0.15, 0.15, 0.17), skin)
	left_leg = _limb_pivot(Vector3(-0.17, 0.79, 0))
	right_leg = _limb_pivot(Vector3(0.17, 0.79, 0))
	_box(left_leg, Vector3(0, -0.32, 0), Vector3(0.24, 0.65, 0.28), dark)
	_box(right_leg, Vector3(0, -0.32, 0), Vector3(0.24, 0.65, 0.28), dark)
	_box(left_leg, Vector3(0, -0.69, -0.06), Vector3(0.28, 0.17, 0.40), boots)
	_box(right_leg, Vector3(0, -0.69, -0.06), Vector3(0.28, 0.17, 0.40), boots)
	if zombie:
		left_arm.rotation.x = -0.45
		right_arm.rotation.x = -0.45


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	_materials.append(material)
	_base_colors.append(color)
	return material


func _limb_pivot(at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	add_child(pivot)
	return pivot


func _box(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	instance.mesh = box
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance


func _sphere(parent: Node3D, at: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	instance.mesh = sphere
	instance.material_override = material
	instance.position = at
	instance.scale = scale_value
	parent.add_child(instance)
	return instance


func set_motion(speed_ratio: float) -> void:
	_motion = clampf(speed_ratio, 0.0, 1.0)


func play_attack() -> void:
	_attack_time = 0.38


func play_hurt() -> void:
	_hurt_time = 0.22


func play_death() -> void:
	_dead = true
	_death_time = 0.0


func _process(delta: float) -> void:
	if _dead:
		_death_time = minf(_death_time + delta, 0.55)
		rotation.z = lerpf(0.0, 1.35, _death_time / 0.55)
		position.y = -0.35 * (_death_time / 0.55)
		return
	_attack_time = maxf(0.0, _attack_time - delta)
	_hurt_time = maxf(0.0, _hurt_time - delta)
	_walk_phase += delta * (8.0 if zombie else 11.0) * _motion
	var swing := sin(_walk_phase) * 0.52 * _motion
	left_leg.rotation.x = swing
	right_leg.rotation.x = -swing
	left_arm.rotation.x = (-0.5 if zombie else 0.0) - swing * 0.65
	right_arm.rotation.x = (-0.5 if zombie else 0.0) + swing * 0.65
	if _attack_time > 0.0:
		left_arm.rotation.x = -1.05
		right_arm.rotation.x = -1.25
	for index in _materials.size():
		_materials[index].albedo_color = _base_colors[index].lerp(Color("d96a64"), 0.6 if _hurt_time > 0.0 else 0.0)
	position.y = absf(sin(_walk_phase)) * 0.055 * _motion
