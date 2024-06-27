package main

import "core:fmt"
import "core:strings"
import "shared"
import rl "vendor:raylib"


PlayerInventory :: struct {
	using menu:    Menu,
	storage:       [dynamic]TreeReward,
	drawInventory: proc(pInv: ^PlayerInventory),
}

createPlayerInventory :: proc(rect: rl.Rectangle) -> PlayerInventory {
	return {
		rect = rect,
		title = "Inventory",
		drawMenu = drawMenu,
		drawInventory = drawContents,
		move = moveInventory,
	}
}
moveInventory :: proc(inv: ^Menu, position: shared.IVector2) {
	using inv
	x = position.x
	y = position.y
}
drawContents :: proc(pInv: ^PlayerInventory) {
	using pInv
	if !show {
		return
	}

	pInv->drawMenu()

	padding := i32(10)
	centerPosX := x + (width / 2)
	bottomPosY := y + height

	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	text := fmt.sbprintf(&b, "Score: %d", getPlayerTotalScore(pInv))
	cText := strings.to_cstring(&b)

	textWidth := rl.MeasureText(cText, 12)

	rl.DrawText(cText, i32(centerPosX) - (textWidth / 2), i32(bottomPosY) - 12, 12, rl.BLACK)
}

drawMenu :: proc(inv: ^Menu) {
	using inv

	textWidth := rl.MeasureText(title, 24)
	centerPosX := x + (width / 2)

	rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), rl.ORANGE) // rl.DrawRectangle(i32(x - width), i32(y - height), i32(width), i32(height), rl.ORANGE)
	rl.DrawText(title, i32(centerPosX) - (textWidth / 2), i32(y + 5), 24, rl.BLACK)
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
	inventory:       PlayerInventory,
	state:           PlayerState,
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
		inventory = inventory,
		addReward = playerAddReward,
		playerDraw = playerDraw,
		playerUpdate = playerUpdate,
		playerInput = playerInput,
	}
}
playerAddReward :: proc(player: ^Player, rewards: [dynamic]TreeReward) {
	append(&player.inventory.storage, ..rewards[:])
}

playerInput :: proc(player: ^Player, userInput: UserInput) {
	player.direction = userInput.direction
	if (userInput.justInteracted) {
		player.state = PlayerState.INTERACTION
	} else {
		player.state = PlayerState.NONE
	}

	if userInput.tabMenuPressed {
		player.inventory.show = !player.inventory.show
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

getPlayerTotalScore :: proc(pInv: ^PlayerInventory) -> (accumulator: i32) {
	using pInv

	for reward in storage {
		accumulator += reward.info.value
	}
	return
}

// drawScore :: proc(player: ^Player) {
// 	using player

// 	b := strings.builder_make()
// 	defer strings.builder_destroy(&b)

// 	text := fmt.sbprintf(&b, "%d", getPlayerTotalScore(player))
// 	cText := strings.to_cstring(&b)

// 	textWidth := rl.MeasureText(cText, 32)
// 	padding := i32(10)

// 	rl.DrawText(
// 		cText,
// 		i32(position.x) - textWidth / 2 + (player.sprite->getWidth() / 2),
// 		i32(position.y) - textWidth - padding,
// 		32,
// 		rl.BLACK,
// 	)

// }
playerDraw :: proc(player: ^Player) {
	using player

	sprite->draw()
	interactionRect->draw()
	// drawScore(player)
	player.inventory->drawInventory()
}

storeLogs :: proc(player: ^Player, box: ^StorageBox) {
	using player

	fmt.println("Adding logs into storage")
	for log in inventory.storage {
		box.storage[log.logType] += 1
	}

	clear(&player.inventory.storage)
}
