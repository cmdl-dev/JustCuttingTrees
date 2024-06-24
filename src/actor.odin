package main

import "shared"

Facing :: enum {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}

MovementState :: enum {
	IDLE,
	WALKING,
}

Actor :: struct {
	position:      shared.IVector2,
	facing:        Facing,
	movementState: MovementState,
}

createActor :: proc(initialPosition: shared.IVector2) -> Actor {
	return {position = initialPosition}
}
