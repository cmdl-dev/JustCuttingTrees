
package main

import "constants"
import "core:fmt"
import "core:strings"
import "shared"

import rnd "core:math/rand"
import rl "vendor:raylib"


Window :: struct {
	fps:    i32,
	width:  i32,
	height: i32,
	title:  cstring,
}


StorageBox :: struct {
	using rect:     rl.Rectangle,
	// Gets the count of each log type
	storage:        map[LogType]i32,
	drawStorageBox: proc(storageBox: ^StorageBox),
}

createStorageBox :: proc(location: shared.IVector2) -> StorageBox {

	return {
		x = location.x,
		y = location.y,
		width = 50,
		height = 30,
		drawStorageBox = drawStorageBox,
	}
}
drawStorageBox :: proc(storageBox: ^StorageBox) {
	using storageBox

	rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), rl.ORANGE)
}
GameState :: struct {
	player:     Player,
	storageBox: StorageBox,
	trees:      [dynamic]Tree,
	draw:       proc(state: ^GameState),
	input:      proc(state: ^GameState),
	update:     proc(state: ^GameState, delta: f32),
}

UserInput :: struct {
	direction:      shared.IVector2,
	justInteracted: bool,
}

createManyTrees :: proc(count: i32) -> (trees: [dynamic]Tree) {
	for c in 0 ..< count {
		x := rnd.float32_range(200, 1500)
		y := rnd.float32_range(200, 900)
		regularTree := createRegularTree({x, y})

		append(&trees, regularTree)
	}
	return trees
}
getTotalGameScore :: proc(gameState: ^GameState) -> (accumulator: i32) {
	using gameState
	for k, v in storageBox.storage {
		accumulator += LogToValueMap[k].value * v
	}

	return
}

drawTotalScore :: proc(gameState: ^GameState, position: shared.IVector2) {
	using gameState

	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	text := fmt.sbprintf(&b, "%d", getTotalGameScore(gameState))
	cText := strings.to_cstring(&b)

	textWidth := rl.MeasureText(cText, 32)
	rl.DrawText(cText, i32(position.x), i32(position.y), 32, rl.BLACK)
}


main :: proc() {
	window := Window {
		width  = constants.SCREEN_WIDTH,
		height = constants.SCREEN_HEIGHT,
		title  = "Just Cutting Trees",
		fps    = constants.TARGET_FPS,
	}
	rl.InitWindow(window.width, window.height, window.title)
	rl.SetTraceLogLevel(rl.TraceLogLevel.ERROR)
	rl.SetTargetFPS(window.fps)

	gState := GameState {
		player = createPlayer({0, 0}),
		draw   = draw,
		update = update,
		input  = input,
	}
	gState.storageBox = createStorageBox({1000, 50})
	gState.trees = createManyTrees(20)


	for !rl.WindowShouldClose() {

		delta := rl.GetFrameTime()
		// Capture input
		gState->input()
		// Handle update
		gState->update(delta)
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)
		// Handle draw
		gState->draw()
		rl.EndDrawing()
	}
}

getUserInput :: proc() -> UserInput {
	direction := shared.IVector2{}
	justInteracted := false

	if (rl.IsKeyDown(rl.KeyboardKey.PERIOD)) {
		direction.y += -1
	}
	if (rl.IsKeyDown(rl.KeyboardKey.O)) {
		direction.x += -1
	}
	if (rl.IsKeyDown(rl.KeyboardKey.E)) {
		direction.y += 1
	}
	if (rl.IsKeyDown(rl.KeyboardKey.U)) {
		direction.x += 1
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.P)) {
		justInteracted = true
	}

	return {direction, justInteracted}
}

input :: proc(state: ^GameState) {
	using state
	userInput := getUserInput()

	//TODO: Maybe works
	player->playerInput(userInput)

}

update :: proc(state: ^GameState, delta: f32) {
	using state

	player->playerUpdate(delta)

	if player.state == PlayerState.INTERACTION {
		for &tree in state.trees {
			if !tree->isDead() && rl.CheckCollisionRecs(player.interactionRect, tree.area) {
				tree->onInteractable(&player)
			}
		}
		if rl.CheckCollisionRecs(storageBox, player.interactionRect) {
			player->storeLogs(&storageBox)
		}
	}


}

draw :: proc(state: ^GameState) {
	using state
	storageBox->drawStorageBox()

	player->playerDraw()

	for &tree in trees {
		if !tree->isDead() {
			tree->draw()
		}
	}

	drawTotalScore(state, {30, 30})

}
