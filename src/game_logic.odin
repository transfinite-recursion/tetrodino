package tetrodino

import rl "vendor:raylib"

import "core:math"
import "core:math/rand"

BOARD_WIDTH :: 10;
BOARD_HEIGHT :: 20;

PieceKind :: enum { None = 0, I, J, L, O, S, T, Z }

Board :: [BOARD_WIDTH][BOARD_HEIGHT]PieceKind;

Piece :: struct {
    squares: [4][2]i8,
    center: [2]i8,
    kind: PieceKind,
}

Timer :: struct {
    elapsed: f32,
    duration: f32,
}

Running :: struct {}
SpawningPiece :: struct { timer: Timer }
Paused :: struct {
    suspended_state: ^GameState,
    selected: int,
}
ClearingLines :: struct {
    timer: Timer,
    lines: bit_set[0..<BOARD_HEIGHT],
}
GameOver :: struct {
    timer: Timer,
    selected: int,
}

GameState :: union #no_nil {
    Running,
    SpawningPiece,
    Paused,
    ClearingLines,
    GameOver,
}

Game :: struct {
    base: Screen,

    state: GameState,
    
    board: Board,
    
    level: int,
    score: int,
    lines_cleared: int,
    
    current_piece: Piece,
    next_piece: Piece,
    
    movement_timer: Timer,
    gravity_timer: Timer,
    soft_drop_timer: Timer,
}

/*
 * ........  []......  ....[]..  ..[][]..
 * [][][][]  [][][]..  [][][]..  ..[][]..
 * 
 * ..[][]..  ..[]....  [][]....
 * [][]....  [][][]..  ..[][]..
*/
make_piece :: proc(kind: PieceKind) -> Piece {
    squares: [4][2]i8;
    center: [2]i8;
    switch kind {
    case .I:
        squares = {{0, 0}, {1, 0}, {2, 0}, {3, 0}};
        center = {3, -1};
    case .J:
        squares = {{0, 0}, {1, 0}, {2, 0}, {0, 1}};
        center = {2, 0};
    case .L:
        squares = {{0, 0}, {1, 0}, {2, 0}, {2, 1}};
        center = {2, 0};
    case .O:
        squares = {{1, 0}, {2, 0}, {1, 1}, {2, 1}};
        center = {3, 1};
    case .S:
        squares = {{0, 0}, {1, 0}, {1, 1}, {2, 1}};
        center = {2, 0};
    case .T:
        squares = {{0, 0}, {1, 0}, {2, 0}, {1, 1}};
        center = {2, 0};
    case .Z:
        squares = {{1, 0}, {2, 0}, {0, 1}, {1, 1}};
        center = {2, 0};
    case .None:
        panic("unreachable");
    }
    return Piece{squares = squares, center = center, kind = kind};
}

piece_color :: proc(kind: PieceKind) -> (result: rl.Color) {
    switch kind {
    case .None: result = rl.BLACK;
    case .I: result = rl.SKYBLUE;
    case .J: result = rl.ORANGE;
    case .L: result = rl.DARKBLUE;
    case .O: result = rl.YELLOW;
    case .S: result = rl.GREEN;
    case .T: result = rl.VIOLET;
    case .Z: result = rl.RED;
    }
    return;
}

move_piece :: proc(piece: Piece, offset: [2]i8) -> Piece {
    result := piece;
    for &s in result.squares {
        s += offset;
    }
    result.center += 2*offset;
    return result;
}

rotate_piece_left :: proc(piece: Piece) -> Piece {
    result := piece;
    mat := matrix[2, 2]i8{0, -1, 1, 0};
    for &s in result.squares {
        s = (mat * (2*s - piece.center) + piece.center) / 2;
    }
    return result;
}

rotate_piece_right :: proc(piece: Piece) -> Piece {
    result := piece;
    mat := matrix[2, 2]i8{0, 1, -1, 0};
    for &s in result.squares {
        s = (mat * (2*s - piece.center) + piece.center) / 2;
    }
    return result;
}

piece_in_bounds :: proc(piece: Piece, board: Board) -> bool {
    for s in piece.squares {
        in_width := 0 <= s.x && s.x < BOARD_WIDTH;
        in_height := 0 <= s.y && s.y < BOARD_HEIGHT;
        in_board := in_width && in_height;
        if !in_board || board[s.x][s.y] != .None {
            return false;
        }
    }
    return true;
}

drop_piece :: proc(piece: Piece, board: Board) -> Piece {
    prev := piece;
    curr := piece;
    for piece_in_bounds(curr, board) {
        prev = curr;
        curr = move_piece(curr, {0, -1});
    }
    return prev;
}

gravity_for_level :: proc(level: int) -> f32 {
    return math.pow(0.9, f32(level));
}

full_row :: proc(board: Board, y: int) -> bool {
    for x in 0..<BOARD_WIDTH {
        if board[x][y] == .None {
            return false;
        }
    }
    return true;
}

copy_row :: proc(board: ^Board, tgt, src: int) {
    for x in 0..<BOARD_WIDTH {
        board[x][tgt] = board[x][src];
    }
}

clear_row :: proc(board: ^Board, y: int) {
    for x in 0..<BOARD_WIDTH {
        board[x][y] = .None;
    }
}

clear_full_lines :: proc(board: ^Board) {
    y1 := 0;
    for y2 in 0..<BOARD_HEIGHT {
        if !full_row(board^, y2) {
            if y1 != y2 {
                copy_row(board, y1, y2);
            }
            y1 += 1;
        }
    }
    for y2 in y1..<BOARD_HEIGHT {
        clear_row(board, y2);
    }
}

lock_piece :: proc(piece: Piece, board: ^Board) {
    for s in piece.squares {
        board[s.x][s.y] = piece.kind;
    }
}

make_random_piece :: proc() -> Piece {
    kind := cast(PieceKind)(1 + rand.int_max(7));
    return make_piece(kind);
}

update_clear_lines_animation :: proc(using animation: ^ClearingLines) -> bool {
    timer.elapsed += rl.GetFrameTime();
    return timer.elapsed < timer.duration;
}

new_game_screen :: proc() -> ^Screen {
    result := new(Game);
    
    result.base.update = update_game;
    result.base.draw = draw_game;
    result.base.destroy = destroy_game;
    
    result.current_piece = move_piece(make_random_piece(), {3, BOARD_HEIGHT - 3});
    result.next_piece = make_random_piece();
    result.movement_timer.duration = Config.das;
    result.gravity_timer.duration = gravity_for_level(0);
    result.soft_drop_timer.duration = Config.soft_drop_delay;

    return cast(^Screen)(result);
}

reset_game :: proc(using game: ^Game) {
    board = {};
    
    level = 0;
    score = 0;
    lines_cleared = 0;
    
    current_piece = move_piece(make_random_piece(), {3, BOARD_HEIGHT - 3});
    next_piece = make_random_piece();

    state = Running{};
    
    movement_timer.elapsed = 0.0;
    movement_timer.duration = Config.das;
    gravity_timer.elapsed = 0.0;
    gravity_timer.duration = gravity_for_level(0);
    soft_drop_timer.elapsed = 0.0;
    soft_drop_timer.duration = Config.soft_drop_delay;
}

destroy_game :: proc(screen: ^Screen) {
    game := cast(^Game)(screen);
    paused, ok := game.state.(Paused);
    if ok {
        free(paused.suspended_state);
    }
    free(game);
}

update_running_game :: proc(using game: ^Game) {
    if rl.IsKeyPressed(Config.mappings[.RotateLeft]) {
        new_piece := rotate_piece_left(current_piece);
        if piece_in_bounds(new_piece, board) do current_piece = new_piece;
    }
    if rl.IsKeyPressed(Config.mappings[.RotateRight]) {
        new_piece := rotate_piece_right(current_piece);
        if piece_in_bounds(new_piece, board) do current_piece = new_piece;
    }

    left_key_pressed := rl.IsKeyPressed(Config.mappings[.MoveLeft]);
    right_key_pressed := rl.IsKeyPressed(Config.mappings[.MoveRight]);
    left_key_down := rl.IsKeyDown(Config.mappings[.MoveLeft]);
    right_key_down := rl.IsKeyDown(Config.mappings[.MoveRight]);
    if left_key_pressed || right_key_pressed {
        movement_timer.elapsed = 0.0;
        offset: i8 = left_key_pressed ? -1 : 1;
        new_piece := move_piece(current_piece, {offset, 0});
        if piece_in_bounds(new_piece, board) do current_piece = new_piece;
    } else if left_key_down || right_key_down {
        offset: i8 = left_key_down ? -1 : 1;
        movement_timer.elapsed += rl.GetFrameTime();
        for movement_timer.elapsed >= movement_timer.duration {
            movement_timer.elapsed -= Config.arr; // 0.001;
            new_piece := move_piece(current_piece, {offset, 0});
            if piece_in_bounds(new_piece, board) do current_piece = new_piece;
        }
    }

    if rl.IsKeyPressed(Config.mappings[.SoftDrop]) {
        soft_drop_timer.elapsed = 0.0;
        new_piece := move_piece(current_piece, {0, -1});
        if piece_in_bounds(new_piece, board) {
            current_piece = new_piece;
        } else {
            lock_piece(current_piece, &board);
            current_piece.kind = .None;
        }
    } else if rl.IsKeyDown(Config.mappings[.SoftDrop]) {
        soft_drop_timer.elapsed += rl.GetFrameTime();
        for soft_drop_timer.elapsed >= soft_drop_timer.duration {
            soft_drop_timer.elapsed -= soft_drop_timer.duration;
            new_piece := move_piece(current_piece, {0, -1});
            if piece_in_bounds(new_piece, board) {
                current_piece = new_piece;
            } else {
                lock_piece(current_piece, &board);
                current_piece.kind = .None;
            }
        }
    }
    
    if rl.IsKeyPressed(Config.mappings[.HardDrop]) {
        dropped := drop_piece(current_piece, board);
        dy := int(current_piece.center.y) - int(dropped.center.y);
        score += dy;
        lock_piece(dropped, &board);
        current_piece.kind = .None;
    }

    gravity_timer.elapsed += rl.GetFrameTime();
    for gravity_timer.elapsed >= gravity_timer.duration {
        gravity_timer.elapsed -= gravity_timer.duration;
        if current_piece.kind != .None {
            new_piece := move_piece(current_piece, {0, -1});
            if piece_in_bounds(new_piece, board) {
                current_piece = new_piece;
            } else {
                lock_piece(current_piece, &board);
                current_piece.kind = .None;
            }
        }
    }

    cleared_lines: bit_set[0..<BOARD_HEIGHT] = {};
    for y in 0..<BOARD_HEIGHT {
        if full_row(board, y) {
            cleared_lines |= {y};
            lines_cleared += 1;
            new_level := lines_cleared / 10;
            if new_level > level {
                level = new_level;
                gravity_timer.duration = gravity_for_level(level);
            }
        }
    }
    
    switch card(cleared_lines) {
    case 1: score += 40 * (level + 1);
    case 2: score += 100 * (level + 1);
    case 3: score += 300 * (level + 1);
    case 4: score += 1200 * (level + 1);
    }
    
    if cleared_lines != {} {
        state = ClearingLines{
            timer = {elapsed = 0.0, duration = Config.line_clear_delay},
            lines = cleared_lines,
        };
    } else if current_piece.kind == .None {
        state = SpawningPiece{
            timer = {elapsed = 0.0, duration = Config.spawn_delay}
        };
    }
}

update_game :: proc(screen: ^Screen) -> ^Screen {
    using game := cast(^Game)(screen);
    if rl.IsKeyPressed(Config.mappings[.Pause]) {
        _, paused := state.(Paused);
        if !paused {
            state = Paused{
                suspended_state = new_clone(state),
                selected = 0,
            };
            return screen;
        }
    }

    switch &v in state {
    case Paused:
        if (rl.IsKeyPressed(Config.mappings[.Pause]) ||
            rl.IsKeyPressed(Config.mappings[.MenuCancel]) ||
            (rl.IsKeyPressed(Config.mappings[.MenuConfirm]) && v.selected == 0))
        {
            suspended_state := v.suspended_state;
            state = suspended_state^;
            free(suspended_state);
        }
        if rl.IsKeyPressed(Config.mappings[.MenuConfirm]) {
            if v.selected == 1 {
                return new_config_screen(cast(^Screen)(game));
            } else if v.selected == 2 {
                destroy_game(screen);
                return new_title_screen();
            }
        }
        if rl.IsKeyPressed(Config.mappings[.MenuDown]) {
            v.selected = (v.selected + 1) % 3;
        }
        if rl.IsKeyPressed(Config.mappings[.MenuUp]) {
            v.selected = (v.selected + 2) % 3;
        }
    case ClearingLines:
        if !update_clear_lines_animation(&v) {
            state = SpawningPiece{
                timer = {elapsed = 0.0, duration = Config.spawn_delay}
            };
            clear_full_lines(&board);
        }
    case SpawningPiece:
        v.timer.elapsed += rl.GetFrameTime();
        if v.timer.elapsed >= v.timer.duration {
            current_piece = move_piece(next_piece, {3, BOARD_HEIGHT - 2});
            next_piece = make_random_piece();
            if !piece_in_bounds(current_piece, board) {
                state = GameOver{
                    timer = {elapsed = 0.0, duration = Config.game_over_delay}
                };
            } else {
                state = Running{};
            }
        }
    case Running:
        update_running_game(game);
    case GameOver:
        v.timer.elapsed += rl.GetFrameTime();
        if v.timer.elapsed >= v.timer.duration {
            if rl.IsKeyPressed(Config.mappings[.MenuDown]) {
                v.selected = (v.selected + 1) % 2;
            }
            if rl.IsKeyPressed(Config.mappings[.MenuUp]) {
                v.selected = (v.selected + 1) % 2;
            }
            if rl.IsKeyPressed(Config.mappings[.MenuConfirm]) {
                if v.selected == 0 {
                    reset_game(game);
                } else if v.selected == 1 {
                    destroy_game(screen);
                    return new_title_screen();
                }
            }
        }
    }

    return screen;
}
