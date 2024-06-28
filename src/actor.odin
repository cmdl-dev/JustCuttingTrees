package main

import "shared"

Facing :: enum {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}


Actor :: struct {
	position: shared.IVector2,
	facing:   Facing,
}

createActor :: proc(initialPosition: shared.IVector2) -> Actor {
	return {position = initialPosition}
}
