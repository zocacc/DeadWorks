extends Node3D
class_name PrototypeWeapon

signal fired(origin: Vector3, end: Vector3)

@export_range(1.0, 20.0, 0.5) var shots_per_second := 8.0
@export_range(1.0, 100.0, 1.0) var damage := 25.0
@export_range(5.0, 100.0, 1.0) var max_range := 60.0

var _cooldown := 0.0
var _effect_time := 0.0
var _tracer: MeshInstance3D
var _flash: MeshInstance3D


func _ready() -> void:
	_tracer = MeshInstance3D.new()
	var tracer_material := StandardMaterial3D.new()
	tracer_material.albedo_color = Color("eecb83")
	tracer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tracer.material_override = tracer_material
	_tracer.visible = false
	add_child(_tracer)
	_tracer.top_level = true
	_flash = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.26
	_flash.mesh = sphere
	_flash.material_override = tracer_material
	_flash.visible = false
	add_child(_flash)
	_flash.top_level = true


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_effect_time = maxf(0.0, _effect_time - delta)
	_tracer.visible = _effect_time > 0.0
	_flash.visible = _effect_time > 0.0


func try_fire(direction: Vector3) -> bool:
	if _cooldown > 0.0 or direction.length_squared() < 0.001:
		return false
	var shooter := get_parent() as CharacterBody3D
	if shooter == null:
		return false
	_cooldown = 1.0 / shots_per_second
	var horizontal := Vector3(direction.x, 0.0, direction.z).normalized()
	var origin := shooter.global_position + Vector3.UP * 1.35 + horizontal * 0.52
	var end := origin + horizontal * max_range
	var query := PhysicsRayQueryParameters3D.create(origin, end, 2)
	query.exclude = [shooter.get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		end = result["position"]
		var hit: Object = result["collider"]
		if hit.has_method("take_damage"):
			hit.take_damage(damage)
	_show_shot(origin, end)
	fired.emit(origin, end)
	return true


func _show_shot(origin: Vector3, end: Vector3) -> void:
	var difference := end - origin
	var beam := CylinderMesh.new()
	beam.top_radius = 0.018
	beam.bottom_radius = 0.018
	beam.height = maxf(0.01, difference.length())
	_tracer.mesh = beam
	_tracer.global_position = (origin + end) * 0.5
	_tracer.global_basis = Basis(Quaternion(Vector3.UP, difference.normalized()))
	_flash.global_position = origin
	_effect_time = 0.075
	_tracer.visible = true
	_flash.visible = true
