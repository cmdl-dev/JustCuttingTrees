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
	INTERACTION,
	IDLE,
	WALK,
	SWING,
}

Player :: struct {
	using moveable:  Moveable,
	using actor:     Actor,
	isSwinging:      bool,
	sprite:          sprite.AnimatedSprite,
	interactionRect: Area2D,
	swingActive:     bool,
	swingRect:       Area2D,
	events:          PlayerEvent,
	inventory:       PlayerInventory,
	state:           PlayerState,
	storeLogs:       proc(player: ^Player, storage: ^StorageBox),
	addReward:       proc(player: ^Player, reward: [dynamic]TreeReward),
	playerInput:     proc(player: ^Player, userInput: UserInput),
	playerUpdate:    proc(player: ^Player, delta: f32),
	playerDraw:      proc(player: ^Player),
}


createPlayer :: proc(initialPosition: rl.Vector2) -> Player {

	fileName := cstring("assets/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue.png")
	actor := createActor(initialPosition)
	moveable := createMoveable(200)
	inventory := createPlayerInventory({initialPosition.x, initialPosition.y, 200, 200})

	sprite := sprite.createAnimatedSprite(fileName, {50, 50}, {6, 6})

	sprite->addAnimation(
		"idle",
		{maxFrames = 6, frameCoords = {0, 0}, animationSpeed = 6, activeFrame = -1},
	)
	sprite->addAnimation(
		"walk",
		{maxFrames = 6, frameCoords = {0, 1}, animationSpeed = 6, activeFrame = -1},
	)
	sprite->addAnimation(
		"swing",
		{maxFrames = 6, frameCoords = {0, 3}, animationSpeed = 6, activeFrame = 4},
	)

	sprite->playAnimation("idle")


	interactionRect := createArea2D(
		AreaType.INTERACTION,
		{f32(sprite->getHeight() / 2), f32(sprite->getWidth() / 2)},
		rl.Rectangle{initialPosition.x, initialPosition.y, 32, 32},
	)
	swingRect := createArea2D(
		AreaType.INTERACTION,
		{f32(sprite->getHeight() / 2), f32(sprite->getWidth() / 2)},
		rl.Rectangle{initialPosition.x, initialPosition.y, 32, 32},
	)
	translate(&swingRect, {30, 0})

	return Player {
		actor = actor,
		moveable = moveable,
		sprite = sprite,
		storeLogs = storeLogs,
		interactionRect = interactionRect,
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

playerUpdate :: proc(player: ^Player, delta: f32) {
	using player
	switch player.state {
	case .INTERACTION:
		player.sprite->playAnimation("idle")
	case .IDLE:
		player.sprite->playAnimation("idle")
	case .WALK:
		player.sprite->playAnimation("walk")
	case .SWING:
		player.sprite->playAnimation("swing")
		isSwinging = true
	}

	if (!isSwinging) {

		calculatedDelta := rl.Vector2 {
			delta * f32(velocity) * direction.x,
			delta * f32(velocity) * direction.y,
		}


		player.moveable.move(player, calculatedDelta)
		sprite.position = position

		interactionRect->update(calculatedDelta)
		swingRect->update(calculatedDelta)
	} else {
		if player.sprite->isFrameActive() && isSwinging {
			updateEvent(player, PlayerEventKeys.SWING)

		} else if player.state == PlayerState.INTERACTION {
			updateEvent(player, PlayerEventKeys.INTERACT)
		} else {
			updateEvent(player, PlayerEventKeys.NONE)
		}
		// may create like a general state class thing
		// It would check the state if the key is the the same as the previous state then it wouldn't do anything 
		if playerIsSwing(player) {
			// player.swingActive = true
			fmt.println("Frame active")
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
	using player

	sprite->draw()
	if playerIsSwing(player) do swingRect->draw()
	// drawScore(player)
	player.inventory->drawInventory()
	interactionRect->draw()
}

storeLogs :: proc(player: ^Player, box: ^StorageBox) {
	using player

	fmt.println("Adding logs into storage")
	for log in inventory.storage {
		box.storage[log.logType] += 1
	}

	clear(&player.inventory.storage)
}
