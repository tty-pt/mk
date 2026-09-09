pwd := $(shell pwd)
pwd != pwd

bname := $(shell basename ${pwd})
bname != basename ${pwd}

uname := $(shell test "${cross}" = "" && uname || echo ${cross})
uname != test "${cross}" = "" && uname || echo ${cross}

arch := $(shell uname -m)
arch != uname -m

distro := $(shell sed -n 's/^ID=//p' /etc/os-release 2>/dev/null | tr -d '"')
distro != sed -n 's/^ID=//p' /etc/os-release 2>/dev/null | tr -d '"' || true

prefix-Darwin-arm64  := /opt/homebrew
prefix-Darwin-x86_64 := /usr/local
prefix-Darwin := ${prefix-Darwin-${arch}}
prefix-Linux := /usr
prefix-OpenBSD := /usr/local
prefix-FreeBSD := /usr/local
prefix-NetBSD := /usr/pkg
prefix-DragonFly := /usr/local
prefix-Msys := /mingw64
prefix-MingW := /ucrt64
prefix-MinGW64 := /mingw64
prefix-${uname} ?= /usr/local

PREFIX ?= ${prefix-${uname}}
prefix := ${pwd} ${prefix-${uname}} ${add-prefix} ${add-prefix-${uname}} ${mod-prefix-${uname}:%=${prefix-${uname}}/%}

SYS-Msys := Windows
SYS-MingW := Windows
SYS-MinGW64 := Windows
SYS-Linux := Unix
SYS-OpenBSD := Unix
SYS-FreeBSD := Unix
SYS-NetBSD := Unix
SYS-DragonFly := Unix
SYS-Darwin := Unix
SYS-${uname} ?= Unix
SYS := ${SYS-${uname}}

cc-Linux := ${CC}
cc-Darwin := ${CC}
cc-OpenBSD := ${CC}
cc-FreeBSD := ${CC}
cc-NetBSD := ${CC}
cc-DragonFly := ${CC}
cc-Msys := /usr/bin/x86_64-w64-mingw32-gcc
cc-MingW := /ucrt64/bin/gcc
cc-MinGW64 := /mingw64/bin/gcc
cc-${uname} ?= ${CC}
cc := ${cc-${uname}}

cxx-Linux := ${CXX}
cxx-Darwin := ${CXX}
cxx-OpenBSD := ${CXX}
cxx-FreeBSD := ${CXX}
cxx-NetBSD := ${CXX}
cxx-DragonFly := ${CXX}
cxx-Msys := /usr/bin/x86_64-w64-mingw32-g++
cxx-MingW := /ucrt64/bin/g++
cxx-MinGW64 := /mingw64/bin/g++
cxx-${uname} ?= ${CXX}
cxx := ${cxx-${uname}}

SO-Windows := dll
SO-Unix := so
SO := ${SO-${SYS}}

EXE-Windows := .exe
EXE := ${EXE-${SYS}}

CFLAGS += ${prefix:%=-I%/include} ${CFLAGS-${SYS}} \
	${CFLAGS-${uname}} ${CFLAGS-${distro}} ${CFLAGS-${arch}}
CFLAGS-BIN-Windows += -static
CFLAGS-m-Darwin += -ObjC

LDFLAGS += ${prefix:%=-L%/lib} ${LDFLAGS-${SYS}} \
	${LDFLAGS-${uname}} ${LDFLAGS-${distro}}

LDLIBS-Darwin += -lobjc
LDLIBS += ${LDLIBS-${SYS}} \
	  ${LDLIBS-${uname}} ${LDLIBS-${distro}}
LDLIBS-alpine := -lbsd

WASI_CC    ?= clang
WASI_SYSROOT ?=
WASM_CFLAGS   ?= -O2 -D__wasm__ --target=wasm32-wasi
WASM_LDFLAGS  ?= -mexec-model=reactor -Wl,--export-all -Wl,--allow-undefined
