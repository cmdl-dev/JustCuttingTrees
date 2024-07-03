package aesprite

import "core:encoding/json"
import "core:os"

load_from_file :: proc(
	filename: string,
	allocator := context.allocator,
) -> (
	AespriteProject,
	bool,
) {
	data, ok := os.read_entire_file(filename, allocator)
	if !ok {
		return AespriteProject{}, false
	}
	return load_from_memory(data, allocator)
}

load_from_memory :: proc(data: []byte, allocator := context.allocator) -> (AespriteProject, bool) {
	result: AespriteProject
	err := json.unmarshal(data, &result, json.DEFAULT_SPECIFICATION, allocator)
	if err == nil {
		return result, true
	}
	return AespriteProject{}, false
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
	// x,y,w,h format
	fileName:         string `json:"fileName"`,
	frame:            FrameSize `json:"frame"`,
	rotated:          bool `json:"rotated"`,
	trimmed:          bool `json:"trimmed"`,
	spriteSourceSize: FrameCoordsSize `json:"spriteSourceSize"`,
	sourceSize:       FrameCoords `json:"sourceSize"`,
	duration:         int `json:"duration"`,
}
