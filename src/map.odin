package main

import ldtk "../ldtk"
import "constants"
import "core:fmt"
import "core:path/filepath"
import "core:path/slashpath"
import "core:strings"
import rl "vendor:raylib"

TileMap :: struct {
	layers: [dynamic][]tile,
}
tile :: struct {
	texture: rl.Texture2D,
	src:     rl.Vector2,
	dst:     rl.Vector2,
	flip_x:  bool,
	flip_y:  bool,
}

tile_offset: rl.Vector2
tile_size := 32
tile_columns := -1
tile_rows := -1
collision_tiles: []u8

tileMap: TileMap
offset: rl.Vector2 = {f32(constants.SCREEN_WIDTH - i32(tile_size * tile_columns)) / 2.0, 0}

loadMap :: proc() {

	if project, ok := ldtk.load_from_file("maps/test.ldtk", context.temp_allocator); ok {
		for level in project.levels {
			for layer in level.layer_instances {
				switch layer.type {
				case .IntGrid:
				case .Entities:
				//Tile_Instance{d = [1367, 0], f = 0, px = [64, 464], src = [96, 112], t = 286}
				case .Tiles:
					tile_columns = layer.c_width
					tile_rows = layer.c_height
					//tile_size = 720 / tile_rows
					collision_tiles = make([]u8, tile_columns * tile_rows)
					tile_offset.x = f32(layer.px_total_offset_x)
					tile_offset.y = f32(layer.px_total_offset_y)
					for val, idx in layer.int_grid_csv {
						collision_tiles[idx] = u8(val)
					}

					// TODO: This need do be tracked in the map struct
					// Gets overridden by itself
					tile_data: []tile = make([]tile, len(layer.grid_tiles))

					b := strings.builder_make()
					defer strings.builder_destroy(&b)

					// TODO: find a better way to write abs path 
					//Removed the ../ from relative path
					fmt.sbprintf(&b, "%s", layer.tileset_rel_path[3:])
					fmt.println("ok", strings.to_cstring(&b))
					texture := rl.LoadTexture(strings.to_cstring(&b))


					multiplier: f32 = f32(tile_size) / f32(layer.grid_size)
					for val, idx in layer.grid_tiles {
						tile_data[idx].texture = texture
						tile_data[idx].dst.x = f32(val.px.x) * multiplier
						tile_data[idx].dst.y = f32(val.px.y) * multiplier
						tile_data[idx].src.x = f32(val.src.x)
						f := val.f
						tile_data[idx].src.y = f32(val.src.y)
						tile_data[idx].flip_x = bool(f & 1)
						tile_data[idx].flip_y = bool(f & 2)
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

			source_rect: rl.Rectangle = {val.src.x, val.src.y, 8.0, 8.0}
			if val.flip_x {
				source_rect.width *= -1.0
			}
			if val.flip_y {
				source_rect.height *= -1.0
			}
			dst_rect: rl.Rectangle = {
				val.dst.x + offset.x + tile_offset.x,
				val.dst.y + offset.y + tile_offset.y,
				f32(tile_size),
				f32(tile_size),
			}

			rl.DrawTexturePro(
				val.texture,
				source_rect,
				dst_rect,
				{f32(tile_size / 2), f32(tile_size / 2)},
				0,
				rl.WHITE,
			)
		}
	}
}
