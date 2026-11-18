extends CharacterBody3D
class_name PrototypeZombie

signal killed

@export_range(1.0, 200.0, 1.0) var max_health := 60.0
@export_range(0.5, 10.0, 0.1) var move_speed := 2.6
@export_range(1.0, 100.0, 1.0) var detection_radius := 38.0
@export_range(0.5, 3.0, 0.05) var attack_range := 1.25
@export_range(1.0, 100.0, 1.0) var attack_damage := 10.0
@export_range(0.1, 5.0, 0.1) var attack_cooldown := 1.1

var health := 60.0
var target: PrototypePlayer
var dead := false
var _attack_left := 0.0
var _death_left := 0.0

@onready var visual: HumanoidVisual = $Visual


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	if dead:
		_death_left -= delta
		if _death_left <= 0.0:
			queue_free()
		return
	_attack_left = maxf(0.0, _attack_left - delta)
	if not is_instance_valid(target) or target.health <= 0.0:
		visual.set_motion(0.0)
		return
	var flat := target.global_position - global_position
	flat.y = 0.0
	var distance := flat.length()
	if distance > detection_radius:
		visual.set_motion(0.0)
		return
	var direction := flat.normalized()
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, 7.0 * delta))
	if distance <= attack_range:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		visual.set_motion(0.0)
		if _attack_left <= 0.0:
			target.take_damage(attack_damage)
			visual.play_attack()
			_attack_left = attack_cooldown
	else:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		visual.set_motion(1.0)
	velocity.y = -0.1 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()


func take_damage(amount: float) -> void:
	if dead:
		return
	health -= amount
	visual.play_hurt()
	if health <= 0.0:
		dead = true
		_death_left = 0.75
		velocity = Vector3.ZERO
		$Collision.set_deferred("disabled", true)
		visual.play_death()
		killed.emit()
