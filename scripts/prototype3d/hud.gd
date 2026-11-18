extends CanvasLayer
class_name CombatHUD

var player: PrototypePlayer
var spawner: ZombieSpawner
var health_bar: ProgressBar
var health_label: Label
var kills_label: Label
var hint_label: Label
var death_label: Label


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(290, 102)
	add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 3)
	panel.add_child(layout)
	health_label = Label.new()
	layout.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(260, 12)
	layout.add_child(health_bar)
	kills_label = Label.new()
	layout.add_child(kills_label)
	hint_label = Label.new()
	hint_label.text = "WASD mover  |  Shift correr  |  Espaço esquivar\nMouse mirar  |  Clique atirar  |  Scroll zoom  |  Tab câmera  |  R reiniciar"
	hint_label.position = Vector2(16, 130)
	add_child(hint_label)
	death_label = Label.new()
	death_label.text = "VOCÊ MORREU — pressione R para reiniciar"
	death_label.add_theme_font_size_override("font_size", 28)
	death_label.visible = false
	add_child(death_label)
	_update_state()


func _process(_delta: float) -> void:
	_update_state()
	if death_label.visible:
		death_label.position = get_viewport().get_visible_rect().size * 0.5 - Vector2(240, 20)


func _update_state() -> void:
	if health_bar == null:
		return
	if is_instance_valid(player):
		health_bar.max_value = player.max_health
		health_bar.value = player.health
		health_label.text = "VIDA  %d / %d" % [int(player.health), int(player.max_health)]
		death_label.visible = player.health <= 0.0
	if is_instance_valid(spawner):
		kills_label.text = "ABATES  %d     ZUMBIS  %d" % [spawner.kills, spawner.alive_count()]
