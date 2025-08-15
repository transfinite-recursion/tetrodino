/*
Copyright (c) 2025 Karl Zylinski

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// These procs are the ones that will be called from `index.html`, which is
// generated from `index_template.html`.

package main_web

import "base:runtime"
import "core:c"
import "core:mem"
import game ".."

@(private="file")
web_context: runtime.Context

@export
main_start :: proc "c" () -> ^game.Screen {
	context = runtime.default_context()

	// The WASM allocator doesn't seem to work properly in combination with
	// emscripten. There is some kind of conflict with how the manage memory.
	// So this sets up an allocator that uses emscripten's malloc.
	context.allocator = emscripten_allocator()
	runtime.init_global_temporary_allocator(1*mem.Megabyte)

	// Since we now use js_wasm32 we should be able to remove this and use
	// context.logger = log.create_console_logger(). However, that one produces
	// extra newlines on web. So it's a bug in that core lib.
	context.logger = create_emscripten_logger()

	web_context = context

	return game.init()
}

@export
main_update :: proc "c" (screen: ^game.Screen) -> ^game.Screen {
	context = web_context
	return game.update(screen)
}

@export
main_end :: proc "c" (screen: ^game.Screen) {
	context = web_context
	game.shutdown(screen)
}

@export
web_window_size_changed :: proc "c" (w: c.int, h: c.int) {
	context = web_context
	game.parent_window_size_changed(int(w), int(h))
}
