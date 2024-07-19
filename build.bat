@echo off
odin build games/game.odin -file -build-mode:dll -out:game.dll -debug -define:GLFW_SHARED=true