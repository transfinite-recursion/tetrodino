package tetrodino

Screen :: struct {
    update: proc(^Screen) -> ^Screen,
    draw: proc(^Screen),
    destroy: proc(^Screen),
}

update_screen :: proc(screen: ^Screen) -> ^Screen {
    return screen.update(screen);
}

draw_screen :: proc(screen: ^Screen) {
    screen.draw(screen);
}

destroy_screen :: proc(screen: ^Screen) {
    screen.destroy(screen);
}
