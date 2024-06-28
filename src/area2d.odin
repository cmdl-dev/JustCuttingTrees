package main


import "shared"
import rl "vendor:raylib"


AreaType :: enum {
	COLLISION,
	INTERACTION,
}
Area2D :: struct {
	using rect: rl.Rectangle,
	centered:   bool,
	type:       AreaType,
	parentSize: struct {
		height: i32,
		width:  i32,
	},
	draw:       proc(area: ^Area2D),
	update:     proc(area: ^Area2D, position: shared.IVector2),
}


createArea2D :: proc(type: AreaType, rect: rl.Rectangle, parentSize: struct {
		height: i32,
		width:  i32,
	}, centered: bool = false) -> Area2D {
	return {
		type = type,
		rect = rect,
		draw = drawAreaRect,
		parentSize = parentSize,
		update = updateLocation,
		centered = centered,
	}
}

drawAreaRect :: proc(area: ^Area2D) {
	using area

	rl.DrawRectangleLines(i32(x), i32(y), i32(width), i32(height), rl.BLUE)
}

updateLocation :: proc(area: ^Area2D, position: shared.IVector2) {
	using area
	area.x = position.x
	area.y = position.y
	if centered {
		area.x += f32(parentSize.width / 2) - f32(width / 2)
		area.y += f32(parentSize.height / 2) - f32(height / 2)
	}
}
