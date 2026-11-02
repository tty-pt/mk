LDLIBS-Linux += -lGL -lX11 -lGLEW -lglfw
LDLIBS-OpenBSD += -lGL -lGLU -lX11 -lGLEW -lglfw
LDLIBS-FreeBSD += -lGL -lGLU -lX11 -lGLEW -lglfw
LDLIBS-NetBSD += -lGL -lGLU -lX11 -lGLEW -lglfw
LDLIBS-DragonFly += -lGL -lGLU -lX11 -lGLEW -lglfw
LDLIBS-Windows += -lglew32 -lglfw3 -lopengl32 -lgdi32 -luser32 -lkernel32
LDLIBS-Darwin += -lglfw

LDFLAGS-Darwin += -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo

add-prefix-OpenBSD += /usr/X11R6
add-prefix-NetBSD += /usr/X11R7
