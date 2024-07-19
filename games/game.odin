package games

import gl "vendor:OpenGL"
import "vendor:glfw"

@(export)
game_init :: proc(){
    assert(cast(bool)glfw.Init())

 /*
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 2)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, 1) // i32(true)
    */
	gl.load_up_to(3, 2, proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = glfw.GetProcAddress(name)
	})
}

@(export)
game_render :: proc(){
    gl.ClearColor(1.0, 0.3, 0, 1)
    gl.Clear(gl.COLOR_BUFFER_BIT)
}
@(export)
game_deinit :: proc(){
    //glfw.Terminate()
}