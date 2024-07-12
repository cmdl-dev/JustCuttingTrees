package main


import "shared"
import rl "vendor:raylib"


AreaType :: enum {
	COLLISION,
	INTERACTION,
}

Area2D :: struct {
	using rect:        rl.Rectangle,
	origin:            rl.Vector2,
	type:              AreaType,
	translationCoords: rl.Vector2,
	draw:              proc(area: ^Area2D),
	update:            proc(area: ^Area2D, position: rl.Vector2),
}

getCoordsFromOrigin :: proc(area: ^Area2D) -> (x: f32, y: f32) {
	x = area.origin.x - (area.width / 2)
	y = area.origin.y - (area.height / 2)
	return
}
createArea2D :: proc(type: AreaType, origin: rl.Vector2, rect: rl.Rectangle) -> Area2D {
	return Area2D {
		type = type,
		origin = {rect.x + origin.x, rect.y + origin.y},
		draw = drawAreaRect,
		update = updateLocation,
		rect = rect,
	}
}

translate :: proc(area: ^Area2D, value: rl.Vector2) {
	area.origin += value
}

drawAreaRect :: proc(area: ^Area2D) {
	using area

	rl.DrawRectangleLines(
		i32(x),
		i32(y),
		i32(width),
		i32(height),
		type == AreaType.COLLISION ? rl.RED : rl.BLUE,
	)

	// rl.DrawCircle(i32(origin.x), i32(origin.y), 2, rl.RED)
}

updateLocation :: proc(area: ^Area2D, deltaPos: rl.Vector2) {
	using area
	area.origin += deltaPos
	x, y = getCoordsFromOrigin(area)
}


GetAdjustedVectorFromCollision :: proc(
	box: rl.Rectangle,
	boxes: [dynamic]rl.Rectangle,
	calculatedPosition: rl.Vector2,
) -> (
	pos: rl.Vector2,
) {
	futurePosition := box

	pos = calculatedPosition


	futurePosition.x += f32(pos.x)

	for cBox in boxes {
		if rl.CheckCollisionRecs(cBox, futurePosition) {
			if pos.x > 0 {
				pos.x = (cBox.x - box.width) - box.x
			} else if pos.x < 0 {
				pos.x = (cBox.x + cBox.width) - box.x
			}
		}
	}

	futurePosition.x = box.x + f32(pos.x)

	futurePosition.y += f32(pos.y)
	for cBox in boxes {
		if rl.CheckCollisionRecs(cBox, futurePosition) {
			if pos.y > 0 {
				pos.y = (cBox.y - box.height) - box.y
			} else if pos.y < 0 {
				pos.y = (cBox.y + cBox.height) - box.y
			}
		}
	}


	return pos


}
