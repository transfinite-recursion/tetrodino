# Tetrodino

A familiar stacking puzzle game written in [Odin](https://odin-lang.org/) using
[raylib](https://www.raylib.com/).

## Running

Simply run `build_desktop.sh` on Linux/macOS or `build_desktop.bat` on Windows.
The resulting executable will be placed in `build/desktop/tetrodino`. The only
dependency is the Odin compiler itself.

A web version is also avaiable via `build_web.sh` and `build_web.bat`,
following [Karl Zylinski's
template](https://github.com/karl-zylinski/odin-raylib-web). This requires
having [Emscripten](https://emscripten.org/) installed. To run simply execute
`python3 -m http.server -d build/web 8080`.
