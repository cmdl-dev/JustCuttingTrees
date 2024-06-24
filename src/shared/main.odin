package shared

IVector2 :: struct {
	x: f32,
	y: f32,
}

toRlVector :: proc(vec: IVector2) -> [2]f32 {
	return {vec.x, vec.y}
}
