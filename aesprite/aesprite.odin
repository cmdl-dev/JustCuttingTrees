package aesprite

import "core:encoding/json"
import "core:fmt"
import "core:os"

AespriteError :: enum {
	None,
	UnmarshalError,
	ReadFileError,
}

loadFromFile :: proc(
	filename: string,
	allocator := context.allocator,
) -> (
	AespriteProject,
	AespriteError,
) {
	data, ok := os.read_entire_file(filename, allocator)
	if !ok {
		return AespriteProject{}, .ReadFileError
	}
	return loadFromMemory(data, allocator)
}

loadFromMemory :: proc(
	data: []byte,
	allocator := context.allocator,
) -> (
	AespriteProject,
	AespriteError,
) {
	result: AespriteProject
	err := json.unmarshal(data, &result, json.DEFAULT_SPECIFICATION, allocator)

	if err != nil {
		return AespriteProject{}, .UnmarshalError
	}
	return result, .None
}

AespriteProject :: struct {
	frames: []Frame `json:"frames"`,
	meta:   MetaInformation `json:"meta"`,
}
MetaInformation :: struct {
	app:       string `json:"frame"`,
	version:   string `json:"version"`,
	format:    string `json:"format"`,
	size:      FrameSize `json:"size"`,
	scale:     f32 `json:"scale"`,
	frameTags: []FrameTag `json:"frameTags"`,
	layers:    []Layer `json:"layers"`,
	slices:    []struct {} `json:"slices"`,
}
Layer :: struct {
	name:      string `json:"name"`,
	opacity:   int `json:"opacity"`,
	blendMode: string `json:"blendMode"`,
}
FrameTag :: struct {
	name:      string `json:"name"`,
	from:      int `json:"from"`,
	to:        int `json:"to"`,
	direction: string `json:"direction"`,
	color:     string `json:"color"`,
	data:      Maybe(string) `json:"data"`,
}
FrameCoordsSize :: struct {
	x: int `json:"x"`,
	y: int `json:"y"`,
	w: int `json:"w"`,
	h: int `json:"h"`,
}
FrameSize :: struct {
	w: int `json:"w"`,
	h: int `json:"h"`,
}
FrameCoords :: struct {
	x: int `json:"x"`,
	y: int `json:"y"`,
}

Frame :: struct {
	fileName:         string `json:"filename"`,
	frame:            FrameCoordsSize `json:"frame"`,
	rotated:          bool `json:"rotated"`,
	trimmed:          bool `json:"trimmed"`,
	spriteSourceSize: FrameCoordsSize `json:"spriteSourceSize"`,
	sourceSize:       FrameSize `json:"sourceSize"`,
	duration:         int `json:"duration"`,
}
