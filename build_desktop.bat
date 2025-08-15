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

set OUT_DIR=build\desktop
if not exist %OUT_DIR% mkdir %OUT_DIR%

odin build source\main_desktop -vet -strict-style -out:%OUT_DIR%\game_desktop.exe
IF %ERRORLEVEL% NEQ 0 exit /b 1

xcopy /y /e /i assets %OUT_DIR%\assets >nul
IF %ERRORLEVEL% NEQ 0 exit /b 1

echo Desktop build created in %OUT_DIR%
