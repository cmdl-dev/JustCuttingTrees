package sprite

import "../shared"
import rl "vendor:raylib"

Sprite :: struct {
	texture:  rl.Texture2D,
	position: rl.Vector2,
	// draw:      proc(sprite: ^Sprite),
	// getHeight: proc(sprite: ^Sprite) -> i32,
	// getWidth:  proc(sprite: ^Sprite) -> i32,

	// rect:      SpriteRect,
	// setRect:     proc(sprite: ^Sprite, xPos, yPos, hTiles, vTiles: i32),
	// setTileSize: proc(sprite: ^Sprite, tileSize: i32),
}

createSprite :: proc(fileName: cstring, initialPosition: rl.Vector2) -> Sprite {

	return {texture = shared.loadTexture(fileName), position = initialPosition}
}
