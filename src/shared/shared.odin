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

	assert(texture.width != 0, strings.concatenate({"Could not load asset: ", string(fileName)}))
	return texture
}
stringToCString :: proc(str: string) -> (cs: cstring) {
	b := strings.builder_make()
	// TODO: Figure this out 
	// defer strings.builder_destroy(&b)


	strings.write_string(&b, str)


	cs = strings.to_cstring(&b)
	return
}
