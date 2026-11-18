extends Node3D
class_name ZombieSpawner

signal kills_changed(total: int)

const ZOMBIE_SCENE = preload("res://scenes/prototype3d/zombie.tscn")

@export_range(0, 100, 1) var initial_count := 20
@export_range(1, 200, 1) var maximum_alive := 60
@export_range(0.1, 20.0, 0.1) var spawn_interval := 1.6
@export_range(2.0, 30.0, 0.5) var minimum_spawn_distance := 10.0
@export_range(3.0, 40.0, 0.5) var maximum_spawn_distance := 18.0
@export_range(10.0, 100.0, 1.0) var arena_half_extent := 39.0

var player: PrototypePlayer
var kills := 0
var _clock := 0.0
var _running := false
var _random := RandomNumberGenerator.new()


func start() -> void:
	if not is_instance_valid(player):
		return
	_random.randomize()
	_running = true
	for index in mini(initial_count, maximum_alive):
		spawn_one()


func _process(delta: float) -> void:
	if not _running or not is_instance_valid(player) or player.health <= 0.0:
		return
	_clock += delta
	if _clock >= spawn_interval and alive_count() < maximum_alive:
		_clock = 0.0
		spawn_one()


func alive_count() -> int:
	var count := 0
	for child in get_children():
		if child is PrototypeZombie and not child.dead:
			count += 1
	return count


func spawn_one() -> PrototypeZombie:
	if not is_instance_valid(player) or alive_count() >= maximum_alive:
		return null
	var location := Vector3.ZERO
	var found := false
	for attempt in 32:
		var angle := _random.randf_range(0.0, TAU)
		var radius := _random.randf_range(minimum_spawn_distance, maximum_spawn_distance)
		location = player.global_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if absf(location.x) <= arena_half_extent and absf(location.z) <= arena_half_extent:
			found = true
			break
	if not found:
		return null
	var zombie: PrototypeZombie = ZOMBIE_SCENE.instantiate()
	zombie.position = location
	zombie.target = player
	zombie.killed.connect(_on_zombie_killed)
	add_child(zombie)
	return zombie


func _on_zombie_killed() -> void:
	kills += 1
	kills_changed.emit(kills)
