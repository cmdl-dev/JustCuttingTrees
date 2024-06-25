
package main

import "constants"
import "core:fmt"
import "shared"
import rl "vendor:raylib"


Window :: struct {
	fps:    i32,
	width:  i32,
	height: i32,
	title:  cstring,
}

GameState :: struct {
	player: Player,
	trees:  [dynamic]Tree,
	draw:   proc(state: ^GameState),
	input:  proc(state: ^GameState),
	update: proc(state: ^GameState, delta: f32),
}


UserInput :: struct {
	direction:      shared.IVector2,
	justInteracted: bool,
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
	regularTree := createRegularTree({150, 150})

	append(&gState.trees, regularTree)

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
			if rl.CheckCollisionRecs(player.interactionRect, tree.area) {
				tree->onInteractable(&player)
			}
		}
	}


}
draw :: proc(state: ^GameState) {
	using state

	player->playerDraw()

	for &tree in trees {
		tree->draw()
	}
}
