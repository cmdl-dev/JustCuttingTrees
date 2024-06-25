package main

import "core:fmt"
import "shared"
import rl "vendor:raylib"

Moveable :: struct {
	velocity:  i32,
	direction: shared.IVector2,
	move:      proc(actor: ^Actor, newPosition: shared.IVector2),
}

createMoveable :: proc() -> Moveable {
	return {move = moveActor, velocity = 200}
}
moveActor :: proc(actor: ^Actor, deltaPosition: shared.IVector2) {
	using actor

	position.x += deltaPosition.x
	position.y += deltaPosition.y
}
PlayerState :: enum {
	NONE,
	INTERACTION,
}

Player :: struct {
	using moveable:  Moveable,
	using actor:     Actor,
	sprite:          Sprite,
	interactionRect: Area2D,
	state:           PlayerState,
	treeStorage:     [dynamic]TreeReward,
	addReward:       proc(player: ^Player, reward: [dynamic]TreeReward),
	playerInput:     proc(player: ^Player, userInput: UserInput),
	playerUpdate:    proc(player: ^Player, delta: f32),
	playerDraw:      proc(player: ^Player),
}


createPlayer :: proc(initialPosition: shared.IVector2) -> Player {

	actor := createActor(initialPosition)
	moveable := createMoveable()

	sprite := createSprite("assets/Phoenix.png", {50, 50})
	sprite->setScale(2)


	interactionRect := createArea2D(
		AreaType.INTERACTION,
		{initialPosition.x, initialPosition.y, f32(sprite->getWidth()), f32(sprite->getHeight())},
	)

	return Player {
		actor = actor,
		moveable = moveable,
		sprite = sprite,
		interactionRect = interactionRect,
		addReward = playerAddReward,
		playerDraw = playerDraw,
		playerUpdate = playerUpdate,
		playerInput = playerInput,
	}
}
playerAddReward :: proc(player: ^Player, rewards: [dynamic]TreeReward) {
	fmt.printfln("something")
	append(&player.treeStorage, ..rewards[:])
}

playerInput :: proc(player: ^Player, userInput: UserInput) {
	player.direction = userInput.direction
	if (userInput.justInteracted) {
		player.state = PlayerState.INTERACTION
	} else {
		player.state = PlayerState.NONE
	}
}

playerUpdate :: proc(player: ^Player, delta: f32) {
	using player

	calculatedDelta := shared.IVector2 {
		delta * f32(velocity) * direction.x,
		delta * f32(velocity) * direction.y,
	}

	moveActor(player, calculatedDelta)
	sprite.position = position
	interactionRect->update(position)


}

playerDraw :: proc(player: ^Player) {
	using player

	sprite->draw()
	interactionRect->draw()
}
