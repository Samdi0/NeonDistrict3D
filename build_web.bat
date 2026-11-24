@echo off
set GODOT=godot
if not exist build\web mkdir build\web
%GODOT% --headless --editor --path . --quit
if errorlevel 1 exit /b 1
%GODOT% --headless --path . --export-release Web build\web\index.html
if errorlevel 1 exit /b 1
echo Web build: upload the ENTIRE build\web folder to HTTPS hosting.
