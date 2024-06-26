package sprite

import "../shared"
import rl "vendor:raylib"

AnimatedSprite :: struct {
	using sprite:     Sprite,
	using animatable: Animatable,
	draw:             proc(sprite: ^AnimatedSprite),
	getWidth:         proc(sprite: ^AnimatedSprite) -> i32,
	getHeight:        proc(sprite: ^AnimatedSprite) -> i32,
}


createAnimatedSprite :: proc(
	fileName: cstring,
	initialPosition: rl.Vector2,
	animationFrames: AnimationFrames,
) -> AnimatedSprite {

	sprite := createSprite(fileName, initialPosition)

	animatable := createAnimatable(sprite.texture.width, sprite.texture.height, animationFrames)


	return {
		sprite = sprite,
		animatable = animatable,
		draw = drawAnimatedSprite,
		getWidth = getWidth,
		getHeight = getHeight,
	}

}

getWidth :: proc(sprite: ^AnimatedSprite) -> i32 {
	using sprite

	return animationOffsets.x
}
getHeight :: proc(sprite: ^AnimatedSprite) -> i32 {
	using sprite

	return animationOffsets.y
}

drawAnimatedSprite :: proc(sprite: ^AnimatedSprite) {
	updateAnimationFrame(sprite)

	rect := sprite.currentAnimation.animationPath[sprite.currentFrame]
	rl.DrawTextureRec(
		sprite.texture,
		rect,
		sprite.position -
		[2]f32{f32(sprite.animationOffsets.x / 2), f32(sprite.animationOffsets.y / 2)},
		rl.WHITE,
	)
	// rl.DrawRectangleLines(
	// 	i32(sprite.position.x),
	// 	i32(sprite.position.y),
	// 	sprite.texture.width,
	// 	sprite.texture.height,
	// 	rl.GREEN,
	// )
}
