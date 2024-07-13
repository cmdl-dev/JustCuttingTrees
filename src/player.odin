package main

import "core:fmt"
import "core:strings"
import "shared"
import "sprite"
import rl "vendor:raylib"

PlayerEventKeys :: enum {
	NONE,
	SWING,
	INTERACT,
}

PlayerEvent :: struct {
	current:  PlayerEventKeys,
	previous: PlayerEventKeys,
}


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
moveInventory :: proc(inv: ^Menu, position: rl.Vector2) {
	using inv
	x = position.x
	y = position.y
}

drawTotal :: proc(pInv: ^PlayerInventory) {

	centerPosX := getMenuSizes(pInv).center.x
	bottomPosY := getMenuSizes(pInv).bottomRight.y

	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	text := fmt.sbprintf(&b, "Score: %d", getPlayerTotalScore(pInv))
	cText := strings.to_cstring(&b)

	textWidth := rl.MeasureText(cText, 12)

	rl.DrawText(cText, i32(centerPosX) - (textWidth / 2), i32(bottomPosY) - 12, 12, rl.BLACK)
}
drawLogs :: proc(pInv: ^PlayerInventory) {
	using pInv

	padding := i32(10)

	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	regWoodTotal, willowWoodTotal: i32
	for log in storage {
		if log.logType == LogType.REGULAR do regWoodTotal += 1
		if log.logType == LogType.WILLOW do willowWoodTotal += 1
	}
	text := fmt.sbprintf(
		&b,
		"Regular Wood: %d %dkg\n\nWillow Wood: %d %dkg",
		regWoodTotal,
		regWoodTotal * i32(LogToValueMap[LogType.REGULAR].weight),
		willowWoodTotal,
		willowWoodTotal * i32(LogToValueMap[LogType.WILLOW].weight),
	)

	cText := strings.to_cstring(&b)
	textWidth := rl.MeasureText(cText, 14)

	rl.DrawText(cText, i32(x) + padding, i32(y + 40), 14, rl.BLACK)
}
drawContents :: proc(pInv: ^PlayerInventory) {
	using pInv
	if !show {
		return
	}

	pInv->drawMenu()
	drawLogs(pInv)
	drawTotal(pInv)

}

drawMenu :: proc(inv: ^Menu) {
	using inv

	textWidth := rl.MeasureText(title, 24)
	centerPosX := getMenuSizes(inv).center.x

	rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), rl.ORANGE) // rl.DrawRectangle(i32(x - width), i32(y - height), i32(width), i32(height), rl.ORANGE)
	rl.DrawText(title, i32(centerPosX) - (textWidth / 2), i32(y + 5), 24, rl.BLACK)
}


PlayerState :: enum {
	INTERACTION,
	IDLE,
	WALK,
	SWING,
}

Player :: struct {
	using moveable:     Moveable,
	using actor:        Actor,
	isSwinging:         bool,
	sprite:             sprite.AnimatedSprite,
	cameraOverrideRect: rl.Rectangle,
	interactionRect:    Area2D,
	collisionRect:      Area2D,
	swingActive:        bool,
	swingRect:          Area2D,
	events:             PlayerEvent,
	inventory:          PlayerInventory,
	state:              PlayerState,
	storeLogs:          proc(player: ^Player, storage: ^StorageBox),
	addReward:          proc(player: ^Player, reward: [dynamic]TreeReward),
	playerInput:        proc(player: ^Player, userInput: UserInput),
	playerUpdate:       proc(player: ^Player, collisionTiles: ^CollisionTiles, delta: f32),
	playerDraw:         proc(player: ^Player),
}


createPlayer :: proc(initialPosition: rl.Vector2) -> Player {

	actor := createActor(initialPosition)
	moveable := createMoveable(200)
	inventory := createPlayerInventory({initialPosition.x, initialPosition.y, 200, 200})

	sprite, ok := sprite.createAnimatedSprite("player", initialPosition)
	if !ok {
		fmt.println("Could not load player sprite")
	}


	sprite->playAnimation("Run")

	collisionRect := createArea2D(
		AreaType.COLLISION,
		{0, 0},
		rl.Rectangle{initialPosition.x, initialPosition.y, 16, 16},
	)
	translate(&collisionRect, {0, 24})

	interactionRect := createArea2D(
		AreaType.INTERACTION,
		{0, 0},
		rl.Rectangle{initialPosition.x, initialPosition.y, 32, 32},
	)
	swingRect := createArea2D(
		AreaType.INTERACTION,
		{0, 0},
		rl.Rectangle{initialPosition.x, initialPosition.y, 32, 32},
	)
	translate(&swingRect, {60, 0})

	cameraOverrideRect := rl.Rectangle {
		initialPosition.x - (200 / 2),
		initialPosition.y - (200 / 2),
		200,
		200,
	}

	return Player {
		actor = actor,
		moveable = moveable,
		sprite = sprite,
		storeLogs = storeLogs,
		interactionRect = interactionRect,
		collisionRect = collisionRect,
		cameraOverrideRect = cameraOverrideRect,
		swingRect = swingRect,
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

	if player.isSwinging {
		return

	}
	if userInput.justInteracted {
		player.state = PlayerState.INTERACTION
	} else if player.direction != {0, 0} {
		player.state = PlayerState.WALK
	} else if userInput.justSwung {
		player.state = PlayerState.SWING
	} else {
		player.state = PlayerState.IDLE
	}


	if userInput.tabMenuPressed {
		player.inventory.show = !player.inventory.show
	}

}

playerUpdate :: proc(player: ^Player, collisionTiles: ^CollisionTiles, delta: f32) {
	using player
	switch player.state {
	case .INTERACTION:
		player.sprite->playAnimation("Idle")
	case .IDLE:
		player.sprite->playAnimation("Idle")
	case .WALK:
		player.sprite->playAnimation("Run")
	case .SWING:
		player.sprite->playAnimation("Chop")
		isSwinging = true
	}

	if (!isSwinging) {


		calculatedDelta := GetAdjustedVectorFromCollision(
			player.collisionRect,
			collisionTiles.locations,
			{delta * f32(velocity) * direction.x, delta * f32(velocity) * direction.y},
		)

		player.moveable.move(player, calculatedDelta)
		sprite.position = position

		interactionRect->update(calculatedDelta)
		swingRect->update(calculatedDelta)
		collisionRect->update(calculatedDelta)

		player.cameraOverrideRect.x = player.position.x - (player.cameraOverrideRect.width / 2)
		player.cameraOverrideRect.y = player.position.y - (player.cameraOverrideRect.height / 2)

	} else {

		if player.sprite->isFrameActive() && isSwinging {
			updateEvent(player, PlayerEventKeys.SWING)

		} else if player.state == PlayerState.INTERACTION {
			updateEvent(player, PlayerEventKeys.INTERACT)
		} else {
			updateEvent(player, PlayerEventKeys.NONE)
		}

	}

	if !player.sprite.isAnimationPlaying && isSwinging {
		isSwinging = false
	}

}

updateEvent :: proc(player: ^Player, event: PlayerEventKeys) {
	player.events.previous = player.events.current
	player.events.current = event
}

playerIsSwing :: proc(player: ^Player) -> bool {
	return(
		player.events.previous != PlayerEventKeys.SWING &&
		player.events.current == PlayerEventKeys.SWING \
	)
}

getPlayerTotalScore :: proc(pInv: ^PlayerInventory) -> (accumulator: i32) {
	using pInv

	for reward in storage {
		accumulator += reward.info.value
	}
	return
}

playerDraw :: proc(player: ^Player) {

	player.sprite->draw()
	if playerIsSwing(player) do player.swingRect->draw()
	player.inventory->drawInventory()
	player.interactionRect->draw()
	player.collisionRect->draw()

	// if sprite.eventOccured(&player.sprite, sprite.AnimationEventKeys.FINISHED) {
	// 	fmt.println("Finished animation")

	// }
}

storeLogs :: proc(player: ^Player, box: ^StorageBox) {
	using player

	for log in inventory.storage {
		box.storage[log.logType] += 1
	}

	clear(&player.inventory.storage)
}
