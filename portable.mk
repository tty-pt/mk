pwd := $(shell pwd)
pwd != pwd

bname := $(shell basename ${pwd})
bname != basename ${pwd}

uname := $(shell test "${cross}" = "" && uname || echo ${cross})
uname != test "${cross}" = "" && uname || echo ${cross}

arch := $(shell uname -m)
arch != uname -m

distro != cat /etc/os-release 2>/dev/null | grep ID \
	| sed 's/.*=//' || true

prefix-Darwin-arm64  := /opt/homebrew
prefix-Darwin-x86_64 := /usr/local
prefix-Darwin := ${prefix-Darwin-${arch}}
prefix-Linux := /usr
prefix-OpenBSD := /usr/local
prefix-Msys := /mingw64
prefix-MingW := /ucrt64

PREFIX ?= ${prefix-${uname}}
prefix := ${pwd} ${prefix-${uname}} ${add-prefix-${uname}}

SYS-Msys := Windows
SYS-MingW := Windows
SYS-Linux := Unix
SYS-OpenBSD := Unix
SYS-Darwin := Unix
SYS := ${SYS-${uname}}

cc-Linux := ${CC}
cc-Darwin := ${CC}
cc-OpenBSD := ${CC}
cc-Msys := /usr/bin/x86_64-w64-mingw32-gcc
cc-MingW := /ucrt64/bin/gcc
cc := ${cc-${uname}}

cxx-Linux := ${CXX}
cxx-Darwin := ${CXX}
cxx-OpenBSD := ${CXX}
cxx-Msys := /usr/bin/x86_64-w64-mingw32-g++
cxx-MingW := /ucrt64/bin/g++
cxx := ${cxx-${uname}}

SO-Windows := dll
SO-Unix := so
SO := ${SO-${SYS}}

EXE-Windows := .exe
EXE := ${EXE-${SYS}}

CFLAGS += ${prefix:%=-I%/include} ${CFLAGS-${SYS}} \
	${CFLAGS-${uname}} ${CFLAGS-${distro}}
CFLAGS-BIN-Windows += -static
CFLAGS-m-Darwin += -ObjC

LDFLAGS += ${prefix:%=-L%/lib} ${LDFLAGS-${SYS}} \
	${LDFLAGS-${uname}} ${LDFLAGS-${distro}}

LDLIBS-Darwin += -lobjc
LDLIBS += ${LDLIBS-${SYS}} \
	  ${LDLIBS-${uname}} ${LDLIBS-${distro}}
LDLIBS-alpine := -lbsd
