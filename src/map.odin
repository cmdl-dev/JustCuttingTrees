package main

import "core:fmt"
import path "core:path/filepath"

import ldtk "../ldtk"
import "shared"
import rl "vendor:raylib"

TileMap :: struct {
	layers:                [dynamic][]Tile,
	draw:                  proc(tileMap: ^TileMap),
	collision:             CollisionTiles,
	playerInitialLocation: rl.Vector2,
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
					for entities in layer.entity_instances {
						if entities.identifier == "Player" {
							tileMap.playerInitialLocation.x = f32(entities.px.x)
							tileMap.playerInitialLocation.y = f32(entities.px.y)
						}

					}
				case .Tiles:
					// TODO: find a better way to write abs path 
					//Removed the ../ from relative path
					absPath, ok := path.abs(layer.tileset_rel_path[3:])
					assert(ok, "Could not load file")

					texturePath := shared.stringToCString(absPath)

					texture := rl.LoadTexture(texturePath)
					assert(texture.width != 0, "Could not load texture")

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
	tileMap.draw = drawMap
	return tileMap
}

drawMap :: proc(tileMap: ^TileMap) {
	#reverse for tileData, idx in tileMap.layers {
		for val, idk in tileData {
			rl.DrawTextureRec(val.texture, val.rect, val.position, rl.WHITE)
		}
	}

	row := 0
	col := 0
	for rect, idx in tileMap.collision.locations {
		rl.DrawRectangleRec(rect, rl.RED)
	}
}
