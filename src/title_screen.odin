package tetrodino

import rl "vendor:raylib"

TitleScreen :: struct {
    base: Screen,

    selected: int,
}

new_title_screen :: proc() -> ^Screen {
    result := new(TitleScreen);
    result.base.update = update_title_screen;
    result.base.draw = draw_title_screen;
    result.base.destroy = destroy_title_screen;
    return cast(^Screen)(result);
}

update_title_screen :: proc(screen: ^Screen) -> ^Screen {
    using title_screen := cast(^TitleScreen)(screen);
    if rl.IsKeyPressed(Config.mappings[.MenuDown]) {
        selected = (selected + 1) % 3;
    }
    if rl.IsKeyPressed(Config.mappings[.MenuUp]) {
        selected = (selected + 2) % 3;
    }
    if rl.IsKeyPressed(Config.mappings[.MenuConfirm]) {
        if selected == 0 {
            destroy_title_screen(screen);
            return new_game_screen();
        } else if selected == 1 {
            return new_config_screen(screen);
        } else if selected == 2 {
            destroy_title_screen(screen);
            return nil;
        }
    }
    return screen;
}

draw_title_screen :: proc(screen: ^Screen) {
    using title_screen := cast(^TitleScreen)(screen);
    rl.ClearBackground(rl.VIOLET);

    window_area := Area{
        left_x = 0.0, top_y = 0.0,
        width = f32(rl.GetRenderWidth()), height = f32(rl.GetRenderHeight()),
    };

    main_area := subarea_with_aspect_ratio(
        subarea_with_padding(window_area, 10.0),
        16.0 / 9.0,
    );

    draw_text("TETRODINO", main_area, 0.2, 0.5, 0.3, rl.RAYWHITE);

    draw_text("Play", main_area, selected == 0 ? 0.1 : 0.09,
              0.5, 0.55, selected == 0 ? rl.RAYWHITE : rl.LIGHTGRAY);

    draw_text("Options", main_area, selected == 1 ? 0.1 : 0.09,
              0.5, 0.7, selected == 1 ? rl.RAYWHITE : rl.LIGHTGRAY);
    
    draw_text("Quit", main_area, selected == 2 ? 0.1 : 0.09,
              0.5, 0.85, selected == 2 ? rl.RAYWHITE : rl.LIGHTGRAY);
}

destroy_title_screen :: proc(screen: ^Screen) {
    free(screen);
}
