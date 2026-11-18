extends CharacterBody3D
class_name PrototypePlayer

signal health_changed(current: float, maximum: float)
signal died

@export_range(1.0, 12.0, 0.1) var walk_speed := 5.2
@export_range(1.0, 18.0, 0.1) var run_speed := 8.0
@export_range(1.0, 100.0, 0.5) var acceleration := 24.0
@export_range(1.0, 100.0, 0.5) var deceleration := 28.0
@export_range(1.0, 25.0, 0.1) var dodge_speed := 13.0
@export_range(0.05, 1.0, 0.01) var dodge_duration := 0.22
@export_range(0.1, 5.0, 0.1) var dodge_cooldown := 1.0
@export_range(1.0, 30.0, 0.5) var turn_speed := 12.0
@export_range(1.0, 500.0, 1.0) var max_health := 100.0

var health := 100.0
var camera: Camera3D
var aim_direction := Vector3.FORWARD
var _dodge_left := 0.0
var _dodge_recharge := 0.0
var _dodge_direction := Vector3.FORWARD
var _hurt_immunity := 0.0

@onready var visual: HumanoidVisual = $Visual
@onready var weapon: PrototypeWeapon = $Weapon


func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if health <= 0.0:
		velocity = Vector3.ZERO
		return
	_dodge_left = maxf(0.0, _dodge_left - delta)
	_dodge_recharge = maxf(0.0, _dodge_recharge - delta)
	_hurt_immunity = maxf(0.0, _hurt_immunity - delta)
	_update_aim(delta)
	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A): input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): input.x += 1.0
	if Input.is_physical_key_pressed(KEY_W): input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S): input.y += 1.0
	var desired := move_direction_for_input(input, camera)
	var speed := run_speed if Input.is_physical_key_pressed(KEY_SHIFT) else walk_speed
	if _dodge_left > 0.0:
		velocity.x = _dodge_direction.x * dodge_speed
		velocity.z = _dodge_direction.z * dodge_speed
	else:
		var target := desired * speed
		var change := acceleration if desired.length_squared() > 0.0 else deceleration
		velocity.x = move_toward(velocity.x, target.x, change * delta)
		velocity.z = move_toward(velocity.z, target.z, change * delta)
	velocity.y = -0.1 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	visual.set_motion(Vector2(velocity.x, velocity.z).length() / run_speed)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if weapon.try_fire(aim_direction):
			visual.play_attack()


func move_direction_for_input(input: Vector2, view: Camera3D) -> Vector3:
	if view == null or input.is_zero_approx():
		return Vector3.ZERO
	var right := view.global_basis.x
	right.y = 0.0
	var forward := -view.global_basis.z
	forward.y = 0.0
	return (right.normalized() * input.x + forward.normalized() * -input.y).normalized()


func _update_aim(delta: float) -> void:
	if camera == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var ray := camera.project_ray_normal(mouse)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + ray * 500.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var point: Vector3
	if not hit.is_empty():
		point = hit["position"]
	else:
		var intersection = Plane(Vector3.UP, 0.0).intersects_ray(origin, ray)
		if intersection == null:
			return
		point = intersection
	var flat := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	if flat.length_squared() < 0.09:
		return
	aim_direction = flat.normalized()
	rotation.y = lerp_angle(rotation.y, atan2(-aim_direction.x, -aim_direction.z), minf(1.0, turn_speed * delta))


func _unhandled_input(event: InputEvent) -> void:
	if health <= 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		if _dodge_recharge <= 0.0:
			var input := Vector2.ZERO
			if Input.is_physical_key_pressed(KEY_A): input.x -= 1.0
			if Input.is_physical_key_pressed(KEY_D): input.x += 1.0
			if Input.is_physical_key_pressed(KEY_W): input.y -= 1.0
			if Input.is_physical_key_pressed(KEY_S): input.y += 1.0
			_dodge_direction = move_direction_for_input(input, camera)
			if _dodge_direction.is_zero_approx():
				_dodge_direction = aim_direction
			_dodge_left = dodge_duration
			_dodge_recharge = dodge_cooldown


func take_damage(amount: float) -> void:
	if health <= 0.0 or _hurt_immunity > 0.0:
		return
	health = maxf(0.0, health - amount)
	_hurt_immunity = 0.35
	visual.play_hurt()
	health_changed.emit(health, max_health)
	if health <= 0.0:
		visual.play_death()
		died.emit()
