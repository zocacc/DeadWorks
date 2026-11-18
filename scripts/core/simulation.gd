extends RefCounted
class_name DeadWorksSimulation

const GRID_SIZE := 32
const WORLD_SIZE := Vector2i(2048, 1152)
const BELT_STEP := 0.4
const PROCESS_SECONDS := 3.0
const ASSEMBLE_SECONDS := 3.0
const NOISE_RADIUS := 480.0
const PLAYER_DETECTION_RADIUS := 150.0
const ZOMBIE_SPEED := 72.0
const BUILD_COSTS := {"processor": 3, "assembler": 4, "belt": 1}
const CARDINALS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

var scrap := 0
var kits := 0
var player_health := 5
var kills := 0
var machines: Array[Dictionary] = []
var belts: Array[Dictionary] = []
var barricades: Array[Dictionary] = []
var zombies: Array[Dictionary] = []
var piles: Array[Dictionary] = []
var belt_clock := 0.0
var spawn_clock := 0.0
var spawn_count := 0
var attack_cooldown := 0.0
var player_hit_cooldown := 0.0


func _init() -> void:
	for position in [
		Vector2(550, 330), Vector2(760, 360), Vector2(990, 300),
		Vector2(1250, 450), Vector2(1490, 730), Vector2(1100, 870),
		Vector2(680, 780), Vector2(350, 640), Vector2(1730, 380)
	]:
		piles.append({"position": position, "amount": 12, "refill": 0.0})


func cell_at(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / GRID_SIZE), floori(position.y / GRID_SIZE))


func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * GRID_SIZE) + Vector2.ONE * (GRID_SIZE / 2.0)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < WORLD_SIZE.x / GRID_SIZE and cell.y < WORLD_SIZE.y / GRID_SIZE


func collect_scrap(player_position: Vector2) -> bool:
	for pile in piles:
		if pile["amount"] > 0 and player_position.distance_to(pile["position"]) <= 44.0:
			pile["amount"] -= 1
			scrap += 1
			if pile["amount"] == 0:
				pile["refill"] = 30.0
			return true
	return false


func place(kind: String, cell: Vector2i, direction: Vector2i = Vector2i.RIGHT) -> bool:
	if not in_bounds(cell) or occupied(cell):
		return false
	if kind == "barricade":
		if kits < 1:
			return false
		kits -= 1
		barricades.append({"cell": cell, "health": 6})
		return true
	if not BUILD_COSTS.has(kind):
		return false
	if kind == "belt" and not CARDINALS.has(direction):
		return false
	var cost: int = BUILD_COSTS[kind]
	if scrap < cost:
		return false
	scrap -= cost
	if kind == "belt":
		belts.append({"cell": cell, "dir": direction, "item": 0})
	else:
		machines.append({"kind": kind, "cell": cell, "dir": direction, "input": 0, "output": 0, "progress": 0.0, "health": 8})
	return true


func occupied(cell: Vector2i) -> bool:
	if _machine_at(cell) >= 0 or _belt_at(cell) >= 0 or _barricade_at(cell) >= 0:
		return true
	for pile in piles:
		if cell_center(cell).distance_to(pile["position"]) < 34.0:
			return true
	return false


func load_processor(player_position: Vector2) -> bool:
	if scrap < 1:
		return false
	for machine in machines:
		if machine["kind"] == "processor" and player_position.distance_to(cell_center(machine["cell"])) <= 62.0:
			scrap -= 1
			machine["input"] += 1
			return true
	return false


func take_kits(player_position: Vector2) -> bool:
	for machine in machines:
		if machine["kind"] == "assembler" and machine["output"] > 0 and player_position.distance_to(cell_center(machine["cell"])) <= 62.0:
			kits += machine["output"]
			machine["output"] = 0
			return true
	return false


func active_machine_count() -> int:
	var count := 0
	for machine in machines:
		if machine["input"] > 0 and machine["output"] < 4:
			count += 1
	return count


func can_player_move(position: Vector2) -> bool:
	if position.x < 16 or position.y < 16 or position.x > WORLD_SIZE.x - 16 or position.y > WORLD_SIZE.y - 16:
		return false
	for machine in machines:
		if position.distance_to(cell_center(machine["cell"])) < 31.0:
			return false
	for barricade in barricades:
		if position.distance_to(cell_center(barricade["cell"])) < 30.0:
			return false
	return true


func attack(player_position: Vector2, facing: Vector2) -> int:
	if attack_cooldown > 0.0 or player_health <= 0:
		return 0
	attack_cooldown = 0.45
	var hits := 0
	for index in range(zombies.size() - 1, -1, -1):
		var offset: Vector2 = zombies[index]["position"] - player_position
		if offset.length() <= 58.0 and offset.normalized().dot(facing.normalized()) > 0.15:
			zombies[index]["health"] -= 1
			hits += 1
			if zombies[index]["health"] <= 0:
				zombies.remove_at(index)
				kills += 1
	return hits


func step(delta: float, player_position: Vector2) -> void:
	if delta <= 0.0 or player_health <= 0:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	for pile in piles:
		if pile["amount"] == 0:
			pile["refill"] -= delta
			if pile["refill"] <= 0.0:
				pile["amount"] = 12
				pile["refill"] = 0.0
	for machine in machines:
		if machine["input"] <= 0 or machine["output"] >= 4:
			continue
		machine["progress"] += delta
		var cycle := PROCESS_SECONDS if machine["kind"] == "processor" else ASSEMBLE_SECONDS
		while machine["input"] > 0 and machine["output"] < 4 and machine["progress"] + 0.0001 >= cycle:
			machine["input"] -= 1
			machine["output"] += 1
			machine["progress"] = maxf(0.0, machine["progress"] - cycle)
		if machine["input"] == 0:
			machine["progress"] = 0.0
	belt_clock += delta
	while belt_clock >= BELT_STEP:
		belt_clock -= BELT_STEP
		_move_belts()
	spawn_clock += delta
	var spawn_interval := 16.0 / (1.0 + active_machine_count() * 0.75)
	if spawn_clock >= spawn_interval and zombies.size() < 32:
		spawn_clock = 0.0
		_spawn_zombie()
	var remaining := delta
	while remaining > 0.0:
		var slice := minf(remaining, 0.1)
		player_hit_cooldown = maxf(0.0, player_hit_cooldown - slice)
		_update_zombies(slice, player_position)
		remaining -= slice


func zombie_target(position: Vector2, player_position: Vector2) -> Vector2:
	if position.distance_to(player_position) <= PLAYER_DETECTION_RADIUS:
		return player_position
	var best_distance := NOISE_RADIUS
	var target := player_position
	for machine in machines:
		if machine["input"] <= 0 or machine["output"] >= 4:
			continue
		var machine_position := cell_center(machine["cell"])
		var distance := position.distance_to(machine_position)
		if distance < best_distance:
			best_distance = distance
			target = machine_position
	return target


func _move_belts() -> void:
	var old_items: Array[int] = []
	for belt in belts:
		old_items.append(int(belt["item"]))
	var next_items := old_items.duplicate()
	for index in belts.size():
		if old_items[index] == 0:
			continue
		var destination: Vector2i = belts[index]["cell"] + belts[index]["dir"]
		var machine_index := _machine_at(destination)
		if machine_index >= 0 and machines[machine_index]["kind"] == "assembler":
			machines[machine_index]["input"] += 1
			next_items[index] = 0
			continue
		var belt_index := _belt_at(destination)
		if belt_index >= 0 and old_items[belt_index] == 0 and next_items[belt_index] == 0:
			next_items[index] = 0
			next_items[belt_index] = 1
	for index in belts.size():
		belts[index]["item"] = next_items[index]
	for machine in machines:
		if machine["kind"] != "processor" or machine["output"] == 0:
			continue
		var destination: Vector2i = machine["cell"] + machine["dir"]
		var belt_index := _belt_at(destination)
		if belt_index >= 0 and belts[belt_index]["dir"] == machine["dir"] and belts[belt_index]["item"] == 0:
			belts[belt_index]["item"] = 1
			machine["output"] -= 1


func _update_zombies(delta: float, player_position: Vector2) -> void:
	for zombie in zombies:
		zombie["cooldown"] = maxf(0.0, zombie["cooldown"] - delta)
		var position: Vector2 = zombie["position"]
		var target := zombie_target(position, player_position)
		if position.distance_to(player_position) < 24.0:
			if zombie["cooldown"] == 0.0 and player_hit_cooldown == 0.0:
				player_health = maxi(0, player_health - 1)
				zombie["cooldown"] = 1.0
				player_hit_cooldown = 0.8
			continue
		var machine_index := _machine_near(position, 28.0)
		if machine_index >= 0:
			if zombie["cooldown"] == 0.0:
				machines[machine_index]["health"] -= 1
				zombie["cooldown"] = 1.0
				if machines[machine_index]["health"] <= 0:
					machines.remove_at(machine_index)
			continue
		var next_position := position.move_toward(target, ZOMBIE_SPEED * delta)
		var barricade_index := _barricade_near(next_position, 24.0)
		if barricade_index >= 0:
			if zombie["cooldown"] == 0.0:
				barricades[barricade_index]["health"] -= 1
				zombie["cooldown"] = 1.0
				if barricades[barricade_index]["health"] <= 0:
					barricades.remove_at(barricade_index)
			continue
		zombie["position"] = next_position


func _spawn_zombie() -> void:
	var offset := float((spawn_count * 173) % (WORLD_SIZE.x - 160)) + 80.0
	var position := Vector2(offset, 16.0)
	match spawn_count % 4:
		1:
			position = Vector2(WORLD_SIZE.x - 16.0, fmod(offset, WORLD_SIZE.y - 32.0) + 16.0)
		2:
			position = Vector2(offset, WORLD_SIZE.y - 16.0)
		3:
			position = Vector2(16.0, fmod(offset, WORLD_SIZE.y - 32.0) + 16.0)
	zombies.append({"position": position, "health": 2, "cooldown": 0.0})
	spawn_count += 1


func _machine_at(cell: Vector2i) -> int:
	for index in machines.size():
		if machines[index]["cell"] == cell:
			return index
	return -1


func _belt_at(cell: Vector2i) -> int:
	for index in belts.size():
		if belts[index]["cell"] == cell:
			return index
	return -1


func _barricade_at(cell: Vector2i) -> int:
	for index in barricades.size():
		if barricades[index]["cell"] == cell:
			return index
	return -1


func _machine_near(position: Vector2, distance: float) -> int:
	for index in machines.size():
		if position.distance_to(cell_center(machines[index]["cell"])) < distance:
			return index
	return -1


func _barricade_near(position: Vector2, distance: float) -> int:
	for index in barricades.size():
		if position.distance_to(cell_center(barricades[index]["cell"])) < distance:
			return index
	return -1
