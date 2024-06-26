package main

import "core:fmt"
import "core:strings"
import "shared"
import rl "vendor:raylib"

PlayerInventory :: struct {
	using rect: rl.Rectangle,
	show:       bool,
	draw:       proc(inv: ^PlayerInventory),
	move:       proc(inv: ^PlayerInventory, position: shared.IVector2),
}
createPlayerInventory :: proc(rect: rl.Rectangle) -> PlayerInventory {
	return {rect = rect, draw = drawInventory, move = moveInventory}
}
moveInventory :: proc(inv: ^PlayerInventory, position: shared.IVector2) {
	using inv
	x = position.x
	y = position.y
}
drawInventory :: proc(inv: ^PlayerInventory) {
	using inv
	if show {
		rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), rl.ORANGE)
	}
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
	invetoryMenu:    PlayerInventory,
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
	inventory := createPlayerInventory({initialPosition.x, initialPosition.y, 200, 200})

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
		invetoryMenu = inventory,
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

	if userInput.tabMenuPressed {
		player.invetoryMenu.show = !player.invetoryMenu.show
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

	invetoryMenu.move(&invetoryMenu, position)
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
	player.invetoryMenu->draw()
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
