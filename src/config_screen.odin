package tetrodino

import rl "vendor:raylib"

import "core:fmt"

ConfigScreen :: struct {
    base: Screen,

    parent: ^Screen,

    selected: int,
    timer: Timer,
}

new_config_screen :: proc(parent: ^Screen) -> ^Screen {
    result := new(ConfigScreen);
    result.base.update = update_config_screen;
    result.base.draw = draw_config_screen;
    result.base.destroy = destroy_config_screen;
    result.parent = parent;
    result.timer.duration = 0.2;
    return cast(^Screen)(result);
}

update_config_screen :: proc(screen: ^Screen) -> ^Screen {
    using config_screen := cast(^ConfigScreen)(screen);
    if rl.IsKeyPressed(Config.mappings[.MenuCancel]) {
        p := parent;
        parent = nil;
        destroy_config_screen(screen);
        return p;
    }
    
    if rl.IsKeyPressed(Config.mappings[.MenuDown]) {
        selected = (selected + 1) % 4;
    }
    if rl.IsKeyPressed(Config.mappings[.MenuUp]) {
        selected = (selected + 3) % 4;
    }

    d: f32 = 0.0;
    if rl.IsKeyPressed(Config.mappings[.MenuLeft]) {
        timer.elapsed = 0.0; d -= 0.01;
    }
    if rl.IsKeyPressed(Config.mappings[.MenuRight]) {
        timer.elapsed = 0.0; d += 0.01;
    }
    if rl.IsKeyDown(Config.mappings[.MenuLeft]) {
        timer.elapsed += rl.GetFrameTime();
        for timer.elapsed >= timer.duration {
            timer.elapsed -= 0.1;
            d -= 0.01;
        }
    }
    if rl.IsKeyDown(Config.mappings[.MenuRight]) {
        timer.elapsed += rl.GetFrameTime();
        for timer.elapsed >= timer.duration {
            timer.elapsed -= 0.1;
            d += 0.01;
        }
    }
    
    if selected == 0 {
        if rl.IsKeyPressed(Config.mappings[.MenuConfirm]) {
            rl.ToggleFullscreen();
            Config.full_screen ~= true;
        }
    } else if selected == 1 {
        Config.das = max(Config.das + d, 0.0);
    } else if selected == 2 {
        Config.arr = max(Config.arr + d, 0.01);
    } else if selected == 3 {
        if rl.IsKeyPressed(Config.mappings[.MenuConfirm]) {
            return new_change_controls_screen(cast(^Screen)(config_screen));
        }
    }
    return screen;
}

draw_config_screen :: proc(screen: ^Screen) {
    using config_screen := cast(^ConfigScreen)(screen);
    rl.ClearBackground(rl.VIOLET);

    window_area := Area{
        left_x = 0.0, top_y = 0.0,
        width = f32(rl.GetRenderWidth()), height = f32(rl.GetRenderHeight()),
    };
    main_area := subarea_with_aspect_ratio(
        subarea_with_padding(window_area, 20.0),
        16.0 / 9.0,
    );

    draw_text("Options", main_area, 0.2, 0.5, 0.15, rl.RAYWHITE);

    full_screen := fmt.caprintf("Fullscreen: %s", Config.full_screen ? "ON" : "OFF");
    defer delete(full_screen);
    draw_text(full_screen, main_area, selected == 0 ? 0.1 : 0.09,
              0.5, 0.4, selected == 0 ? rl.RAYWHITE : rl.LIGHTGRAY);
    
    das := fmt.caprintf("Delayed Auto Shift: %d ms", int(1000*Config.das + 0.5));
    defer delete(das);
    draw_text(das, main_area, selected == 1 ? 0.1 : 0.09,
              0.5, 0.55, selected == 1 ? rl.RAYWHITE : rl.LIGHTGRAY);

    arr := fmt.caprintf("Auto Repeat Rate: %d ms", int(1000*Config.arr + 0.5));
    defer delete(arr);
    draw_text(arr, main_area, selected == 2 ? 0.1 : 0.09,
              0.5, 0.7, selected == 2 ? rl.RAYWHITE : rl.LIGHTGRAY);

    draw_text("Change controls", main_area, selected == 3 ? 0.1 : 0.09,
              0.5, 0.85, selected == 3 ? rl.RAYWHITE : rl.LIGHTGRAY);
}

destroy_config_screen :: proc(screen: ^Screen) {
    config_screen := cast(^ConfigScreen)(screen);
    if config_screen.parent != nil {
        destroy_screen(config_screen.parent);
    }
    free(config_screen);
}
