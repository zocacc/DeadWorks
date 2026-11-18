extends SceneTree

const Arena = preload("res://scenes/prototype3d/arena.tscn")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS 3D: ", description)
	else:
		push_error("FAIL 3D: " + description)
		failures += 1


func _run() -> void:
	var arena = Arena.instantiate()
	root.add_child(arena)
	var player: PrototypePlayer = arena.player
	var rig: CombatCameraRig = arena.camera_rig
	var spawner: ZombieSpawner = arena.spawner
	_check(player is CharacterBody3D and player.global_position == Vector3.ZERO, "jogador 3D nasce no centro")
	_check(spawner.alive_count() == 20, "arena inicia com vinte zumbis")
	var first_zombie: PrototypeZombie = spawner.get_child(0)
	first_zombie.visual.set_motion(1.0)
	first_zombie.visual._process(0.1)
	_check(absf(first_zombie.visual.left_leg.rotation.x) > 0.01 and absf(first_zombie.visual.right_leg.rotation.x) > 0.01, "caminhada dos zumbis movimenta as pernas")
	var safe := true
	for zombie in spawner.get_children():
		if zombie.global_position.distance_to(player.global_position) < spawner.minimum_spawn_distance - 0.01:
			safe = false
	_check(safe, "zumbis nascem fora do raio seguro")
	_check(rig.view.projection == Camera3D.PROJECTION_PERSPECTIVE and is_equal_approx(rig.view.fov, 40.0), "câmera inicia em perspectiva de 40 graus")
	_check(is_equal_approx(rig.tilt_degrees, 55.0) and is_equal_approx(rig.distance, 20.0), "inclinação e distância iniciais configuradas")
	rig.set_orthographic(true)
	_check(rig.view.projection == Camera3D.PROJECTION_ORTHOGONAL, "câmera alterna para ortográfica")
	rig.set_orthographic(false)
	_check(rig.view.projection == Camera3D.PROJECTION_PERSPECTIVE, "câmera retorna à perspectiva")
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	rig._unhandled_input(wheel)
	_check(rig.distance < 20.0, "scroll aproxima a câmera")
	var forward := player.move_direction_for_input(Vector2(0, -1), rig.view)
	_check(forward.z < -0.9 and absf(forward.x) < 0.01, "W usa orientação horizontal da câmera")
	var view_rotation := rig.view.global_rotation
	player.rotation.y = 1.4
	await process_frame
	_check(rig.view.global_rotation.distance_to(view_rotation) < 0.001, "mira do jogador não gira a câmera")
	player.rotation.y = 0.0
	var dodge := InputEventKey.new()
	dodge.pressed = true
	dodge.physical_keycode = KEY_SPACE
	player._unhandled_input(dodge)
	_check(player._dodge_left > 0.0 and player._dodge_recharge > 0.0, "esquiva curta respeita cooldown")
	player._dodge_left = 0.0
	spawner.set_process(false)
	for zombie in spawner.get_children():
		zombie.queue_free()
	await process_frame
	var target: PrototypeZombie = load("res://scenes/prototype3d/zombie.tscn").instantiate()
	target.position = Vector3(0, 0, -4)
	target.move_speed = 0.0
	target.target = player
	arena.add_child(target)
	await physics_frame
	await physics_frame
	var shot := player.weapon.try_fire(Vector3.FORWARD)
	_check(shot and target.health == target.max_health - player.weapon.damage, "tiro hitscan acerta zumbi no mundo 3D")
	_check(not player.weapon.try_fire(Vector3.FORWARD), "cadência impede segundo tiro imediato")
	player.weapon._cooldown = 0.0
	player.weapon.try_fire(Vector3.FORWARD)
	player.weapon._cooldown = 0.0
	player.weapon.try_fire(Vector3.FORWARD)
	_check(target.dead, "dano de tiros mata o zumbi")
	var spawned := spawner.spawn_one()
	_check(spawned != null, "spawner gera novos zumbis após liberar espaço")
	if spawned != null:
		spawned.take_damage(1000.0)
	_check(spawner.kills == 1, "morte emitida pelo zumbi atualiza contador")
	var previous_health := player.health
	player.take_damage(10.0)
	await process_frame
	await process_frame
	_check(player.health == previous_health - 10.0 and arena.hud.health_bar.value == player.health, "dano atualiza vida e HUD")
	player._hurt_immunity = 0.0
	var attacker: PrototypeZombie = load("res://scenes/prototype3d/zombie.tscn").instantiate()
	attacker.position = player.global_position + Vector3(0, 0, -0.8)
	attacker.target = player
	arena.add_child(attacker)
	var before_bite := player.health
	attacker._physics_process(0.016)
	_check(player.health == before_bite - attacker.attack_damage, "zumbi ataca corpo a corpo com cooldown")
	arena.queue_free()
	print("Resultado 3D: %d falha(s)" % failures)
	quit(1 if failures > 0 else 0)
