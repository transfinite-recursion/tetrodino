package tetrodino

import rl "vendor:raylib"

ChangeControlsScreen :: struct {
    base: Screen,
    action_index: int,
    parent: ^Screen,
}

new_change_controls_screen :: proc(parent: ^Screen) -> ^Screen {
    result := new(ChangeControlsScreen);

    result.base.update = update_change_controls_screen;
    result.base.draw = draw_change_controls_screen;
    result.base.draw = draw_change_controls_screen;
    
    result.parent = parent;
    return cast(^Screen)(result);
}

update_change_controls_screen :: proc(screen: ^Screen) -> ^Screen {
    using change_controls_screen := cast(^ChangeControlsScreen)(screen);
    key := rl.GetKeyPressed();
    if key != .KEY_NULL {
        Config.mappings[cast(Action)(action_index)] = key;
        action_index += 1;
        if action_index == len(Config.mappings) {
            p := parent;
            parent = nil;
            destroy_change_controls_screen(change_controls_screen);
            return p;
        }
    }

    return screen;
}

action_name :: proc(index: int) -> cstring {
    switch index {
    case  0: return "Move Left";
    case  1: return "Move Right";
    case  2: return "Soft Drop";
    case  3: return "Hard Drop";
    case  4: return "Rotate Left";
    case  5: return "Rotate Right";
    case  6: return "Pause";
    case  7: return "Menu Left";
    case  8: return "Menu Right";
    case  9: return "Menu Up";
    case 10 : return "Menu Down";
    case 11: return "Menu Confirm";
    case 12: return "Menu Cancel";
    }
    return "unreachable";
}

draw_change_controls_screen :: proc(screen: ^Screen) {
    using change_controls_screen := cast(^ChangeControlsScreen)(screen);
    rl.ClearBackground(rl.VIOLET);

    window_area := Area{
        left_x = 0.0, top_y = 0.0,
        width = f32(rl.GetRenderWidth()), height = f32(rl.GetRenderHeight()),
    };
    main_area := subarea_with_aspect_ratio(
        subarea_with_padding(window_area, 20.0),
        16.0 / 9.0,
    );

    draw_text("Press a key for action:", main_area, 0.1, 0.5, 0.3, rl.RAYWHITE);
    draw_text(action_name(action_index), main_area, 0.2, 0.5, 0.7, rl.RAYWHITE);
}

destroy_change_controls_screen :: proc(
    using change_controls_screen: ^ChangeControlsScreen
) {
    if parent != nil {
        destroy_screen(parent);
    }
    free(change_controls_screen);
}

