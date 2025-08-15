@echo off

rem Copyright (c) 2025 Karl Zylinski
rem 
rem Permission is hereby granted, free of charge, to any person obtaining a copy of
rem this software and associated documentation files (the "Software"), to deal in
rem the Software without restriction, including without limitation the rights to
rem use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
rem of the Software, and to permit persons to whom the Software is furnished to do
rem so, subject to the following conditions:
rem 
rem The above copyright notice and this permission notice shall be included in all
rem copies or substantial portions of the Software.
rem 
rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
rem IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
rem FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
rem AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
rem LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
rem OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
rem SOFTWARE.

:: Point this to where you installed emscripten.
set EMSCRIPTEN_SDK_DIR=c:\SDK\emsdk
set OUT_DIR=build\web

if not exist %OUT_DIR% mkdir %OUT_DIR%

set EMSDK_QUIET=1
call %EMSCRIPTEN_SDK_DIR%\emsdk_env.bat

:: Note RAYLIB_WASM_LIB=env.o -- env.o is an internal WASM object file. You can
:: see how RAYLIB_WASM_LIB is used inside <odin>/vendor/raylib/raylib.odin.
::
:: The emcc call will be fed the actual raylib library file. That stuff will end
:: up in env.o
::
:: Note that there is a rayGUI equivalent: -define:RAYGUI_WASM_LIB=env.o
odin build source\main_web -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o -vet -strict-style -out:%OUT_DIR%\game.wasm.o
IF %ERRORLEVEL% NEQ 0 exit /b 1

for /f %%i in ('odin root') do set "ODIN_PATH=%%i"

copy %ODIN_PATH%\core\sys\wasm\js\odin.js %OUT_DIR%

set files=%OUT_DIR%\game.wasm.o %ODIN_PATH%\vendor\raylib\wasm\libraylib.a %ODIN_PATH%\vendor\raylib\wasm\libraygui.a

:: index_template.html contains the javascript code that calls the procedures in
:: source/main_web/main_web.odin
set flags=-sUSE_GLFW=3 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS --shell-file source\main_web\index_template.html --preload-file assets

:: For debugging: Add `-g` to `emcc` (gives better error callstack in chrome)
::
:: This uses `cmd /c` to avoid emcc stealing the whole command prompt. Otherwise
:: it does not run the lines that follow it.
cmd /c emcc -o %OUT_DIR%\index.html %files% %flags%

del %OUT_DIR%\game.wasm.o 

echo Web build created in %OUT_DIR%
