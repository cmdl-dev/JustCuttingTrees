package main

import "shared"

Moveable :: struct {
	velocity:  i32,
	direction: shared.IVector2,
	move:      proc(actor: ^Actor, newPosition: shared.IVector2),
}
createMoveable :: proc(velocity: i32) -> Moveable {
	return {velocity = velocity, move = moveActor}
}

moveActor :: proc(actor: ^Actor, deltaPosition: shared.IVector2) {
	using actor

	position.x += deltaPosition.x
	position.y += deltaPosition.y
}
