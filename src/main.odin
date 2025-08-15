package tetrodino

import rl "vendor:raylib"

import "core:c"

init :: proc() -> ^Screen {
    rl.SetTargetFPS(60);
    rl.SetConfigFlags({.WINDOW_RESIZABLE});
    
    rl.InitWindow(800, 600, "Tetrodino");
    
    rl.SetExitKey(.KEY_NULL);

    return new_title_screen();
}

update :: proc(screen: ^Screen) -> ^Screen {
    new_screen := update_screen(screen);
    if new_screen == nil do return nil;
    
    rl.BeginDrawing(); {
        draw_screen(new_screen);
    } rl.EndDrawing();

    return new_screen;
}

parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(c.int(w), c.int(h));
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		if rl.WindowShouldClose() {
            return false;
		}
	}

	return true;
}

shutdown :: proc(screen: ^Screen) {
    if screen != nil do destroy_screen(screen);

    rl.CloseWindow();
}
