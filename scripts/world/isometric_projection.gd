extends RefCounted
class_name IsometricProjection

# A 32-unit simulation cell occupies a 64 x 32 diamond on screen.
const WORLD_UNITS_PER_CELL := 32.0
const TILE_WIDTH := 64.0
const TILE_HEIGHT := 32.0


static func world_to_screen(world: Vector2) -> Vector2:
	return Vector2(
		(world.x - world.y) * TILE_WIDTH / (2.0 * WORLD_UNITS_PER_CELL),
		(world.x + world.y) * TILE_HEIGHT / (2.0 * WORLD_UNITS_PER_CELL)
	)


static func screen_to_world(screen: Vector2) -> Vector2:
	return Vector2(
		(screen.x / (TILE_WIDTH / 2.0) + screen.y / (TILE_HEIGHT / 2.0)) * WORLD_UNITS_PER_CELL / 2.0,
		(screen.y / (TILE_HEIGHT / 2.0) - screen.x / (TILE_WIDTH / 2.0)) * WORLD_UNITS_PER_CELL / 2.0
	)


static func screen_direction_to_world(direction: Vector2) -> Vector2:
	return screen_to_world(direction).normalized()


static func facing_index(direction: Vector2) -> int:
	if direction.is_zero_approx():
		return 4
	return posmod(roundi(atan2(direction.x, -direction.y) / (PI / 4.0)), 8)


static func tile_points(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0, -TILE_HEIGHT / 2.0),
		center + Vector2(TILE_WIDTH / 2.0, 0),
		center + Vector2(0, TILE_HEIGHT / 2.0),
		center + Vector2(-TILE_WIDTH / 2.0, 0)
	])
