package main

import rl "vendor:raylib"

Facing :: enum {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}


Actor :: struct {
	position: rl.Vector2,
	facing:   Facing,
}

createActor :: proc(initialPosition: rl.Vector2) -> Actor {
	return {position = initialPosition}
}
