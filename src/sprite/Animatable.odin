package sprite

import "../shared"
import rl "vendor:raylib"

FrameCoords :: struct {
	x, y: i32,
}
AnimationInfo :: struct {
	maxFrames:      i32,
	name:           string,
	frameCoords:    rl.Vector2,
	animationSpeed: i32,
	// Which frame is active
	activeFrame:    i32,
	animationPath:  [dynamic]rl.Rectangle,
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
	currentFrame:       i32,
	// frameSpeed:           i32,
	frameCounter:       i32,
	isAnimationPlaying: bool,
	// animationPath:      [dynamic]rl.Rectangle,
	animations:         map[string]AnimationInfo,
	animationOffsets:   AnimationOffsets,
	animationFrames:    AnimationFrames,
	currentAnimation:   AnimationInfo,
	isFrameActive:      proc(anim: ^Animatable) -> bool,
	addAnimation:       proc(anim: ^Animatable, name: string, info: IAddAnimation),
	playAnimation:      proc(anim: ^Animatable, name: string),
	// resetAnimations:      proc(anim: ^Animatable),
	// updateAnimationFrame: proc(anim: ^Animatable),
}

createAnimatable :: proc(
	parentWidth: i32,
	parentHeight: i32,
	animationFrames: AnimationFrames,
) -> Animatable {

	animationOffsets := AnimationOffsets {
		x = parentWidth / animationFrames.hFrames,
		y = parentHeight / animationFrames.vFrames,
	}
	return Animatable {
		animationFrames = animationFrames,
		animationOffsets = animationOffsets,
		isFrameActive = isFrameActive,
		addAnimation = addAnimation,
		playAnimation = playAnimation,
	}
}

playAnimation :: proc(anim: ^Animatable, name: string) {
	if animation, ok := anim.animations[name]; ok {
		if name == anim.currentAnimation.name {
			return
		}

		anim.currentAnimation = animation
		resetAnimations(anim)
	}
}
isFrameActive :: proc(anim: ^Animatable) -> bool {
	if anim.currentAnimation.maxFrames == 0 {return false}
	return anim.currentAnimation.activeFrame == anim.currentFrame
}

IAddAnimation :: struct {
	maxFrames:      i32,
	frameCoords:    rl.Vector2,
	animationSpeed: i32,
	activeFrame:    i32,
}

addAnimation :: proc(anim: ^Animatable, name: string, info: IAddAnimation) {

	anim.animations[name] = {
		maxFrames      = info.maxFrames,
		name           = name,
		frameCoords    = info.frameCoords,
		animationSpeed = info.animationSpeed,
		activeFrame    = info.activeFrame,
		animationPath  = createAnimationPath(anim, info),
	}

}
createAnimationPath :: proc(anim: ^Animatable, info: IAddAnimation) -> [dynamic]rl.Rectangle {
	using anim

	rectArr: [dynamic]rl.Rectangle
	currentCol := info.frameCoords.x
	currentRow := info.frameCoords.y

	for i in 0 ..< info.maxFrames {

		xStart := i32(currentCol) * animationOffsets.x
		yStart := i32(currentRow) * animationOffsets.y

		append(
			&rectArr,
			rl.Rectangle {
				f32(xStart),
				f32(yStart),
				f32(animationOffsets.x),
				f32(animationOffsets.y),
			},
		)
		currentCol += 1
		// if xStart >= texture.width {
		// 	currentRow += 1
		// 	currentCol = 0
		// }

	}
	return rectArr
}
resetAnimations :: proc(anim: ^Animatable) {
	using anim
	currentFrame = 0
	frameCounter = 0
	// clear(&animationPath)
}

updateAnimationFrame :: proc(anim: ^Animatable) {
	using anim

	frameCounter += 1
	if frameCounter > (60 / currentAnimation.animationSpeed) {
		frameCounter = 0
		if currentFrame >= currentAnimation.maxFrames {
			currentFrame = 0
			isAnimationPlaying = false
		}

		isAnimationPlaying = true
		currentFrame += 1
	}


}
