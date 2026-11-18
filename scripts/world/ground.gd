extends Node2D

const Iso = preload("res://scripts/world/isometric_projection.gd")
const Simulation = preload("res://scripts/core/simulation.gd")


func _draw() -> void:
	draw_rect(Rect2(-2200, -1100, 6600, 3900), Color("101a1b"))
	var columns := Simulation.WORLD_SIZE.x / Simulation.GRID_SIZE
	var rows := Simulation.WORLD_SIZE.y / Simulation.GRID_SIZE
	for y in rows:
		for x in columns:
			var center := Iso.world_to_screen(
				Vector2(x + 0.5, y + 0.5) * Simulation.GRID_SIZE
			)
			var grain := (x * 37 + y * 71 + x * y * 13) % 17
			var color := Color("2a3433") if grain < 8 else Color("303a38")
			if grain == 0 or grain == 13:
				color = Color("3c403a")
			if (x in range(7, 11) or y in range(7, 10)) and grain > 2:
				color = Color("393d3b")
			var corners := Iso.tile_points(center)
			draw_colored_polygon(corners, color)
			draw_polyline(PackedVector2Array([corners[0], corners[1], corners[2]]), Color("47504a", 0.38), 1.0)
			if grain == 1:
				draw_line(center + Vector2(-11, -2), center + Vector2(-2, 3), Color("171f20"), 1.0)
				draw_line(center + Vector2(-2, 3), center + Vector2(4, 2), Color("171f20"), 1.0)
			elif grain == 6:
				draw_line(center + Vector2(8, -3), center + Vector2(16, 1), Color("625b46", 0.8), 2.0)
			elif grain == 11:
				draw_circle(center + Vector2(-7, 0), 2.0, Color("445447"))
				draw_circle(center + Vector2(-5, -2), 1.0, Color("617657"))
