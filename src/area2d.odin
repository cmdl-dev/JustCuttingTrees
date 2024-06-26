package main


import "shared"
import rl "vendor:raylib"


AreaType :: enum {
	COLLISION,
	INTERACTION,
}
Area2D :: struct {
	using rect: rl.Rectangle,
	type:       AreaType,
	draw:       proc(area: ^Area2D),
	update:     proc(area: ^Area2D, position: shared.IVector2),
}


createArea2D :: proc(type: AreaType, rect: rl.Rectangle) -> Area2D {
	return {type = type, rect = rect, draw = drawAreaRect, update = updateLocation}
}

drawAreaRect :: proc(area: ^Area2D) {
	using area

	rl.DrawRectangleLines(i32(x), i32(y), i32(width), i32(height), rl.BLUE)
}

updateLocation :: proc(area: ^Area2D, position: shared.IVector2) {
	area.x = position.x
	area.y = position.y
}
