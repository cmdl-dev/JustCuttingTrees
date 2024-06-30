package sprite

import "../shared"
import rl "vendor:raylib"

Sprite :: struct {
	texture:  rl.Texture2D,
	position: rl.Vector2,
}

createSprite :: proc(fileName: cstring, initialPosition: rl.Vector2) -> Sprite {

	return {texture = shared.loadTexture(fileName), position = initialPosition}
}
