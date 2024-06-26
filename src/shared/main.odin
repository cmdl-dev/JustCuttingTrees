package shared


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
