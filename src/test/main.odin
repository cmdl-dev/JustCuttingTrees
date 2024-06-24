package test


import "core:fmt"
import rl "vendor:raylib"


main :: proc() {
	texture := rl.LoadTexture("asset/Heavy_Knight_Sprite_Sheet.png")
	fmt.println("Something", texture.width)
}
