package main

import "shared"
import rl "vendor:raylib"

Cuttable :: struct {
	health: int,
	onCut:  proc(tree: ^Tree) -> [dynamic]TreeReward,
}
createCuttable :: proc(health: int) -> Cuttable {
	return {health = health}
}

TreeReward :: struct {}

Tree :: struct {
	using actor:    Actor,
	using cuttable: Cuttable,
	area:           Area2D,
	reward:         [dynamic]TreeReward,
	sprite:         Sprite,
	draw:           proc(tree: ^Tree),
	onInteractable: proc(tree: ^Tree, actor: ^Actor),
}


createTree :: proc(fileName: cstring, treeHealth: int, initialPosition: shared.IVector2) -> Tree {
	actor := createActor(initialPosition)
	cuttable := createCuttable(treeHealth)
	sprite := createSprite(fileName, initialPosition)
	area2D := createArea2D(
		AreaType.INTERACTION,
		rl.Rectangle{initialPosition.x, initialPosition.y, 32, 32},
	)

	return {actor = actor, cuttable = cuttable, sprite = sprite, draw = drawTree, area = area2D}
}

onInteractable :: proc(tree: ^Tree, actor: ^Actor) {
	reward := tree->onCut()
	// Do Something with reward
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
	tree.cuttable.onCut = onCutRegularTree
	return {tree = tree}
}

onCutRegularTree :: proc(tree: ^Tree) -> [dynamic]TreeReward {

	return tree.reward
}
