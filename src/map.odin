package main

import ldtk "../ldtk"
import "constants"
import "core:fmt"
import "core:path/filepath"
import "core:path/slashpath"
import "core:strings"
import rl "vendor:raylib"

TileMap :: struct {
	layers: [dynamic][]Tile,
}
Tile :: struct {
	texture:  rl.Texture2D,
	rect:     rl.Rectangle,
	position: rl.Vector2,
}

tile_size := 32
collision_tiles: []u8

tileMap: TileMap

loadMap :: proc() {

	if project, ok := ldtk.load_from_file("maps/test.ldtk", context.temp_allocator); ok {
		for level in project.levels {
			for layer in level.layer_instances {
				switch layer.type {
				case .IntGrid:
				case .Entities:
				//Tile_Instance{d = [1367, 0], f = 0, px = [64, 464], src = [96, 112], t = 286}
				case .Tiles:
					b := strings.builder_make()
					defer strings.builder_destroy(&b)

					// TODO: find a better way to write abs path 
					//Removed the ../ from relative path
					fmt.sbprintf(&b, "%s", layer.tileset_rel_path[3:])
					fmt.println("ok", strings.to_cstring(&b))
					texture := rl.LoadTexture(strings.to_cstring(&b))

					tile_data: []Tile = make([]Tile, len(layer.grid_tiles))
					multiplier: f32 = f32(tile_size) / f32(layer.grid_size)
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
}


drawMap :: proc() {
	#reverse for tileData, idx in tileMap.layers {
		for val, idk in tileData {
			rl.DrawTextureRec(val.texture, val.rect, val.position, rl.WHITE)
		}
	}
}
