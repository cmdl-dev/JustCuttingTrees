package main

import "core:fmt"
import "shared"
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
	sprite:         Sprite,
	draw:           proc(tree: ^Tree),
	onInteractable: proc(tree: ^Tree, actor: ^Player),
	isDead:         proc(tree: ^Tree) -> bool,
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
		isDead = isTreeDead,
	}
}

isTreeDead :: proc(tree: ^Tree) -> bool {
	return tree.health <= 0
}
onInteractable :: proc(tree: ^Tree, player: ^Player) {
	success, reward := tree->onCut()
	if (success) {
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
	fileName := cstring("assets/trees_trans.png")
	treeHealth := 10

	tree := createTree(fileName, treeHealth, initialPosition)
	tree.sprite->setRect(0, 0, 3, 7)
	tree.sprite->setTileSize(8)
	tree.sprite->setScale(2)

	reward := createLogReward(LogType.REGULAR)
	append(&tree.reward, reward)
	tree.cuttable.onCut = onCutRegularTree
	return {tree = tree}
}

onCutRegularTree :: proc(tree: ^Tree) -> (success: bool, reward: [dynamic]TreeReward) {

	success = false
	reward = {}

	// it shouldn't be on the screen, but still checking for it 
	if tree.state != TreeState.GROWN {
		return
	}

	tree.health -= 1
	fmt.println("Remaining health", tree.health)
	if (tree.health <= 0) {
		tree.state = TreeState.CUT
		reward = tree.reward
		success = true
	}
	return
}
