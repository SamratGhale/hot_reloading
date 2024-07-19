package main

import im "./odin-imgui"
import "./odin-imgui/imgui_impl_glfw"
import "./odin-imgui/imgui_impl_opengl3"

import "vendor:glfw"
import "core:fmt"
import gl "vendor:OpenGL"
import "core:dynlib"
import "core:os"
import win32 "core:sys/windows"

GameApi :: struct{
	//game_ is prefixed, so we look for symbool game_render
	init : proc "c" (),
	render : proc "c" (),
	deinit : proc "c" (),
	_my_lib_handle : dynlib.Library,
	dll_time : os.File_Time,
	game_api_version : int,
}

EngineState :: struct{
	game_loaded : bool
}

game : GameApi
engine_state : EngineState


main :: proc() {
	assert(cast(bool)glfw.Init())
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 2)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, 1) // i32(true)

	window := glfw.CreateWindow(1280, 720, "Atlas", nil, nil)
	assert(window != nil)
	defer glfw.DestroyWindow(window)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1) // vsync

	gl.load_up_to(3, 2, proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = glfw.GetProcAddress(name)
	})

	im.CHECKVERSION()
	im.CreateContext()
	defer im.DestroyContext()
	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}

	im.StyleColorsDark()

	imgui_impl_glfw.InitForOpenGL(window, true)
	defer imgui_impl_glfw.Shutdown()
	imgui_impl_opengl3.Init("#version 150")
	defer imgui_impl_opengl3.Shutdown()

	//lib, lib_ok := dynlib.initialize_symbols(&game, "./game.dll", "game_", "lib")

	engine_state.game_loaded = false


	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		dll_time, dll_time_err := os.last_write_time_by_name("./game.dll")

		reload := dll_time_err == os.ERROR_NONE && game.dll_time != dll_time

		if reload{

			if engine_state.game_loaded{
				dynlib.unload_library(game._my_lib_handle)
				game.init = nil
				game._my_lib_handle = nil
				game.render = nil
			}

			win32.DeleteFileW(win32.L("./new_game.dll"))
			win32.CopyFileW(win32.L("./game.dll"), win32.L("./new_game.dll"), win32.TRUE)
			
			lib, lib_ok := dynlib.initialize_symbols(&game, "./new_game.dll", "game_", "_my_lib_handle")

			if lib_ok {
				game.init()
			}else{
				fmt.println(dynlib.last_error())
			}
			engine_state.game_loaded = lib_ok
			game.dll_time = dll_time
		}

		imgui_impl_opengl3.NewFrame()
		imgui_impl_glfw.NewFrame()
		im.NewFrame()

		im.ShowDemoWindow()

		if im.Begin("Window containing a quit button") {
			if im.Button("The quit button in question") {
				glfw.SetWindowShouldClose(window, true)
			}
		}
		im.End()

		im.Render()
		display_w, display_h := glfw.GetFramebufferSize(window)
		gl.Viewport(0, 0, display_w, display_h)

		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		//update game

		if engine_state.game_loaded{
			game.render()
		}

		imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

		glfw.SwapBuffers(window)
	}
}
