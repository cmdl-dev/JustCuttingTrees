package main

import "core:fmt"
import "core:slice"
import "shared"

import path "core:path/filepath"
import rl "vendor:raylib"

import ldtk "../ldtk"

TileMap :: struct {
	layers:                [dynamic][]Tile,
	collision:             CollisionTiles,
	playerInitialLocation: rl.Vector2,
	playableMapRect:       rl.Rectangle,
	totalMapRect:          rl.Rectangle,
	draw:                  proc(tileMap: ^TileMap),
}
CollisionTiles :: struct {
	locations: [dynamic]rl.Rectangle,
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
	TotalAreaBounds,
}


creatTileMap :: proc(level: string) -> TileMap {
	tileMap: TileMap
	enumTagValueMap := make(map[string][]int)
	defer delete(enumTagValueMap)
	collisionTiles: [dynamic]rl.Rectangle

	if project, ok := ldtk.load_from_file(level); ok {
		for ts in project.defs.tilesets {
			// Store enum tags information
			for enums in ts.enum_tags {
				switch enums.enum_value_id {
				case "Collision":
					enumTagValueMap["OnGroundDeco"] = enums.tile_ids
				}
			}
		}

		for level in project.levels {
			for layer in level.layer_instances {
				switch layer.type {
				case .IntGrid:
					tileMap.collision.width = layer.c_width
					tileMap.collision.height = layer.c_height

					tileMap.collision.gridSize = layer.grid_size
					//tile_size = 720 / tile_rows

					row := 0
					col := 0
					taArr: [dynamic]rl.Vector2 = {}
					paArr: [dynamic]rl.Vector2 = {}
					for val, idx in layer.int_grid_csv {
						if IntGridValues(val) == .Collision {
							append(
								&collisionTiles,
								rl.Rectangle {
									f32(col * layer.grid_size),
									f32(row * layer.grid_size),
									f32(layer.grid_size),
									f32(layer.grid_size),
								},
							)
						}
						if IntGridValues(val) == .TotalAreaBounds {
							append(
								&taArr,
								rl.Vector2{f32(col * layer.grid_size), f32(row * layer.grid_size)},
							)
						}
						if IntGridValues(val) == .MiniMapBounds {
							append(
								&paArr,
								rl.Vector2{f32(col * layer.grid_size), f32(row * layer.grid_size)},
							)
						}
						if col >= layer.c_width {
							col = 0
							row += 1
						}

						col += 1
					}
					assert(len(taArr) == 2, "Total Area Bounds not set properly")
					assert(len(paArr) == 2, "Player Area Bounds not set properly")


					tileMap.totalMapRect = {
						taArr[0].x,
						taArr[0].y,
						getMapSizes(taArr).x,
						getMapSizes(taArr).y,
					}

					tileMap.playableMapRect = {
						paArr[0].x,
						paArr[0].y,
						getMapSizes(paArr).x,
						getMapSizes(paArr).y,
					}

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
						if enumVals, ok := enumTagValueMap[layer.identifier]; ok {
							if slice.contains(enumVals, val.t) {
								fmt.println("Collision on ", val.src)

								append(
									&collisionTiles,
									rl.Rectangle {
										f32(val.px.x),
										f32(val.px.y),
										f32(layer.grid_size),
										f32(layer.grid_size),
									},
								)
							}


						}
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

	tileMap.collision.locations = collisionTiles
	tileMap.draw = drawMap
	return tileMap
}

getMapSizes :: proc(bounds: [dynamic]rl.Vector2) -> rl.Vector2 {
	width := bounds[1].x - bounds[0].x
	height := bounds[1].y - bounds[0].y

	return rl.Vector2{width, height}
}

// Draw the camera lines
drawMiniMap :: proc(gState: ^GameState) {
	using gState
	rl.BeginTextureMode(renderTexture)
	width := renderTexture.texture.width
	height := renderTexture.texture.height


	playableSize := gState.level.playableMapRect
	// Setting scale based on the width of the texture and the width of the screen 
	scaleSize :=
		[2]f32{f32(width), f32(height)} / [2]f32{f32(playableSize.width), f32(playableSize.height)}

	// Were the playable area is with relation to the 0,0 point
	offset := rl.Vector2{playableSize.x * scaleSize.x, playableSize.y * scaleSize.y}

	// Getting topleft position of the camera
	camPos := rl.GetScreenToWorld2D({0, 0}, camera)
	// Getting the percentage of where the camera is compared to the screen
	// If the camera is on 0,0 then it is 0% of the screen, if camera is in the middle of the screen then it would be 50%
	percent: [2]f32 = camPos.xy / {f32(playableSize.width), f32(playableSize.height)}

	// Making a scale version of the camera
	cameraDimension :=
		[2]f32{f32(rl.GetScreenWidth()) / camera.zoom, f32(rl.GetScreenHeight()) / camera.zoom} *
		scaleSize


	rl.ClearBackground(rl.SKYBLUE)

	// Drawing the lines
	rl.DrawRectangleLines(
		i32(f32(width) * (percent.x)) - i32(offset.x),
		i32(f32(height) * (percent.y)) - i32(offset.y),
		i32(cameraDimension.x),
		i32(cameraDimension.y),
		rl.BLACK,
	)
	for &tree in trees {
		treePos := tree.position

		if !tree->isDead() {

			rl.DrawRectangle(
				i32(f32(treePos.x) * (scaleSize.x)) - i32(offset.x),
				i32(f32(treePos.y) * (scaleSize.y)) - i32(offset.y),
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
