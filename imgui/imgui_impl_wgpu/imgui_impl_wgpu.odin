package imgui_impl_wgpu

import imgui "../"
import "vendor:wgpu"

when      ODIN_OS == .Windows do foreign import lib "../imgui_windows_x64.lib"
else when ODIN_OS == .Linux   do foreign import lib "../imgui_linux_x64.a"
else when ODIN_OS == .Darwin {
	when ODIN_ARCH == .amd64 { foreign import lib "../imgui_darwin_x64.a" } else { foreign import lib "../imgui_darwin_arm64.a" }
}

// imgui_impl_wgpu.h
// Last checked 357f752

@(link_prefix="ImGui_ImplWGPU_")
foreign lib {
    Init           :: proc(device: wgpu.Device, num_frames_in_flight: i32, rt_format: wgpu.TextureFormat, depth_format: wgpu.TextureFormat) -> bool ---
    Shutdown       :: proc() ---
    NewFrame       :: proc() ---
    RenderDrawData :: proc(draw_data: ^imgui.DrawData, pass_encoder: wgpu.RenderPassEncoder) ---

    // Use if you want to reset your rendering device without losing Dear ImGui state.
    InvalidateDeviceObjects :: proc() ---
    CreateDeviceObjects     :: proc() -> bool ---
}
