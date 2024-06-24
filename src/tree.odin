package main

import "core:fmt"
import "shared"
import rl "vendor:raylib"

Cuttable :: struct {
	health: int,
	onCut:  proc(tree: ^Tree) -> [dynamic]TreeReward,
}
createCuttable :: proc(health: int) -> Cuttable {
	return {health = health}
}

LogType :: enum {
	REGULAR,
}
TreeReward :: struct {
	logType: LogType,
}
createLogReward :: proc(type: LogType) -> TreeReward {

	return {type}
}

Tree :: struct {
	using actor:    Actor,
	using cuttable: Cuttable,
	area:           Area2D,
	reward:         [dynamic]TreeReward,
	sprite:         Sprite,
	draw:           proc(tree: ^Tree),
	onInteractable: proc(tree: ^Tree, actor: ^Player),
}


createTree :: proc(fileName: cstring, treeHealth: int, initialPosition: shared.IVector2) -> Tree {
	actor := createActor(initialPosition)
	cuttable := createCuttable(treeHealth)
	sprite := createSprite(fileName, initialPosition)
	area2D := createArea2D(
		AreaType.INTERACTION,
		rl.Rectangle{initialPosition.x, initialPosition.y, 32, 32},
	)

	return {
		actor = actor,
		cuttable = cuttable,
		sprite = sprite,
		draw = drawTree,
		area = area2D,
		onInteractable = onInteractable,
	}
}

onInteractable :: proc(tree: ^Tree, player: ^Player) {
	reward := tree->onCut()
	player->addReward(reward)
	fmt.println("Reward type", reward)

}

drawTree :: proc(tree: ^Tree) {
	using tree
	sprite->draw()
	area->draw()
}

RegularTree :: struct {
	using tree: Tree,
}


createRegularTree :: proc(
	fileName: cstring,
	treeHealth: int,
	initialPosition: shared.IVector2,
) -> RegularTree {
	tree := createTree(fileName, treeHealth, initialPosition)
	reward := createLogReward(LogType.REGULAR)
	append(&tree.reward, reward)
	tree.cuttable.onCut = onCutRegularTree
	return {tree = tree}
}

onCutRegularTree :: proc(tree: ^Tree) -> [dynamic]TreeReward {

	return tree.reward
}
