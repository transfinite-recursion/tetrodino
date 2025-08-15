package tetrodino

import rl "vendor:raylib"

Action :: enum {
    MoveLeft,
    MoveRight,
    SoftDrop,
    HardDrop,
    RotateLeft,
    RotateRight,
    Pause,
    
    MenuLeft,
    MenuRight,
    MenuUp,
    MenuDown,
    MenuConfirm,
    MenuCancel,
}

Config := struct {
    full_screen: bool,
    
    das: f32,
    arr: f32,
    
    spawn_delay: f32,
    soft_drop_delay: f32,
    line_clear_delay: f32,
    game_over_delay: f32,
    
    shadow_transparency: u8,

    mappings: [Action]rl.KeyboardKey,
} {
    full_screen = false,
    
    das = 0.3,
    arr = 0.05,
    
    spawn_delay = 0.08,
    soft_drop_delay = 0.05,
    line_clear_delay = 0.5,
    game_over_delay = 1.0,
    
    shadow_transparency = 100,

    mappings = {
        .MoveLeft = .LEFT,
        .MoveRight = .RIGHT,
        .SoftDrop = .DOWN,
        .HardDrop = .UP,
        .RotateLeft = .Z,
        .RotateRight = .X,
        .Pause = .ESCAPE,
        
        .MenuLeft = .LEFT,
        .MenuRight = .RIGHT,
        .MenuUp = .UP,
        .MenuDown = .DOWN,
        .MenuConfirm = .Z,
        .MenuCancel = .X,
    },
};
