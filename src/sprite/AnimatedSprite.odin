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
	initialPosition: shared.IVector2,
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

setFrame :: proc(sprite: ^AnimatedSprite) {
	using sprite

	frameCounter += 1
	if frameCounter > (60 / currentAnimation.animationSpeed) {
		frameCounter = 0
		isAnimationPlaying = true

		currentFrame += 1
		if currentFrame >= currentAnimation.maxFrames {
			currentFrame = 0
			isAnimationPlaying = false
		}

	}

}
drawAnimatedSprite :: proc(sprite: ^AnimatedSprite) {
	setFrame(sprite)
	using sprite

	rect := currentAnimation.animationPath[currentFrame]
	rl.DrawTextureRec(texture, rect, shared.toRlVector(position), rl.WHITE)
}
