package main

import "core:fmt"
import "shared"
import rl "vendor:raylib"

FrameCoords :: struct {
	x, y: i32,
}
AnimationInfo :: struct {
	maxFrames:   int,
	name:        string,
	frameCoords: FrameCoords,
}

AnimationFrames :: struct {
	hFrames: i32,
	vFrames: i32,
}
AnimationOffsets :: struct {
	x: i32,
	y: i32,
}
Animatable :: struct {
	currentFrame:         int,
	frameSpeed:           int,
	frameCounter:         int,
	isAnimationPlaying:   bool,
	animationOffsets:     AnimationOffsets,
	animationFrames:      AnimationFrames,
	animations:           map[string]AnimationInfo,
	currentAnimation:     AnimationInfo,
	animationPath:        [dynamic]rl.Rectangle,
	addAnimation:         proc(
		sprite: ^Animatable,
		name: string,
		maxFrames: int,
		coords: FrameCoords,
	),
	setAnimationSpeed:    proc(sprite: ^Animatable, speed: int),
	resetAnimations:      proc(anim: ^Animatable),
	updateAnimationFrame: proc(anim: ^Animatable),
}

AnimatedSprite :: struct {
	using animation:        Animatable,
	using sprite:           Sprite,
	createAnimationPath:    proc(anim: ^AnimatedSprite),
	playAnimation:          proc(anim: ^AnimatedSprite, name: string),
	drawAnimated:           proc(aSprite: ^AnimatedSprite),
	setAnimatedSpriteScale: proc(aSprite: ^AnimatedSprite, scale: i32),
	getSpriteWidth:         proc(sprite: ^AnimatedSprite) -> i32,
	getSpriteHeight:        proc(sprite: ^AnimatedSprite) -> i32,
}

createAnimatedSprite :: proc(
	fileName: cstring,
	initiaPosition: shared.IVector2,
	frameSpeed: int,
	animationFrames: AnimationFrames,
) -> AnimatedSprite {
	sprite := createSprite(fileName, initiaPosition)

	return {
		sprite = sprite,
		animation = Animatable {
			currentFrame = 0,
			frameSpeed = frameSpeed,
			frameCounter = 0,
			isAnimationPlaying = false,
			animationFrames = animationFrames,
			animationOffsets = AnimationOffsets {
				x = sprite.texture.width / animationFrames.hFrames,
				y = sprite.texture.height / animationFrames.vFrames,
			},
			addAnimation = addAnimation,
			setAnimationSpeed = setAnimationSpeed,
			resetAnimations = resetAnimations,
			updateAnimationFrame = updateAnimationFrame,
		},
		drawAnimated = drawAnimatedSprite,
		playAnimation = playAnimation,
		createAnimationPath = createAnimationPath,
		setAnimatedSpriteScale = setAnimatedSpriteScale,
		getSpriteWidth = getSpriteWidth,
		getSpriteHeight = getSpriteHeight,
	}

}
getSpriteWidth :: proc(sprite: ^AnimatedSprite) -> i32 {
	return sprite.animationOffsets.x
}

getSpriteHeight :: proc(sprite: ^AnimatedSprite) -> i32 {
	return sprite.animationOffsets.y
}

Sprite :: struct {
	texture:   rl.Texture2D,
	position:  shared.IVector2,
	draw:      proc(sprite: ^Sprite),
	setScale:  proc(sprite: ^Sprite, scale: i32),
	getHeight: proc(sprite: ^Sprite) -> i32,
	getWidth:  proc(sprite: ^Sprite) -> i32,
}


createSprite :: proc(fileName: cstring, initialPosition: shared.IVector2) -> Sprite {
	texture := loadTexture(fileName)

	return {
		texture = texture,
		position = initialPosition,
		draw = drawSprite,
		setScale = setScale,
		getHeight = getHeight,
		getWidth = getWidth,
	}
}
getHeight :: proc(sprite: ^Sprite) -> i32 {
	using sprite
	return texture.height
}
getWidth :: proc(sprite: ^Sprite) -> i32 {
	using sprite
	return texture.width
}


loadTexture :: proc(fileName: cstring) -> rl.Texture2D {
	texture := rl.LoadTexture(fileName)

	assert(texture.width != 0, "Could not load asset")
	return texture
}

setScale :: proc(sprite: ^Sprite, scale: i32) {
	sprite.texture.height *= scale
	sprite.texture.width *= scale
}

addAnimation :: proc(anim: ^Animatable, name: string, maxFrames: int, coords: FrameCoords) {
	anim.animations[name] = AnimationInfo {
		name        = name,
		maxFrames   = maxFrames,
		frameCoords = coords,
	}
}

setAnimationSpeed :: proc(anim: ^Animatable, speed: int) {
	anim.frameSpeed = speed
}

/*
NOTE: Must be used before createAnimationPaths

*/
setAnimatedSpriteScale :: proc(aSprite: ^AnimatedSprite, scale: i32) {
	using aSprite
	aSprite->setScale(scale)

	animationOffsets.x = texture.width / animationFrames.hFrames
	animationOffsets.y = texture.height / animationFrames.vFrames

}

resetAnimations :: proc(anim: ^Animatable) {
	using anim
	currentFrame = 0
	isAnimationPlaying = false
	clear(&animationPath)
}

updateAnimationFrame :: proc(anim: ^Animatable) {
	using anim

	frameCounter += 1
	if frameCounter > (60 / frameSpeed) {
		frameCounter = 0
		isAnimationPlaying = true
		currentFrame += 1

		if currentFrame >= currentAnimation.maxFrames - 1 {
			currentFrame = 0
			isAnimationPlaying = false
		}
	}


}

playAnimation :: proc(anim: ^AnimatedSprite, name: string) {
	using anim
	if currentAnimation.name == name {
		return
	}

	if animation, ok := animations[name]; ok {
		currentAnimation = animation
		resetAnimations(anim)
		createAnimationPath(anim)
	}
}

createAnimationPath :: proc(aSprite: ^AnimatedSprite) {
	using aSprite

	currentCol := currentAnimation.frameCoords.x
	currentRow := currentAnimation.frameCoords.y


	for i in 0 ..< currentAnimation.maxFrames {

		xStart := i32(currentCol) * animationOffsets.x
		yStart := i32(currentRow) * animationOffsets.y

		append(
			&animationPath,
			rl.Rectangle {
				f32(xStart),
				f32(yStart),
				f32(animationOffsets.x),
				f32(animationOffsets.y),
			},
		)
		currentCol += 1
		if xStart >= texture.width {
			currentRow += 1
			currentCol = 0
		}

	}
}

drawAnimatedSprite :: proc(aSprite: ^AnimatedSprite) {
	using aSprite

	assert(len(animationPath) != 0, "Animation path is empty")

	animation->updateAnimationFrame()
	currentAnimationFrame := animationPath[currentFrame]

	rl.DrawTextureRec(texture, currentAnimationFrame, shared.toRlVector(position), rl.WHITE)

}
drawSprite :: proc(sprite: ^Sprite) {
	using sprite
	rl.DrawTexture(texture, i32(position.x), i32(position.y), rl.WHITE)
}
