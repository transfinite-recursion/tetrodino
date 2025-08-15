package tetrodino

import rl "vendor:raylib"

import "core:c"

Area :: struct {
    left_x, top_y, width, height: f32
}

subarea_with_padding :: proc(base: Area, padding: f32) -> Area {
    absolute := padding / 100.0 * min(base.width, base.height);
    return Area {
        left_x = base.left_x + absolute/2.0, top_y = base.top_y + absolute/2.0,
        width = base.width - absolute, height = base.height - absolute,
    };
}

subarea_with_aspect_ratio :: proc(base: Area, aspect_ratio: f32) -> (result: Area) {
    result.width = min(base.width, base.height * aspect_ratio);
    result.height = result.width / aspect_ratio;
    result.left_x = base.left_x + (base.width - result.width) / 2.0;
    result.top_y = base.top_y + (base.height - result.height) / 2.0;
    return;
}

area_to_raylib_rectangle :: proc(area: Area) -> rl.Rectangle {
    return rl.Rectangle{
        x = area.left_x, y = area.top_y,
        width = area.width, height = area.height
    };
}

draw_text :: proc(
    text: cstring, area: Area, text_height: f32, x: f32, y: f32, color: rl.Color
) {
    th := c.int(text_height * area.height);
    tw := rl.MeasureText(text, th);
    tx := c.int(area.left_x + x * area.width - f32(tw) / 2.0);
    ty := c.int(area.top_y + y * area.height - f32(th) / 2.0);
    rl.DrawText(text, tx, ty, th, color);
}
