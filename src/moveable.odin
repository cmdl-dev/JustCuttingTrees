package main

import rl "vendor:raylib"

Moveable :: struct {
	velocity:  i32,
	direction: rl.Vector2,
	move:      proc(actor: ^Actor, newPosition: rl.Vector2),
}
createMoveable :: proc(velocity: i32) -> Moveable {
	return {velocity = velocity, move = moveActor}
}

moveActor :: proc(actor: ^Actor, deltaPosition: rl.Vector2) {
	using actor

	position.x += deltaPosition.x
	position.y += deltaPosition.y
}
