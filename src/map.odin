package main

import ldtk "../ldtk"
import "constants"
import "core:fmt"
import "core:path/filepath"
import "core:path/slashpath"
import "core:strings"
import "shared"
import rl "vendor:raylib"

TileMap :: struct {
	layers:    [dynamic][]Tile,
	draw:      proc(tileMap: ^TileMap),
	collision: CollisionTiles,
}
CollisionTiles :: struct {
	locations: []rl.Rectangle,
	width:     int,
	height:    int,
	gridSize:  int,
}

Tile :: struct {
	texture:  rl.Texture2D,
	rect:     rl.Rectangle,
	position: rl.Vector2,
}


creatTileMap :: proc(level: string) -> TileMap {
	tileMap: TileMap
	if project, ok := ldtk.load_from_file(level, context.temp_allocator); ok {

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
						if val != 0 {
							collisionTiles[idx] = rl.Rectangle {
								f32(col * layer.grid_size),
								f32(row * layer.grid_size),
								f32(layer.grid_size),
								f32(layer.grid_size),
							}
						}
						if col >= layer.c_width {
							col = 0
							row += 1
						}

						col += 1
					}
					tileMap.collision.locations = collisionTiles

				case .Entities:
				case .Tiles:
					// TODO: find a better way to write abs path 
					//Removed the ../ from relative path
					texturePath := shared.stringToCString(layer.tileset_rel_path[3:])
					texture := rl.LoadTexture(texturePath)

					tile_data: []Tile = make([]Tile, len(layer.grid_tiles))
					for val, idx in layer.grid_tiles {
						tile_data[idx].texture = texture
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
	tileMap.draw = drawMap
	return tileMap
}

drawMap :: proc(tileMap: ^TileMap) {
	#reverse for tileData, idx in tileMap.layers {
		for val, idk in tileData {
			rl.DrawTextureRec(val.texture, val.rect, val.position, rl.WHITE)
		}
	}

	//row := 0
	//col := 0
	for rect, idx in tileMap.collision.locations {
		rl.DrawRectangleRec(rect, rl.RED)
	}
}
