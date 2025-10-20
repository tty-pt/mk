LDLIBS-Linux += -lGL -lX11 -lglfw
LDLIBS-OpenBSD += -lGL -lGLU -lX11 -lglfw
LDLIBS-Windows += -lglfw3 -lopengl32 -lgdi32 -luser32 -lkernel32
LDLIBS-Darwin += -lglfw

LDFLAGS-Darwin += -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo

add-prefix-OpenBSD += /usr/X11R6
