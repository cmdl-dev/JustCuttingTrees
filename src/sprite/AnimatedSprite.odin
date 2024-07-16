package sprite

import aesprite "../../aesprite"
import "../shared"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

import path "core:path/filepath"
import rl "vendor:raylib"

importsPath :: "assetImports/"

AnimatedSprite :: struct {
	using sprite:     Sprite,
	using animatable: Animatable,
	draw:             proc(sprite: ^AnimatedSprite),
	getWidth:         proc(sprite: ^AnimatedSprite) -> i32,
	getHeight:        proc(sprite: ^AnimatedSprite) -> i32,
}

isPNG :: proc(ext: string) -> bool {
	return ext == ".png"
}
isJSON :: proc(ext: string) -> bool {
	return ext == ".json"
}

SpriteInfoImports :: struct {
	fileLocation:         string,
	aespriteJsonLocation: string,
	fileName:             string,
	variant:              []string,
}

loadSpriteInfoFromFile :: proc(
	filename: string,
	allocator := context.allocator,
) -> (
	SpriteInfoImports,
	bool,
) {
	data, ok := os.read_entire_file(filename, allocator)
	if !ok {
		return SpriteInfoImports{}, false
	}
	return loadSpriteInfoFromMemory(data, allocator)
}

loadSpriteInfoFromMemory :: proc(
	data: []byte,
	allocator := context.allocator,
) -> (
	SpriteInfoImports,
	bool,
) {
	result: SpriteInfoImports
	err := json.unmarshal(data, &result, json.DEFAULT_SPECIFICATION, allocator)
	if err == nil {
		return result, true
	}
	return SpriteInfoImports{}, false
}

AnimationFileResult :: struct {
	pngPath:  string,
	jsonPath: string,
}
// Gets the .png files and .json files
// Create anim(AvailableSprites.trees)
getAnimationFiles :: proc(name: string) -> (AnimationFileResult, bool) {
	if absPath, ok := path.abs(importsPath); ok {
		pngPath: string
		jsonPath: string

		filePath := path.join({absPath, strings.concatenate({name, ".json"})})
		info, ok := loadSpriteInfoFromFile(filePath)

		if pngPath, ok = path.abs(
			path.join({info.fileLocation, strings.concatenate({info.fileName, ".png"})}),
		); !ok {
			return AnimationFileResult{}, false
		}

		if jsonPath, ok = path.abs(
			path.join({info.aespriteJsonLocation, strings.concatenate({info.fileName, ".json"})}),
		); !ok {
			return AnimationFileResult{}, false
		}

		return AnimationFileResult{pngPath = pngPath, jsonPath = jsonPath}, true
	}
	return AnimationFileResult{}, false
}

createAnimatedSprite :: proc(name: string, initialPosition: rl.Vector2) -> (AnimatedSprite, bool) {
	absPath, foundFiles := getAnimationFiles(name)

	assert(foundFiles, strings.concatenate({"Could not load Animation File for: ", name}))


	data, ok := aesprite.loadFromFile(absPath.jsonPath)
	if !ok {
		return AnimatedSprite{}, false
	}

	sprite := createSprite(shared.stringToCString(absPath.pngPath), initialPosition)


	animatable := createAnimatable(
	sprite.texture.width,
	sprite.texture.height,
	//TODO: Refactor this. Not needed
	{vFrames = 1, hFrames = i32(len(data.frames))},
	)

	animationFrames := make([]rl.Rectangle, len(data.frames))
	// defer delete(animationFrames)

	for frame, idx in data.frames {
		animationFrames[idx] = rl.Rectangle {
			f32(frame.frame.x),
			f32(frame.frame.y),
			f32(frame.frame.w),
			f32(frame.frame.h),
		}
	}

	for frameTags in data.meta.frameTags {
		maxFrames :=
			1 if frameTags.to == frameTags.from else i32(frameTags.to - frameTags.from + 1)
		animInfo: IAddAnimation = {
			maxFrames      = maxFrames,
			frameCoords    = {f32(frameTags.from), 0},
			animationSpeed = 10,
			activeFrame    = 0,
			animationPath  = animationFrames[frameTags.from:frameTags.to + 1],
		}

		if data, ok := frameTags.data.?; ok {
			animInfo.activeFrame = i32(strconv.atoi(data))
		}

		animatable->addAnimation(frameTags.name, animInfo)

	}
	return {
			sprite = sprite,
			animatable = animatable,
			draw = drawAnimatedSprite,
			getWidth = getWidth,
			getHeight = getHeight,
		},
		true


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
