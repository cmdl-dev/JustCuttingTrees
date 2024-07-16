
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
	move:       proc(menu: ^Menu, position: rl.Vector2),
}

getMenuSizes :: proc(pInv: ^Menu) -> struct {
		center:      rl.Vector2,
		bottomRight: rl.Vector2,
		topRight:    rl.Vector2,
	} {
	using pInv

	return {
		center = {x + (width / 2), y + (height / 2)},
		bottomRight = {x + width, y + height},
		topRight = {x + width, y},
	}
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

createStorageBox :: proc(rect: rl.Rectangle) -> StorageBox {

	return {
		x = rect.x,
		y = rect.y,
		width = rect.width,
		height = rect.height,
		drawStorageBox = drawStorageBox,
	}
}

drawStorageBox :: proc(storageBox: ^StorageBox) {
	using storageBox

	// rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), rl.ORANGE)
	rl.DrawRectangleLines(i32(x), i32(y), i32(width), i32(height), rl.ORANGE)
}

GameState :: struct {
	level:           TileMap,
	player:          Player,
	storageBox:      StorageBox,
	isCameraStopped: bool,
	trees:           [dynamic]Tree,
	camera:          rl.Camera2D,
	showMiniMap:     bool,
	renderTexture:   rl.RenderTexture2D,
	draw:            proc(state: ^GameState),
	input:           proc(state: ^GameState),
	update:          proc(state: ^GameState, delta: f32),
}

UserInput :: struct {
	direction:      rl.Vector2,
	justSwung:      bool,
	justInteracted: bool,
	tabMenuPressed: bool,
}


createManyTrees :: proc(count: i32, gState: ^GameState) -> (trees: [dynamic]Tree) {
	mapBounds := gState.level.playableMapRect

	for c in 0 ..< count {
        x := rnd.float32_range(mapBounds.x, mapBounds.x + mapBounds.width)
		y := rnd.float32_range(mapBounds.y, mapBounds.y + mapBounds.height)

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

drawTotalScore :: proc(gameState: ^GameState, position: rl.Vector2) {
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

	camera := rl.Camera2D {
		offset = {f32(constants.SCREEN_WIDTH / 2), f32(constants.SCREEN_HEIGHT / 2)}, // Camera offset (displacement from target)
		zoom   = 1, // Camera zoom (scaling), should be 1.0f by default
	}

	gState := GameState {
		camera = camera,
		draw   = draw,
		update = update,
		input  = input,
		level  = creatTileMap("maps/level1test.ldtk"),
	}


	gState.renderTexture = rl.LoadRenderTexture(i32(gState.level.playableMapRect.width/10),i32(gState.level.playableMapRect.height / 10))

	gState.player = createPlayer(gState.level.playerInitialLocation)
	gState.camera.target = gState.player.position

	gState.storageBox = createStorageBox(getEnterLocation(gState.level))
	gState.trees = createManyTrees(20, &gState)



	for !rl.WindowShouldClose() {
		drawMiniMap(&gState)

		delta := rl.GetFrameTime()
		// Capture input
		gState->input()
		// Handle update

		gState->update(delta)
		// -----
		rl.BeginDrawing()
		rl.BeginMode2D(gState.camera)
		rl.ClearBackground(rl.WHITE)

		// // Handle draw
		gState->draw()
        // wood.sprite->draw()


		rl.EndMode2D()
		rl.EndDrawing()
	}
}

getUserInput :: proc() -> (userInput: UserInput) {


	if (rl.IsKeyDown(rl.KeyboardKey.W)) {
		userInput.direction.y += -1
	}
	if (rl.IsKeyDown(rl.KeyboardKey.A)) {
		userInput.direction.x += -1
	}
	if (rl.IsKeyDown(rl.KeyboardKey.S)) {
		userInput.direction.y += 1
	}

	if (rl.IsKeyDown(rl.KeyboardKey.D)) {
		userInput.direction.x += 1
	}

	if (rl.IsKeyPressed(rl.KeyboardKey.E)) {
		userInput.justInteracted = true
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.TAB)) {
		userInput.tabMenuPressed = true
	}
	if (rl.IsMouseButtonDown(rl.MouseButton.LEFT)) {
		userInput.justSwung = true
	}

	return
}

input :: proc(state: ^GameState) {
	using state
	userInput := getUserInput()

	player->playerInput(userInput)

}

hasEnteredCenter :: proc(player: ^Player, camera: ^rl.Camera2D) -> bool {
	pos := rl.GetScreenToWorld2D(camera.offset, camera^)
	centerRect := rl.Rectangle {
		x      = pos.x,
		y      = pos.y,
		width  = 100,
		height = 100,
	}

	return rl.CheckCollisionRecs(player.interactionRect, centerRect)
}
hasReachedCornerOfScreen :: proc(camera: ^rl.Camera2D) -> bool {
	pos := rl.GetScreenToWorld2D({0, 0}, camera^)
	if pos.x <= 0 {
		return true
	}
	if pos.y <= 0 {
		return true
	}
	return false

}

update :: proc(state: ^GameState, delta: f32) {
	using state

	player->playerUpdate(&state.level.collision, delta)

	for &tree in state.trees {
		onUpdate(&tree)
		if playerIsSwing(&player) {
			if !tree->isDead() && rl.CheckCollisionRecs(player.swingRect, tree.area) {
				tree->onInteractable()
			}
		}
        if player.state == PlayerState.INTERACTION && tree.log.isActive {
             if rl.CheckCollisionRecs(tree.log.interaction, player.interactionRect) {
                tree.log.onLogInteract(&tree, &player)
            }
        }

	}

	if player.state == PlayerState.INTERACTION {
            if rl.CheckCollisionRecs(storageBox, player.interactionRect) {
                player->storeLogs(&storageBox)
            }
	}


    state.camera.target = player.position
	player.inventory->move(rl.GetScreenToWorld2D({0, 100}, state.camera))
}

drawPlayerPosition :: proc(player: ^Player, position: rl.Vector2) {

	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	text := fmt.sbprintf(&b, "(%d,%d)", i32(player.position.x), i32(player.position.y))
	cText := strings.to_cstring(&b)
	rl.DrawText(cText, i32(position.x), i32(position.y), 32, rl.BLACK)
}

draw :: proc(state: ^GameState) {
	using state


	state.level->draw()

	for &tree in trees {
		tree->draw()
	}
    player->playerDraw()
	storageBox->drawStorageBox()

	fpsPos := rl.GetScreenToWorld2D({state.camera.offset.x, 30}, state.camera)
	drawTotalScore(state, rl.GetScreenToWorld2D({30, 30}, state.camera))

	drawPlayerPosition(&state.player, rl.GetScreenToWorld2D({100, 30}, state.camera))


	pos := rl.GetScreenToWorld2D(
		{f32(constants.SCREEN_WIDTH - (state.renderTexture.texture.width ) - 4), 10},
		state.camera,
	)

	rl.DrawTextureRec(
		state.renderTexture.texture,
		{0, 0, f32(state.renderTexture.texture.width), f32(-state.renderTexture.texture.height)},
		pos,
		rl.WHITE,
	)
	// DrawTextureRec(target.texture, (Rectangle) { 0, 0, (float)target.texture.width, (float)-target.texture.height }, (Vector2) { 0, 0 }, WHITE);

}
