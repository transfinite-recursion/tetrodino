package tetrodino

import rl "vendor:raylib"

import "core:fmt"

draw_board_frame :: proc(area: Area) {
    rl.DrawRectangleLinesEx(rl.Rectangle{
        x = area.left_x - 2.0, y = area.top_y - 2.0,
        width = area.width + 4.0, height = area.height + 4.0,
    }, 2.0, rl.RAYWHITE);
    rl.DrawRectangleRec(area_to_raylib_rectangle(area), rl.BLACK);
}

draw_board_row :: proc(board: Board, j: int, area: Area) {
    w := area.width / BOARD_WIDTH;
    h := area.height / BOARD_HEIGHT;
    for i in 0..<BOARD_WIDTH {
        x := f32(i);
        y := f32(BOARD_HEIGHT - j - 1);
        p := board[i][j];
        if p != .None {
            color := piece_color(p);
            rl.DrawRectangleRec(
                rl.Rectangle{
                    x = area.left_x + x*w, y = area.top_y + y*h,
                    width = w, height = h,
                },
                color,
            );
        }
    }
}

draw_squares :: proc(squares: [4][2]i8, color: rl.Color, area: Area) {
    w := area.width / BOARD_WIDTH;
    h := area.height / BOARD_HEIGHT;
    
    for s in squares {
        x := f32(s.x);
        y := f32(BOARD_HEIGHT - s.y - 1);
        rl.DrawRectangleRec(rl.Rectangle{
            x = area.left_x + x*w, y = area.top_y + y*h,
            width = w, height = h,
        }, color);
    }
}

draw_piece :: proc(piece: Piece, board: Board, area: Area) {
    shadow := drop_piece(piece, board);
    
    color := piece_color(piece.kind);
    
    shadow_color := color;
    shadow_color.a = Config.shadow_transparency;

    draw_squares(shadow.squares, shadow_color, area);
    draw_squares(piece.squares, color, area);
}

draw_next_piece :: proc(piece: Piece, area: Area) {
    piece_area := Area {
        left_x = area.left_x + 0.5 / 6.0 * area.width,
        width = 5.0 / 6.0 * area.width,
        top_y = area.top_y + 2.0 / 5.0 * area.height,
        height = 3.0 / 5.0 * area.height,
    };
    
    w := piece_area.width / 5.0;
    h := piece_area.height / 3.0;
    dx, dy: f32;
    switch piece.kind {
    case .I:
        dx = 0.5; dy = -1.0;
    case .J, .L, .S, .T, .Z:
        dx = 1.0; dy = -0.5;
    case .O:
        dx = 0.5; dy = -0.5;
    case .None:
        panic("unreachable");
    }
    
    rl.DrawRectangleLinesEx(rl.Rectangle{
        x = area.left_x - 2.0, y = area.top_y - 2.0,
        width = area.width + 4.0, height = area.height + 4.0,
    }, 2.0, rl.RAYWHITE);
    rl.DrawRectangleRec(area_to_raylib_rectangle(area), rl.BLACK);

    draw_text("Next", area, 0.3, 0.5, 0.25, rl.RAYWHITE);

    color := piece_color(piece.kind);
    for s in piece.squares {
        x := f32(s.x);
        y := f32(2 - s.y);
        rl.DrawRectangleRec(rl.Rectangle{
            x = piece_area.left_x + (x+dx)*w,
            y = piece_area.top_y + (y+dy)*h,
            width = w,
            height = h,
        }, color);
    }
}

draw_level_text :: proc(level: int, area: Area) {
    rl.DrawRectangleLinesEx(rl.Rectangle{
        x = area.left_x - 2.0, y = area.top_y - 2.0,
        width = area.width + 4.0, height = area.height + 4.0,
    }, 2.0, rl.RAYWHITE);
    rl.DrawRectangleRec(area_to_raylib_rectangle(area), rl.BLACK);

    draw_text("Level", area, 0.4, 0.5, 0.33, rl.RAYWHITE);
    
    level_cstr := fmt.caprintf("%d", level);
    defer delete(level_cstr);
    draw_text(level_cstr, area, 0.4, 0.5, 0.75, rl.RAYWHITE);
}

draw_score :: proc(score: int, area: Area) {
    rl.DrawRectangleLinesEx(rl.Rectangle{
        x = area.left_x - 2.0, y = area.top_y - 2.0,
        width = area.width + 4.0, height = area.height + 4.0,
    }, 2.0, rl.RAYWHITE);
    rl.DrawRectangleRec(area_to_raylib_rectangle(area), rl.BLACK);

    draw_text("Score", area, 0.4, 0.5, 0.33, rl.RAYWHITE);

    score_cstr := fmt.caprintf("%d", score);
    defer delete(score_cstr);
    draw_text(score_cstr, area, 0.3, 0.5, 0.75, rl.RAYWHITE);
}

cleared_line_is_hidden :: proc(y: int, state: GameState) -> bool {
    using clearing_lines: ClearingLines;
    
    switch v in state {
    case ClearingLines:
        clearing_lines = v;
    case Paused:
        c, ok := v.suspended_state.(ClearingLines);
        if ok do clearing_lines = c;
        else do return false;
    case Running, SpawningPiece, GameOver:
        return false;
    }

    if !(y in lines) do return false;
    
    t := timer.elapsed / timer.duration;
    return int(5.00 * t) % 2 == 0;
}

draw_game :: proc(screen: ^Screen) {
    using game := cast(^Game)(screen);
    window_area := Area{
        left_x = 0.0, top_y = 0.0,
        width = f32(rl.GetRenderWidth()), height = f32(rl.GetRenderHeight()),
    };

    main_area := subarea_with_aspect_ratio(
        subarea_with_padding(window_area, 15.0),
        26.0 / 22.0,
    );

    board_area := Area {
        left_x = main_area.left_x + 8.0 / 26.0 * main_area.width,
        width = 10.0 / 26.0 * main_area.width,
        top_y = main_area.top_y + 1.0 / 22.0 * main_area.height,
        height = 20.0 / 22.0 * main_area.height,
    };

    next_area := Area {
        left_x = main_area.left_x + 19.0 / 26.0 * main_area.width,
        width = 6.0 / 26.0 * main_area.width,
        top_y = main_area.top_y + 2.0 / 22.0 * main_area.height,
        height = 5.0 / 22.0 * main_area.height,
    };
    
    level_area := Area {
        left_x = main_area.left_x + 19.0 / 26.0 * main_area.width,
        width = 6.0 / 26.0 * main_area.width,
        top_y = main_area.top_y + 8.0 / 22.0 * main_area.height,
        height = 4.0 / 22.0 * main_area.height,
    };

    score_area := Area {
        left_x = main_area.left_x + 19.0 / 26.0 * main_area.width,
        width = 6.0 / 26.0 * main_area.width,
        top_y = main_area.top_y + 13.0 / 22.0 * main_area.height,
        height = 4.0 / 22.0 * main_area.height,
    };

    rl.DrawRectangleRec(area_to_raylib_rectangle(window_area), rl.PURPLE);
    draw_board_frame(board_area);
    for y in 0..<BOARD_HEIGHT {
        if !cleared_line_is_hidden(y, state) {
            draw_board_row(board, y, board_area);   
        }
    }
    if current_piece.kind != .None {
        draw_piece(current_piece, board, board_area);
    }
    draw_next_piece(next_piece, next_area);
    draw_level_text(level, level_area);
    draw_score(score, score_area);

    #partial switch v in state {
    case Paused:
        color := rl.BLACK;
        color.a = 225;
        rl.DrawRectangleRec(area_to_raylib_rectangle(window_area), color);

        draw_text("PAUSE", board_area, 0.125, 0.5, 0.3, rl.RAYWHITE);

        draw_text("Resume", board_area, v.selected == 0 ? 0.1 : 0.09,
                  0.5, 0.5, v.selected == 0 ? rl.RAYWHITE : rl.LIGHTGRAY);

        draw_text("Options", board_area, v.selected == 1 ? 0.1 : 0.09,
                  0.5, 0.65, v.selected == 1 ? rl.RAYWHITE : rl.LIGHTGRAY);

        draw_text("Quit", board_area, v.selected == 2 ? 0.1 : 0.09,
                  0.5, 0.8, v.selected == 2 ? rl.RAYWHITE : rl.LIGHTGRAY);
        
    case GameOver:
        color := rl.BLACK;
        color.a = 225;
        rl.DrawRectangleRec(area_to_raylib_rectangle(window_area), color);

        b := v.timer.elapsed >= v.timer.duration;
        
        draw_text("GAME OVER", board_area, 0.125, 0.5, 0.3, rl.RAYWHITE);

        draw_text("Play again", board_area, b && v.selected == 0 ? 0.1 : 0.09,
                  0.5, 0.6, b && v.selected == 0 ? rl.RAYWHITE : rl.LIGHTGRAY);

        draw_text("Quit", board_area, b && v.selected == 1 ? 0.1 : 0.09,
                  0.5, 0.8, b && v.selected == 1 ? rl.RAYWHITE : rl.LIGHTGRAY);
    }
}
