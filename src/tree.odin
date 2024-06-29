package main

import "core:fmt"
import "shared"
import "sprite"
import rl "vendor:raylib"

Cuttable :: struct {
	health: int,
	onCut:  proc(tree: ^Tree) -> (success: bool, reward: [dynamic]TreeReward),
}
createCuttable :: proc(health: int) -> Cuttable {
	return {health = health}
}

LogType :: enum {
	REGULAR,
	WILLOW,
}
LogInfo :: struct {
	value:  i32,
	weight: f32,
}

LogToValueMap: map[LogType]LogInfo = {
	LogType.REGULAR = {1, 10.0},
	LogType.WILLOW  = {3, 14.0},
}
TreeReward :: struct {
	logType: LogType,
	info:    LogInfo,
}
createLogReward :: proc(type: LogType) -> TreeReward {

	return {type, LogToValueMap[type]}
}

TreeState :: enum {
	GROWN,
	CUT,
	GROWING,
}
Tree :: struct {
	using actor:    Actor,
	using cuttable: Cuttable,
	state:          TreeState,
	area:           Area2D,
	reward:         [dynamic]TreeReward,
	sprite:         sprite.AnimatedSprite,
	draw:           proc(tree: ^Tree),
	onInteractable: proc(tree: ^Tree, actor: ^Player),
	isDead:         proc(tree: ^Tree) -> bool,
	onTreeDeath:    proc(tree: ^Tree),
}


createTree :: proc(fileName: cstring, treeHealth: int, initialPosition: shared.IVector2) -> Tree {
	actor := createActor(initialPosition)
	cuttable := createCuttable(treeHealth)
	sprite := sprite.createAnimatedSprite(fileName, initialPosition, {hFrames = 4, vFrames = 3})
	area2D := createArea2D(
		AreaType.INTERACTION,
		rl.Rectangle{initialPosition.x, initialPosition.y, 32, 32},
		{sprite->getWidth(), sprite->getHeight()},
		true,
	)
	// Update the area2d to be centered
	area2D->update(initialPosition)

	return {
		actor = actor,
		cuttable = cuttable,
		draw = drawTree,
		area = area2D,
		sprite = sprite,
		onInteractable = onInteractable,
		isDead = isTreeDead,
	}
}

isTreeDead :: proc(tree: ^Tree) -> bool {
	return tree.health <= 0
}
onInteractable :: proc(tree: ^Tree, player: ^Player) {
	success, reward := tree->onCut()
	tree.sprite->playAnimation("cut")
	if (success) {
		tree->onTreeDeath()
		player->addReward(reward)
		fmt.println("Reward type", reward)
	}

}

drawTree :: proc(tree: ^Tree) {
	using tree
	sprite->draw()
	area->draw()
}

RegularTree :: struct {
	using tree: Tree,
}


createRegularTree :: proc(initialPosition: shared.IVector2) -> RegularTree {
	fileName := cstring("assets/Resources/Trees/Tree.png")
	treeHealth := 2

	tree := createTree(fileName, treeHealth, initialPosition)
	tree.sprite->addAnimation(
		"idle",
		{maxFrames = 4, frameCoords = {0, 0}, animationSpeed = 6, activeFrame = -1},
	)
	tree.sprite->addAnimation(
		"hit",
		{maxFrames = 2, frameCoords = {0, 1}, animationSpeed = 6, activeFrame = -1},
	)
	tree.sprite->addAnimation(
		"stump",
		{maxFrames = 1, frameCoords = {0, 2}, animationSpeed = 6, activeFrame = -1},
	)

	tree.sprite->playAnimation("idle")
	tree.onTreeDeath = onRegularTreeDeath

	reward := createLogReward(LogType.REGULAR)
	append(&tree.reward, reward)
	tree.cuttable.onCut = onCutRegularTree
	return {tree = tree}
}

onRegularTreeDeath :: proc(tree: ^Tree) {
	fmt.println("I diead")
}

onCutRegularTree :: proc(tree: ^Tree) -> (success: bool, reward: [dynamic]TreeReward) {

	success = false
	reward = {}

	// it shouldn't be on the screen, but still checking for it 
	if tree.state != TreeState.GROWN {
		return
	}

	tree.health -= 1
	if (tree.health <= 0) {
		tree.state = TreeState.CUT
		reward = tree.reward
		success = true
	}
	return
}
