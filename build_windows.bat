@echo off
set GODOT=godot
if not exist build mkdir build
%GODOT% --headless --editor --path . --quit
if errorlevel 1 exit /b 1
%GODOT% --headless --path . --export-release "Windows Desktop" build\NeonDistrict3D.exe
if errorlevel 1 exit /b 1
echo Windows build: build\NeonDistrict3D.exe
