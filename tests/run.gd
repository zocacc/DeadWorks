extends SceneTree

const Simulation = preload("res://scripts/core/simulation.gd")
const Iso = preload("res://scripts/world/isometric_projection.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1


func _run() -> void:
	var sim = Simulation.new()
	var pile_position: Vector2 = sim.piles[0]["position"]
	_check(not sim.place("processor", Vector2i(30, 20)), "máquina exige sucata")
	var collected_all := true
	for _i in 12:
		collected_all = sim.collect_scrap(pile_position) and collected_all
	_check(collected_all, "coleta 12 sucatas disponíveis")
	_check(sim.scrap == 12 and not sim.collect_scrap(pile_position), "pilha esgotada interrompe coleta")
	_check(sim.place("processor", Vector2i(30, 20)), "constrói processador")
	_check(sim.place("belt", Vector2i(31, 20)), "constrói primeira esteira")
	_check(sim.place("belt", Vector2i(32, 20)), "constrói segunda esteira")
	_check(sim.place("assembler", Vector2i(33, 20)), "constrói montadora")
	_check(not sim.place("belt", Vector2i(31, 20)), "grade impede sobreposição")
	var processor_position := sim.cell_center(Vector2i(30, 20))
	var assembler_position := sim.cell_center(Vector2i(33, 20))
	_check(sim.load_processor(processor_position) and sim.load_processor(processor_position), "abastece processador manualmente")
	_check(sim.scrap == 1 and sim.active_machine_count() == 1, "entrada ativa ruído e consome sucata")
	_check(sim.zombie_target(processor_position + Vector2(200, 0), Vector2(1800, 1000)) == processor_position, "ruído atrai zumbi distante do jogador")
	sim.step(2.9, Vector2(1800, 1000))
	_check(sim.machines[0]["output"] == 0, "produção respeita duração")
	sim.step(0.1, Vector2(1800, 1000))
	_check(sim.machines[0]["output"] == 1, "processador conclui ciclo")
	sim.step(1.2, Vector2(1800, 1000))
	_check(sim.machines[1]["input"] == 1, "material percorre esteiras e entra na montadora")
	sim.step(3.0, Vector2(1800, 1000))
	sim.step(3.0, Vector2(1800, 1000))
	_check(sim.machines[1]["output"] == 2, "cadeia produz dois kits")
	_check(sim.machines[0]["output"] == 0 and sim.machines[1]["input"] == 0 and sim.belts[0]["item"] == 0 and sim.belts[1]["item"] == 0, "cadeia não duplica nem perde material")
	_check(sim.take_kits(assembler_position) and sim.kits == 2, "jogador retira kits")
	_check(sim.place("barricade", Vector2i(34, 20)) and sim.kits == 1, "kit vira barricada")
	_check(not sim.can_player_move(sim.cell_center(Vector2i(34, 20))), "barricada bloqueia passagem")
	_check(sim.active_machine_count() == 0, "máquinas ociosas ficam silenciosas")
	_check(sim.load_processor(processor_position) and not sim.load_processor(processor_position), "processador não aceita entrada sem sucata")

	var disconnected = Simulation.new()
	disconnected.scrap = 10
	disconnected.place("processor", Vector2i(10, 10))
	disconnected.place("assembler", Vector2i(13, 10))
	disconnected.load_processor(disconnected.cell_center(Vector2i(10, 10)))
	disconnected.step(4.0, Vector2(1800, 1000))
	_check(disconnected.machines[0]["output"] == 1 and disconnected.machines[1]["input"] == 0, "sem esteira, saída aguarda conexão")
	disconnected.scrap = 2
	disconnected.place("belt", Vector2i(11, 10))
	disconnected.place("belt", Vector2i(12, 10))
	disconnected.step(1.2, Vector2(1800, 1000))
	_check(disconnected.machines[1]["input"] == 1, "reconexão libera material retido")

	var defense = Simulation.new()
	defense.kits = 1
	defense.place("barricade", Vector2i(20, 20))
	var barrier_position := defense.cell_center(Vector2i(20, 20))
	defense.zombies.append({"position": barrier_position - Vector2(40, 0), "health": 2, "cooldown": 0.0})
	defense.step(1.0, barrier_position + Vector2(120, 0))
	_check(defense.barricades[0]["health"] == 5, "zumbi ataca barricada que bloqueia rota")
	_check(defense.zombies[0]["position"].x < barrier_position.x, "barricada segura zumbi enquanto resiste")
	defense.step(6.0, barrier_position + Vector2(120, 0))
	_check(defense.barricades.is_empty(), "dano contínuo destrói barricada")
	var fighter = Simulation.new()
	var player := Vector2(1000, 1000)
	fighter.zombies.append({"position": player + Vector2(40, 0), "health": 2, "cooldown": 0.0})
	_check(fighter.attack(player, Vector2.RIGHT) == 1, "ataque corpo a corpo acerta zumbi à frente")
	_check(fighter.attack(player, Vector2.RIGHT) == 0, "ataque respeita intervalo")
	fighter.step(0.45, player)
	_check(fighter.attack(player, Vector2.RIGHT) == 1 and fighter.kills == 1, "segundo golpe elimina zumbi")

	var hunted = Simulation.new()
	hunted.scrap = 4
	hunted.place("processor", Vector2i(20, 20))
	hunted.load_processor(hunted.cell_center(Vector2i(20, 20)))
	hunted.zombies.append({"position": hunted.cell_center(Vector2i(20, 20)) + Vector2(27, 0), "health": 2, "cooldown": 0.0})
	hunted.step(0.1, Vector2(1800, 1000))
	_check(hunted.machines[0]["health"] == 7, "zumbi danifica máquina ruidosa")
	hunted.step(8.0, Vector2(1800, 1000))
	_check(hunted.machines.is_empty(), "zumbi pode destruir máquina")
	var bitten = Simulation.new()
	bitten.zombies.append({"position": player + Vector2(20, 0), "health": 2, "cooldown": 0.0})
	bitten.zombies.append({"position": player + Vector2(0, 20), "health": 2, "cooldown": 0.0})
	bitten.step(0.1, player)
	_check(bitten.player_health == 4, "mordidas simultâneas causam um dano e dão breve proteção")
	var quiet = Simulation.new()
	quiet.step(10.0, Vector2(1800, 1000))
	var noisy = Simulation.new()
	noisy.scrap = 7
	noisy.place("processor", Vector2i(20, 20))
	for _i in 4:
		noisy.load_processor(noisy.cell_center(Vector2i(20, 20)))
	noisy.step(10.0, Vector2(1800, 1000))
	_check(noisy.zombies.size() > quiet.zombies.size(), "produção ruidosa acelera surgimento de zumbis")

	var renewable = Simulation.new()
	for _i in 12:
		renewable.collect_scrap(renewable.piles[0]["position"])
	renewable.step(30.0, Vector2(1800, 1000))
	_check(renewable.piles[0]["amount"] == 12, "sucata retorna ao mapa para sandbox contínuo")
	var main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for world in [Vector2.ZERO, Vector2(16, 16), Vector2(640, 384), Vector2(1999, 1100)]:
		_check(Iso.screen_to_world(Iso.world_to_screen(world)).distance_to(world) < 0.001, "projeção isométrica preserva coordenada do mundo")
	for screen_direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var world_direction := Iso.screen_direction_to_world(screen_direction)
		_check(Iso.world_to_screen(world_direction).normalized().dot(screen_direction) > 0.999, "WASD segue direção vista na tela")
	_check(Iso.facing_index(Vector2.UP) == 0 and Iso.facing_index(Vector2.RIGHT) == 2 and Iso.facing_index(Vector2.DOWN) == 4 and Iso.facing_index(Vector2.LEFT) == 6, "oito orientações do personagem seguem a tela")
	var starting_screen := Iso.world_to_screen(main.player_position)
	main.move_for_screen_direction(Vector2.UP, 0.1)
	_check(Iso.world_to_screen(main.player_position).y < starting_screen.y and absf(Iso.world_to_screen(main.player_position).x - starting_screen.x) < 0.001, "W move para cima na tela")
	main.player_position = Vector2(640, 384)
	var test_cell := Vector2i(25, 15)
	var test_screen := Iso.world_to_screen(main.simulation.cell_center(test_cell))
	_check(main.cell_from_screen(test_screen) == test_cell, "mouse seleciona a célula isométrica correta")
	main.simulation.scrap = 1
	main.selected_kind = "belt"
	_check(main.place_at_screen(test_screen) and main.simulation.belts[0]["cell"] == test_cell, "clique constrói na célula selecionada")
	_check(not main.place_at_screen(test_screen), "clique não sobrepõe construção")
	_check(not main.place_at_screen(Iso.world_to_screen(main.simulation.cell_center(main.simulation.cell_at(main.player_position)))), "clique não constrói sob o jogador")
	var mechanic_image: Image = load("res://assets/characters/mechanic_idle.png").get_image()
	var zombie_image: Image = load("res://assets/characters/zombie_idle.png").get_image()
	var processor_image: Image = load("res://assets/machines/processor.png").get_image()
	_check(mechanic_image.get_pixel(0, 0).a < 0.01 and zombie_image.get_pixel(0, 0).a < 0.01 and processor_image.get_pixel(0, 0).a < 0.01, "sprites de personagem, zumbi e máquina têm fundo transparente")
	main.player_position = main.simulation.piles[0]["position"]
	var interact := InputEventKey.new()
	interact.pressed = true
	interact.physical_keycode = KEY_E
	main._unhandled_input(interact)
	_check(main.simulation.scrap == 1, "tecla E da cena coleta sucata")
	var select_belt := InputEventKey.new()
	select_belt.pressed = true
	select_belt.physical_keycode = KEY_3
	main._unhandled_input(select_belt)
	_check(main.selected_kind == "belt", "tecla 3 seleciona esteira")
	main.free()

	print("Resultado: %d falha(s)" % failures)
	quit(1 if failures > 0 else 0)
