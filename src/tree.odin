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

LogAnim :: struct {
	sprite:   sprite.AnimatedSprite,
	isActive: bool,
}

createLogAnimation :: proc(initialPosition: rl.Vector2) -> LogAnim {
	sprite, ok := sprite.createAnimatedSprite("log", initialPosition)
	if !ok {
		fmt.println("Create wood not ok")
	}

	return LogAnim{sprite = sprite, isActive = false}
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
	log:            LogAnim,
	reward:         [dynamic]TreeReward,
	sprite:         sprite.AnimatedSprite,
	draw:           proc(tree: ^Tree),
	onInteractable: proc(tree: ^Tree, actor: ^Player),
	isDead:         proc(tree: ^Tree) -> bool,
	onTreeDeath:    proc(tree: ^Tree),
}


createTree :: proc(fileName: cstring, treeHealth: int, initialPosition: rl.Vector2) -> Tree {

	baseOffset := rl.Vector2{0, 70}
	pos := initialPosition + baseOffset

	actor := createActor(pos)
	cuttable := createCuttable(treeHealth)

	sprite, ok := sprite.createAnimatedSprite(string(fileName), pos)
	if !ok {
		fmt.println("could not create animated sprite")
	}
	area2D := createArea2D(AreaType.INTERACTION, {0, 0}, rl.Rectangle{pos.x, pos.y, 32, 32})
	translate(&area2D, baseOffset)
	area2D->update({0, 0})

	log := createLogAnimation(initialPosition)
	log.sprite->playAnimation("W_Spawn")
	return {
		actor = actor,
		cuttable = cuttable,
		log = log,
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
onUpdate :: proc(tree: ^Tree) {
	if tree->isDead() {
		tree.sprite->playAnimation("Chopped")
		return

	}

}

// TODO: update the add reward from tree to log
onInteractable :: proc(tree: ^Tree, player: ^Player) {
	success, reward := tree->onCut()
	tree.sprite->playAnimation("Hit")
	if (success) {
		tree->onTreeDeath()
		player->addReward(reward)
	}

}

drawTree :: proc(tree: ^Tree) {
	tree.sprite->draw()
	tree.area->draw()

	if tree.log.isActive {
		tree.log.sprite->draw()
		if sprite.eventOccured(&tree.sprite, sprite.AnimationEventKeys.FINISHED) {
			tree.log.sprite->playAnimation("W_Idle")
		}
	}
}

RegularTree :: struct {
	using tree: Tree,
}


createRegularTree :: proc(initialPosition: rl.Vector2) -> RegularTree {
	treeHealth := 2

	tree := createTree("regularTree", treeHealth, initialPosition)

	tree.sprite->playAnimation("Idle")
	tree.onTreeDeath = onRegularTreeDeath

	reward := createLogReward(LogType.REGULAR)
	append(&tree.reward, reward)
	tree.cuttable.onCut = onCutRegularTree
	return {tree = tree}
}

onRegularTreeDeath :: proc(tree: ^Tree) {
	// TODO: spawn a tree logs on the floor
	tree.log.isActive = true
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
