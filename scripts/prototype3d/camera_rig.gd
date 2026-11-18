extends Node3D
class_name CombatCameraRig

@export_range(15.0, 80.0, 1.0) var tilt_degrees := 55.0
@export_range(8.0, 50.0, 0.5) var distance := 20.0
@export_range(20.0, 90.0, 1.0) var perspective_fov := 40.0
@export_range(1.0, 20.0, 0.5) var follow_smoothing := 7.0
@export_range(5.0, 30.0, 0.5) var minimum_zoom := 10.0
@export_range(15.0, 80.0, 0.5) var maximum_zoom := 38.0
@export_range(0.5, 8.0, 0.5) var zoom_step := 2.0
@export var start_orthographic := false

var target: Node3D
var orthographic := false

@onready var view: Camera3D = $Camera3D


func _ready() -> void:
	orthographic = start_orthographic
	_apply_camera()


func _process(delta: float) -> void:
	if is_instance_valid(target):
		var weight := 1.0 - exp(-follow_smoothing * delta)
		global_position = global_position.lerp(target.global_position, weight)
	_apply_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - zoom_step, minimum_zoom, maximum_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + zoom_step, minimum_zoom, maximum_zoom)
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		set_orthographic(not orthographic)


func set_orthographic(enabled: bool) -> void:
	orthographic = enabled
	_apply_camera()


func _apply_camera() -> void:
	if view == null:
		return
	var tilt := deg_to_rad(tilt_degrees)
	view.position = Vector3(0.0, sin(tilt) * distance, cos(tilt) * distance)
	view.look_at(global_position + Vector3.UP * 0.9, Vector3.UP)
	if orthographic:
		view.projection = Camera3D.PROJECTION_ORTHOGONAL
		view.size = distance * 0.85
	else:
		view.projection = Camera3D.PROJECTION_PERSPECTIVE
		view.fov = perspective_fov
