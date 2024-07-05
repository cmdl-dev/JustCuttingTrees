package RenderTexture

import rl "vendor:raylib"


Window :: struct {
	width:  i32,
	height: i32,
	title:  cstring,
}

drawSquare :: proc(renderTexture: ^rl.RenderTexture2D) {
	rl.BeginTextureMode(renderTexture^)
	rl.ClearBackground(rl.SKYBLUE)
	rl.EndTextureMode()

}

main :: proc() {
	window := Window {
		width  = 800,
		height = 480,
		title  = "test",
	}

	rl.InitWindow(window.width, window.height, window.title)

	camera := rl.Camera2D {
		zoom = 4,
	}
	target := rl.LoadRenderTexture(30, 30)

	for !rl.WindowShouldClose() {
		drawSquare(&target)


		rl.BeginDrawing()
		rl.BeginMode2D(camera)
		rl.ClearBackground(rl.RAYWHITE)


		rl.DrawTextureRec(
			target.texture,
			{0, 0, f32(target.texture.width), f32(-target.texture.height)},
			{0, 0},
			rl.WHITE,
		)


		rl.EndMode2D()
		rl.EndDrawing()

	}
}
