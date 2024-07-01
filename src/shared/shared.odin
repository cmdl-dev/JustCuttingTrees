package shared

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

IVector2 :: struct {
	x: f32,
	y: f32,
}

toRlVector :: proc(vec: IVector2) -> [2]f32 {
	return {vec.x, vec.y}
}


RLVectorToIVector :: proc(vec: [2]f32) -> IVector2 {
	return {vec[0], vec[1]}
}

loadTexture :: proc(fileName: cstring) -> rl.Texture2D {
	texture := rl.LoadTexture(fileName)

	assert(texture.width != 0, "Could not load asset")
	return texture
}
stringToCString :: proc(str: string) -> cstring {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	fmt.sbprintf(&b, "%s", str)
	return strings.to_cstring(&b)
}
