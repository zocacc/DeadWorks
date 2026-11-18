extends Node2D

const Simulation = preload("res://scripts/core/simulation.gd")
const Iso = preload("res://scripts/world/isometric_projection.gd")
const Ground = preload("res://scripts/world/ground.gd")
const MECHANIC_IDLE = preload("res://assets/characters/mechanic_idle.png")
const MECHANIC_WALK = preload("res://assets/characters/mechanic_walk.png")
const MECHANIC_ACTION = preload("res://assets/characters/mechanic_action.png")
const ZOMBIE_IDLE = preload("res://assets/characters/zombie_idle.png")
const PROCESSOR = preload("res://assets/machines/processor.png")

const PLAYER_SPEED := 185.0
const BUILD_KINDS := {KEY_1: "processor", KEY_2: "assembler", KEY_3: "belt", KEY_4: "barricade"}
const COST_HINT := {"processor": "3 sucatas", "assembler": "4 sucatas", "belt": "1 sucata", "barricade": "1 kit"}
const ZOMBIE_FRAME := [4, 7, 2, 1, 0, 5, 6, 5]

var simulation = Simulation.new()
var player_position := Vector2(640, 384)
var facing := Vector2.RIGHT
var facing_screen := Vector2(1, 0.5).normalized()
var selected_kind := ""
var build_direction := Vector2i.RIGHT
var attack_flash := 0.0
var action_time := 0.0
var action_kind := ""
var walk_time := 0.0
var is_walking := false
var hurt_time := 0.0
var last_health := 5
var notice := "Colete sucata para começar a fábrica."
var notice_time := 4.0
var camera: Camera2D
var hud: Label
var help: Label
var mode_label: Label
var notice_label: Label


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ground := Ground.new()
	ground.show_behind_parent = true
	add_child(ground)
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	var bar := ColorRect.new()
	bar.color = Color("121b1c", 0.88)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 112)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bar)
	hud = _make_label(layer, Vector2(16, 8), 19)
	help = _make_label(layer, Vector2(16, 38), 15)
	mode_label = _make_label(layer, Vector2(16, 63), 15)
	notice_label = _make_label(layer, Vector2(16, 87), 15)
	_update_hud()


func _make_label(parent: CanvasLayer, location: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = location
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e9e4d2"))
	parent.add_child(label)
	return label


func _process(delta: float) -> void:
	is_walking = false
	if simulation.player_health > 0:
		var screen_direction := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			screen_direction.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			screen_direction.y += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			screen_direction.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			screen_direction.x += 1.0
		if not screen_direction.is_zero_approx():
			move_for_screen_direction(screen_direction, delta)
		simulation.step(delta, player_position)
	if simulation.player_health < last_health:
		hurt_time = 0.36
	last_health = simulation.player_health
	camera.position = Iso.world_to_screen(player_position)
	attack_flash = maxf(0.0, attack_flash - delta)
	action_time = maxf(0.0, action_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	notice_time = maxf(0.0, notice_time - delta)
	_update_hud()
	queue_redraw()


func move_for_screen_direction(screen_direction: Vector2, delta: float) -> void:
	if simulation.player_health <= 0 or screen_direction.is_zero_approx():
		return
	screen_direction = screen_direction.normalized()
	facing_screen = screen_direction
	facing = Iso.screen_direction_to_world(screen_direction)
	var step := facing * PLAYER_SPEED * delta
	var next_x := player_position + Vector2(step.x, 0)
	if simulation.can_player_move(next_x):
		player_position = next_x
	var next_y := player_position + Vector2(0, step.y)
	if simulation.can_player_move(next_y):
		player_position = next_y
	is_walking = true
	walk_time += delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if simulation.player_health <= 0:
			if event.physical_keycode == KEY_ENTER:
				get_tree().reload_current_scene()
			return
		if BUILD_KINDS.has(event.physical_keycode):
			selected_kind = BUILD_KINDS[event.physical_keycode]
			_show_notice("Clique para construir. R gira; Esc cancela.")
			return
		match event.physical_keycode:
			KEY_R:
				build_direction = Vector2i(-build_direction.y, build_direction.x)
			KEY_ESCAPE:
				selected_kind = ""
			KEY_E:
				_interact()
			KEY_SPACE:
				simulation.attack(player_position, facing)
				attack_flash = 0.22
				action_time = 0.24
				action_kind = "attack"
	elif event is InputEventMouseButton and event.pressed and simulation.player_health > 0:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			selected_kind = ""
		elif event.button_index == MOUSE_BUTTON_LEFT and selected_kind != "":
			if place_at_screen(get_global_mouse_position()):
				_show_notice("Construção concluída.")
			else:
				_show_notice("Posição ocupada, próxima demais ou recursos insuficientes.")


func cell_from_screen(screen: Vector2) -> Vector2i:
	return simulation.cell_at(Iso.screen_to_world(screen))


func place_at_screen(screen: Vector2) -> bool:
	if selected_kind == "" or simulation.player_health <= 0:
		return false
	var cell := cell_from_screen(screen)
	if player_position.distance_to(simulation.cell_center(cell)) < 30.0:
		return false
	return simulation.place(selected_kind, cell, build_direction)


func _interact() -> void:
	if simulation.take_kits(player_position):
		_show_notice("Kits retirados da montadora.")
	elif simulation.collect_scrap(player_position):
		_show_notice("Sucata coletada.")
	elif simulation.load_processor(player_position):
		_show_notice("Processador abastecido.")
	else:
		_show_notice("Aproxime-se de sucata, processador ou montadora pronta.")
	action_time = 0.34
	action_kind = "collect"


func _show_notice(message: String) -> void:
	notice = message
	notice_time = 2.5


func _update_hud() -> void:
	hud.text = "DEADWORKS  |  VIDA %d  |  SUCATA %d  |  KITS %d  |  ABATES %d  |  MÁQUINAS %d" % [simulation.player_health, simulation.scrap, simulation.kits, simulation.kills, simulation.active_machine_count()]
	help.text = "WASD mover na tela  •  E interagir  •  Espaço atacar  •  1 processador  •  2 montadora  •  3 esteira  •  4 barricada"
	mode_label.text = "Construção: %s (%s)  •  R girar  •  clique colocar  •  direito/Esc cancelar" % [selected_kind if selected_kind != "" else "nenhuma", COST_HINT.get(selected_kind, "-")]
	notice_label.text = notice if notice_time > 0.0 else ""
	if simulation.player_health <= 0:
		mode_label.text = "Fim de jogo. Enter reinicia a arena."
		notice_label.text = ""


func _draw() -> void:
	var renderables: Array[Dictionary] = []
	for pile in simulation.piles:
		if pile["amount"] > 0:
			_add_renderable(renderables, "pile", pile["position"], pile)
	for belt in simulation.belts:
		_add_renderable(renderables, "belt", simulation.cell_center(belt["cell"]), belt)
	for machine in simulation.machines:
		_add_renderable(renderables, "machine", simulation.cell_center(machine["cell"]), machine)
	for barricade in simulation.barricades:
		_add_renderable(renderables, "barricade", simulation.cell_center(barricade["cell"]), barricade)
	for zombie in simulation.zombies:
		_add_renderable(renderables, "zombie", zombie["position"], zombie)
	_add_renderable(renderables, "player", player_position, {})
	renderables.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["depth"] < b["depth"])
	for item in renderables:
		var position: Vector2 = item["screen"]
		match item["kind"]:
			"pile": _draw_pile(position)
			"belt": _draw_belt(position, item["data"])
			"machine": _draw_machine(position, item["data"])
			"barricade": _draw_barricade(position, item["data"])
			"zombie": _draw_zombie(position, item["data"])
			"player": _draw_player(position)
	if selected_kind != "" and simulation.player_health > 0:
		var cell := cell_from_screen(get_global_mouse_position())
		if simulation.in_bounds(cell):
			var center := Iso.world_to_screen(simulation.cell_center(cell))
			var valid := not simulation.occupied(cell) and player_position.distance_to(simulation.cell_center(cell)) >= 30.0
			var color := Color(0.35, 0.88, 0.53, 0.42) if valid else Color(0.95, 0.30, 0.24, 0.42)
			var corners := Iso.tile_points(center)
			draw_colored_polygon(corners, color)
			draw_polyline(PackedVector2Array([corners[0], corners[1], corners[2], corners[3], corners[0]]), color.lightened(0.3), 2.0)
			if selected_kind == "belt" or selected_kind == "processor":
				_draw_direction_arrow(center, build_direction, Color("e7e4c4"))


func _add_renderable(items: Array[Dictionary], kind: String, world: Vector2, data: Dictionary) -> void:
	var screen := Iso.world_to_screen(world)
	items.append({"kind": kind, "screen": screen, "depth": screen.y, "data": data})


func _draw_shadow(center: Vector2, width: float = 23.0) -> void:
	var points := PackedVector2Array()
	for index in 17:
		var angle := TAU * index / 16.0
		points.append(center + Vector2(cos(angle) * width, sin(angle) * width * 0.30))
	draw_colored_polygon(points, Color(0.02, 0.04, 0.04, 0.48))


func _draw_pile(center: Vector2) -> void:
	_draw_shadow(center)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-24, -5), center + Vector2(2, -12), center + Vector2(22, -1), center + Vector2(7, 7)]), Color("83553c"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-18, -14), center + Vector2(13, -19), center + Vector2(20, -12), center + Vector2(-12, -7)]), Color("af7451"))
	draw_line(center + Vector2(-13, -17), center + Vector2(15, -20), Color("c58e62"), 2.0)
	draw_circle(center + Vector2(5, -5), 6.0, Color("4b5551"))
	draw_circle(center + Vector2(5, -5), 2.0, Color("a17b54"))
	draw_line(center + Vector2(-20, 1), center + Vector2(-5, -10), Color("68716a"), 3.0)


func _draw_belt(center: Vector2, belt: Dictionary) -> void:
	_draw_shadow(center, 27.0)
	var points := Iso.tile_points(center)
	draw_colored_polygon(points, Color("252d31"))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color("84908b"), 2.0)
	var direction: Vector2 = Iso.world_to_screen(Vector2(belt["dir"])).normalized()
	var side := Vector2(-direction.y, direction.x)
	for offset in [-10.0, -2.0, 6.0]:
		var position: Vector2 = center + direction * offset
		draw_line(position - side * 7.0, position + side * 7.0, Color("586166"), 2.0)
	_draw_direction_arrow(center, belt["dir"], Color("d0b678"))
	if belt["item"] > 0:
		draw_circle(center + Vector2(0, -7), 5.0, Color("e8b864"))
		draw_circle(center + Vector2(-1, -8), 2.0, Color("fff0bb"))


func _draw_machine(center: Vector2, machine: Dictionary) -> void:
	_draw_shadow(center, 31.0)
	if machine["kind"] == "processor":
		draw_texture_rect(PROCESSOR, Rect2(center + Vector2(-33, -68), Vector2(66, 68)), false)
		_draw_direction_arrow(center + Vector2(0, -28), machine["dir"], Color("e5e1bd"))
	else:
		var top := center + Vector2(0, -39)
		draw_colored_polygon(PackedVector2Array([top + Vector2(-28, 2), top + Vector2(0, -10), top + Vector2(28, 2), top + Vector2(0, 14)]), Color("a7833e"))
		draw_colored_polygon(PackedVector2Array([top + Vector2(-28, 2), top + Vector2(0, 14), center + Vector2(0, 4), center + Vector2(-28, -10)]), Color("655236"))
		draw_colored_polygon(PackedVector2Array([top + Vector2(0, 14), top + Vector2(28, 2), center + Vector2(28, -10), center + Vector2(0, 4)]), Color("4b4234"))
		for gear_x in [-11.0, 11.0]:
			draw_circle(center + Vector2(gear_x, -30), 7.0, Color("424c4a"))
			draw_circle(center + Vector2(gear_x, -30), 3.0, Color("d3b46e"))
		draw_rect(Rect2(center + Vector2(-24, -17), Vector2(48, 4)), Color("d6a63d"))
		draw_rect(Rect2(center + Vector2(-23, -8), Vector2(46, 3)), Color("313a37"))
	if machine["input"] > 0 and machine["output"] < 4:
		_draw_noise_ring(simulation.cell_center(machine["cell"]))
		draw_circle(center + Vector2(17, -30), 3.0, Color("da9b58"))
	draw_rect(Rect2(center + Vector2(-20, -72), Vector2(40, 3)), Color("292e2a"))
	draw_rect(Rect2(center + Vector2(-20, -72), Vector2(40.0 * float(machine["health"]) / 8.0, 3)), Color("9abd75"))
	if machine["input"] > 0:
		draw_rect(Rect2(center + Vector2(-20, -68), Vector2(40.0 * float(machine["progress"]) / 3.0, 2)), Color("e5b85c"))
	if machine["output"] > 0:
		draw_circle(center + Vector2(23, -5), 5.0, Color("efc16b"))


func _draw_barricade(center: Vector2, barricade: Dictionary) -> void:
	_draw_shadow(center, 28.0)
	for level in 3:
		var y := -13.0 - level * 8.0
		draw_colored_polygon(PackedVector2Array([center + Vector2(-27, y), center + Vector2(25, y - 2), center + Vector2(25, y + 5), center + Vector2(-27, y + 7)]), Color("7a543c") if level % 2 == 0 else Color("946749"))
		draw_line(center + Vector2(-25, y + 1), center + Vector2(23, y - 1), Color("c08d61"), 1.0)
	for x in [-19.0, 17.0]:
		draw_rect(Rect2(center + Vector2(x, -39), Vector2(5, 37)), Color("454b47"))
		draw_circle(center + Vector2(x + 2, -21), 1.5, Color("c1b391"))
	draw_rect(Rect2(center + Vector2(-20, -47), Vector2(40.0 * float(barricade["health"]) / 6.0, 3)), Color("a2c06e"))


func _draw_zombie(center: Vector2, zombie: Dictionary) -> void:
	_draw_shadow(center, 19.0)
	var target := simulation.zombie_target(zombie["position"], player_position)
	var look := Iso.world_to_screen(target - zombie["position"])
	var frame: int = ZOMBIE_FRAME[Iso.facing_index(look)]
	var bob := sin(float(Time.get_ticks_msec()) * 0.005 + center.x * 0.1) * 1.2
	_draw_character_frame(ZOMBIE_IDLE, frame, center + Vector2(0, bob), Color.WHITE)
	if zombie["health"] == 1:
		draw_circle(center + Vector2(0, -69), 3.0, Color("b45b51"))


func _draw_player(center: Vector2) -> void:
	_draw_shadow(center, 20.0)
	var texture: Texture2D = MECHANIC_IDLE
	if is_walking and fmod(walk_time, 0.32) < 0.16:
		texture = MECHANIC_WALK
	if action_time > 0.0:
		texture = MECHANIC_ACTION if action_time > 0.12 else MECHANIC_IDLE
	var tint := Color.WHITE
	if hurt_time > 0.0 and fmod(hurt_time, 0.12) < 0.06:
		tint = Color("ff756c")
	var bob := sin(walk_time * 18.0) * 1.5 if is_walking else sin(float(Time.get_ticks_msec()) * 0.002) * 0.5
	_draw_character_frame(texture, Iso.facing_index(facing_screen), center + Vector2(0, bob), tint)
	if attack_flash > 0.0:
		draw_line(center + Vector2(0, -36), center + Vector2(0, -36) + facing_screen * 32.0, Color("e9dca6", attack_flash * 4.0), 3.0)
	elif action_time > 0.0 and action_kind == "collect":
		draw_circle(center + facing_screen * 24.0 + Vector2(0, -24), 3.0, Color("f1cf87"))


func _draw_character_frame(texture: Texture2D, index: int, center: Vector2, tint: Color) -> void:
	var cell := Vector2(texture.get_width() / 4.0, texture.get_height() / 2.0)
	var source := Rect2(Vector2((index % 4) * cell.x + 60.0, (index / 4) * cell.y), Vector2(cell.x - 60.0, cell.y))
	draw_texture_rect_region(texture, Rect2(center + Vector2(-40, -82), Vector2(80, 86)), source, tint)


func _draw_direction_arrow(center: Vector2, direction: Vector2i, color: Color) -> void:
	var vector := Iso.world_to_screen(Vector2(direction)).normalized()
	var end := center + vector * 13.0
	var side := Vector2(-vector.y, vector.x)
	draw_line(center - vector * 9.0, end, color, 2.0)
	draw_line(end, end - vector * 6.0 + side * 4.0, color, 2.0)
	draw_line(end, end - vector * 6.0 - side * 4.0, color, 2.0)


func _draw_noise_ring(world_center: Vector2) -> void:
	var ring := PackedVector2Array()
	for index in 49:
		var angle := TAU * index / 48.0
		ring.append(Iso.world_to_screen(world_center + Vector2(cos(angle), sin(angle)) * Simulation.NOISE_RADIUS))
	draw_polyline(ring, Color(0.94, 0.53, 0.25, 0.18), 2.0)
