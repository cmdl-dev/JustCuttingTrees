
package main

import "constants"
import "core:fmt"
import "core:strings"
import "shared"

import rnd "core:math/rand"
import rl "vendor:raylib"


Menu :: struct {
	using rect: rl.Rectangle,
	show:       bool,
	title:      cstring,
	drawMenu:   proc(menu: ^Menu),
	move:       proc(menu: ^Menu, position: shared.IVector2),
}

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
	camera:     rl.Camera2D,
	draw:       proc(state: ^GameState),
	input:      proc(state: ^GameState),
	update:     proc(state: ^GameState, delta: f32),
}

UserInput :: struct {
	direction:      shared.IVector2,
	justSwung:      bool,
	justInteracted: bool,
	tabMenuPressed: bool,
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
	camera := rl.Camera2D {
		offset = {f32(constants.SCREEN_WIDTH / 2), f32(constants.SCREEN_HEIGHT / 2)}, // Camera offset (displacement from target)
		target = {0, 0}, // Camera target (rotation and zoom origin)
		zoom   = 1.3, // Camera zoom (scaling), should be 1.0f by default
	}
	rl.InitWindow(window.width, window.height, window.title)
	rl.SetTraceLogLevel(rl.TraceLogLevel.ERROR)
	rl.SetTargetFPS(window.fps)

	gState := GameState {
		player = createPlayer({0, 0}),
		camera = camera,
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
		rl.BeginMode2D(gState.camera)
		rl.ClearBackground(rl.WHITE)
		// Handle draw
		gState->draw()
		rl.EndMode2D()
		rl.EndDrawing()
	}
}

getUserInput :: proc() -> (userInput: UserInput) {


	if (rl.IsKeyDown(rl.KeyboardKey.PERIOD)) {
		userInput.direction.y += -1
	}
	if (rl.IsKeyDown(rl.KeyboardKey.O)) {
		userInput.direction.x += -1
	}
	if (rl.IsKeyDown(rl.KeyboardKey.E)) {
		userInput.direction.y += 1
	}
	if (rl.IsKeyDown(rl.KeyboardKey.U)) {
		userInput.direction.x += 1
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.P)) {
		userInput.justInteracted = true
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.TAB)) {
		userInput.tabMenuPressed = true
	}
	if (rl.IsMouseButtonPressed(rl.MouseButton.LEFT)) {
		userInput.justSwung = true
	}

	return
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

	// TODO: Should only interact if the axe is in its activatebl frames
	// if player.state == PlayerState.INTERACTION {
	// 	for &tree in state.trees {
	// 		if !tree->isDead() && rl.CheckCollisionRecs(player.interactionRect, tree.area) {
	// 			tree->onInteractable(&player)
	// 		}
	// 	}
	// 	if rl.CheckCollisionRecs(storageBox, player.interactionRect) {
	// 		player->storeLogs(&storageBox)
	// 	}
	// }


	state.camera.target = shared.toRlVector(player.position)

	player.inventory->move(shared.RLVectorToIVector(rl.GetScreenToWorld2D({0, 100}, state.camera)))
}

draw :: proc(state: ^GameState) {
	using state

	for &tree in trees {
		if !tree->isDead() {
			tree->draw()
		}
	}
	storageBox->drawStorageBox()
	player->playerDraw()


	drawTotalScore(state, shared.RLVectorToIVector(rl.GetScreenToWorld2D({30, 30}, state.camera)))

}
