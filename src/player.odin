package main

import "core:fmt"
import "core:strings"
import "shared"
import rl "vendor:raylib"

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
	storeLogs:       proc(player: ^Player, storage: ^StorageBox),
	addReward:       proc(player: ^Player, reward: [dynamic]TreeReward),
	playerInput:     proc(player: ^Player, userInput: UserInput),
	playerUpdate:    proc(player: ^Player, delta: f32),
	playerDraw:      proc(player: ^Player),
}


createPlayer :: proc(initialPosition: shared.IVector2) -> Player {

	fileName := cstring("assets/Phoenix.png")
	actor := createActor(initialPosition)
	moveable := createMoveable(200)

	sprite := createSprite(fileName, {50, 50})
	sprite->setScale(2)


	interactionRect := createArea2D(
		AreaType.INTERACTION,
		{initialPosition.x, initialPosition.y, f32(sprite->getWidth()), f32(sprite->getHeight())},
	)

	return Player {
		actor = actor,
		moveable = moveable,
		sprite = sprite,
		storeLogs = storeLogs,
		interactionRect = interactionRect,
		addReward = playerAddReward,
		playerDraw = playerDraw,
		playerUpdate = playerUpdate,
		playerInput = playerInput,
	}
}
playerAddReward :: proc(player: ^Player, rewards: [dynamic]TreeReward) {
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

	player.moveable.move(player, calculatedDelta)
	sprite.position = position
	interactionRect->update(position)
}

getPlayerTotalScore :: proc(player: ^Player) -> (accumulator: i32) {
	using player

	for reward in treeStorage {
		accumulator += reward.info.value
	}
	return
}

drawScore :: proc(player: ^Player) {
	using player

	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	text := fmt.sbprintf(&b, "%d", getPlayerTotalScore(player))
	cText := strings.to_cstring(&b)

	textWidth := rl.MeasureText(cText, 32)
	padding := i32(10)
	rl.DrawText(
		cText,
		i32(position.x) - textWidth / 2 + (player.sprite->getWidth() / 2),
		i32(position.y) - textWidth - padding,
		32,
		rl.BLACK,
	)

}
playerDraw :: proc(player: ^Player) {
	using player

	sprite->draw()
	interactionRect->draw()
	drawScore(player)
}

storeLogs :: proc(player: ^Player, box: ^StorageBox) {
	using player
	// 
	// storage:        map[LogType]i32,
	fmt.println("Adding logs into storage")
	for log in treeStorage {
		box.storage[log.logType] += 1
	}

	clear(&player.treeStorage)
}
