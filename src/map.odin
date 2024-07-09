package main

import "core:fmt"
import "shared"

import path "core:path/filepath"
import rl "vendor:raylib"

import ldtk "../ldtk"

TileMap :: struct {
	layers:                [dynamic][]Tile,
	collision:             CollisionTiles,
	playerInitialLocation: rl.Vector2,
	playableMapBound:      [dynamic]rl.Vector2,
	draw:                  proc(tileMap: ^TileMap),
}
CollisionTiles :: struct {
	locations: []rl.Rectangle,
	width:     int,
	height:    int,
	gridSize:  int,
}

Tile :: struct {
	layerName: string,
	texture:   rl.Texture2D,
	rect:      rl.Rectangle,
	position:  rl.Vector2,
}

IntGridValues :: enum {
	Collision = 1,
	MiniMapBounds,
}

creatTileMap :: proc(level: string) -> TileMap {
	tileMap: TileMap
	if project, ok := ldtk.load_from_file(level); ok {

		for level in project.levels {
			for layer in level.layer_instances {
				switch layer.type {
				case .IntGrid:
					tileMap.collision.width = layer.c_width
					tileMap.collision.height = layer.c_height

					tileMap.collision.gridSize = layer.grid_size
					//tile_size = 720 / tile_rows
					collisionTiles := make(
						[]rl.Rectangle,
						tileMap.collision.width * tileMap.collision.height,
					)

					row := 0
					col := 0
					for val, idx in layer.int_grid_csv {
						if IntGridValues(val) == .Collision {
							collisionTiles[idx] = rl.Rectangle {
								f32(col * layer.grid_size),
								f32(row * layer.grid_size),
								f32(layer.grid_size),
								f32(layer.grid_size),
							}
						}
						if IntGridValues(val) == .MiniMapBounds {
							append(
								&tileMap.playableMapBound,
								rl.Vector2{f32(col * layer.grid_size), f32(row * layer.grid_size)},
							)
						}
						if col >= layer.c_width {
							col = 0
							row += 1
						}

						col += 1
					}
					tileMap.collision.locations = collisionTiles

				case .Entities:
					for entities in layer.entity_instances {
						if entities.identifier == "Player" {
							tileMap.playerInitialLocation.x = f32(entities.px.x)
							tileMap.playerInitialLocation.y = f32(entities.px.y)
						}

					}
				case .Tiles:
					absPath, ok := path.abs(layer.tileset_rel_path[3:])
					assert(ok, "Could not load file")

					texturePath := shared.stringToCString(absPath)

					texture := shared.loadTexture(texturePath)
					tile_data: []Tile = make([]Tile, len(layer.grid_tiles))
					for val, idx in layer.grid_tiles {
						tile_data[idx].texture = texture
						tile_data[idx].layerName = layer.identifier
						// Where its going to go on the screen 
						tile_data[idx].position = {f32(val.px.x), f32(val.px.y)}
						// What part of the map 
						tile_data[idx].rect = {
							f32(val.src.x),
							f32(val.src.y),
							f32(layer.grid_size),
							f32(layer.grid_size),
						}

					}
					append(&tileMap.layers, tile_data)
				case .AutoLayer:
				}
			}
		}
	}
	assert(len(tileMap.playableMapBound) == 2, "Map bounds not set")
	tileMap.draw = drawMap
	return tileMap
}

getPlayableMapRec :: proc(tileMap: ^TileMap) -> rl.Rectangle {
	width := tileMap.playableMapBound[1].x - tileMap.playableMapBound[0].x
	height := tileMap.playableMapBound[1].y - tileMap.playableMapBound[0].y

	return rl.Rectangle {
		tileMap.playableMapBound[0].x,
		tileMap.playableMapBound[0].y,
		width,
		height,
	}
}

// Draw the camera lines
drawMiniMap :: proc(gState: ^GameState) {
	using gState
	rl.BeginTextureMode(renderTexture)
	width := renderTexture.texture.width
	height := renderTexture.texture.height

	// Setting scale based on the width of the texture and the width of the screen 
	scaleSize :=
		[2]f32{f32(width), f32(height)} /
		[2]f32{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}

	fmt.println(width, height, rl.GetScreenWidth())
	// Getting topleft position of the camera
	camPos := rl.GetScreenToWorld2D({0, 0}, camera)
	// Getting the percentage of where the camera is compared to the screen
	// If the camera is on 0,0 then it is 0% of the screen, if camera is in the middle of the screen then it would be 50%
	percent: [2]f32 = camPos.xy / {f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}

	// Making a scale version of the camera
	cameraDimension :=
		[2]f32{f32(rl.GetScreenWidth()) / camera.zoom, f32(rl.GetScreenHeight()) / camera.zoom} *
		scaleSize


	rl.ClearBackground(rl.SKYBLUE)

	// Drawing the lines
	rl.DrawRectangleLines(
		i32(f32(width) * (percent.x)),
		i32(f32(height) * (percent.y)),
		i32(cameraDimension.x),
		i32(cameraDimension.y),
		rl.BLACK,
	)
	mapBounds := getPlayableMapRec(&gState.level)

	// fmt.println("mapbounds", mapBounds)
	// // fmt.println("boundaries", mapBounds, mapBounds * scaleSize)
	// rl.DrawRectangleLines(
	// 	i32(f32(mapBounds.x) * (scaleSize.x)),
	// 	i32(f32(mapBounds.y) * (scaleSize.y)),
	// 	i32(mapBounds.width * scaleSize.x),
	// 	i32(mapBounds.height * scaleSize.y),
	// 	rl.BLACK,
	// )

	for &tree in trees {
		treePos := tree.position

		if !tree->isDead() {

			rl.DrawRectangle(
				i32(f32(treePos.x) * (scaleSize.x)),
				i32(f32(treePos.y) * (scaleSize.y)),
				i32(4),
				i32(4),
				rl.BLACK,
			)
		}
	}


	rl.EndTextureMode()
}

drawMap :: proc(tileMap: ^TileMap) {
	#reverse for tileData, idx in tileMap.layers {
		for val, idk in tileData {
			rl.DrawTextureRec(val.texture, val.rect, val.position, rl.WHITE)
		}
	}

	for rect, idx in tileMap.collision.locations {
		rl.DrawRectangleRec(rect, rl.RED)
	}
}
