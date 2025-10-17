# PREFIX ?= /usr/local
RELDIR := .
pwd := $(shell pwd)
pwd != pwd
uname := $(shell test "${cross}" = "" && uname || echo ${cross})
uname != test "${cross}" = "" && uname || echo ${cross}
arch := $(shell uname -m)
arch != uname -m
prefix-Darwin-arm64  := /opt/homebrew
prefix-Darwin-x86_64 := /usr/local
prefix-Darwin += ${prefix-Darwin-${arch}}
prefix-Linux := /usr
prefix-OpenBSD := /usr/local
prefix-Msys := /mingw64
prefix-MingW := /ucrt64
PREFIX ?= ${prefix-${uname}}
DESTDIR     ?=
prefix := ${DESTDIR}/${prefix-${uname}}
cc-Linux := ${CC}
cc-Darwin := ${CC}
cc-OpenBSD := ${CC}
cc-Msys := /usr/bin/x86_64-w64-mingw32-gcc
cc-MingW := /ucrt64/bin/gcc
cc := ${cc-${uname}}
prefix := ${pwd} ${prefix-${uname}} ${PREFIX}
WARN := -Wall -Wextra -Wpedantic
distro != cat /etc/os-release | grep ID \
	| sed 's/.*=//' || true
# LDLIBS-Msys := -lbsd
LDLIBS-alpine := -lbsd
LIB-LDLIBS += ${LDLIBS-${uname}} ${LDLIBS-${distro}}
LDLIBS += ${LIB:%=-l%} ${LIB-LDLIBS}
SO-Msys := dll
SO-MingW := dll
SO-Linux := so
SO-OpenBSD := so
SO-Darwin := so
SO := ${SO-${uname}}
# CFLAGS-LIB-Msys += SO=exe
INCFLAGS += ${prefix:%=-I%/include} ${WARN} ${CFLAGS-${uname}} ${CFLAGS}
LIB-LDFLAGS += ${prefix:%=-L%/lib}
LDFLAGS	+= ${LIB-LDFLAGS} ${prefix:%=-Wl,-rpath,%/lib}
ONELIB := $(shell echo ${LIB} | awk '{print $$1}')
ONELIB != echo ${LIB} | awk '{print $$1}'

FOLDER ?= ttypt

HEADERS += ${ONELIB:%=${FOLDER}/%.h}

bintarget := ${BIN:%=bin/%} ${INSTALL-BIN:%=bin/%}
libtarget := ${LIB:%=lib/lib%.${SO}}

.SUFFIXES: .${SO} .c .o

all: info ${libtarget} ${bintarget}
	@echo ${installed-headers}

info:
	@echo ARCH ${arch}

${bintarget}: ${libtarget} bin ${bintarget:bin/%=src/%.c}
	${cc} -o $@ ${@:bin/%=src/%.c} \
		${CFLAGS-BIN-${uname}} \
		${INCFLAGS} ${LDFLAGS} ${LDLIBS}

${libtarget}: ${LIB:%=src/lib%.c} ${HEADERS:%=include/%} lib
	${cc} -o $@ ${@:lib/%.${SO}=src/%.c} ${INCFLAGS} \
		${CFLAGS-LIB-${uname}} -fPIC \
		-shared ${LIB-LDFLAGS} ${LIB-LDLIBS}

.c.o:
	${cc} -c -o ${@:%=${RELDIR}/%} ${INCFLAGS} ${<:%=${RELDIR}/%}

lib bin $(dirs):
	@mkdir $@ 2>/dev/null || true

clean:
	@rm lib/*.${SO} bin/* src/*.o 2>/dev/null || true

installed-lib-Msys := $(LIB:%=${DESTDIR}${PREFIX}/bin/lib%.${SO})
installed-lib := $(LIB:%=${DESTDIR}${PREFIX}/lib/lib%.${SO})

installed-pc := ${ONELIB:%=${DESTDIR}${PREFIX}/lib/pkgconfig/%.pc}

$(installed-lib): ${libtarget} ${DESTDIR}${PREFIX}/lib
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} \
		${DESTDIR}${PREFIX}/lib/

$(installed-lib-Msys): ${libtarget} ${DESTDIR}${PREFIX}/bin
	install -m 644 ${@:${DESTDIR}${PREFIX}/bin/%=lib/%} \
		${DESTDIR}${PREFIX}/bin/

install-dirs := ${DESTDIR}${PREFIX}/lib ${DESTDIR}${PREFIX}/bin \
	${DESTDIR}${PREFIX}/include \
	${DESTDIR}${PREFIX}/include/${FOLDER} \
	${DESTDIR}${PREFIX}/lib/pkgconfig

$(install-dirs):
	install -d $@

$(installed-pc): ${ONELIB:%=%.pc} ${DESTDIR}${PREFIX}/lib/pkgconfig
	install -m 644 \
		${@:${DESTDIR}${PREFIX}/lib/pkgconfig/%=%} \
		$(DESTDIR)${PREFIX}/lib/pkgconfig

installed-headers := ${HEADERS:%=${DESTDIR}${PREFIX}/include/%}

$(installed-headers): ${HEADERS:%=include/%} ${DESTDIR}${PREFIX}/include/${FOLDER}
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} \
		$(DESTDIR)${PREFIX}/include/${FOLDER}

installed-bin := $(INSTALL-BIN:%=$(DESTDIR)$(PREFIX)/bin/%)

$(installed-bin): ${bintarget} ${DESTDIR}${PREFIX}/bin
	install -m 755 ${@:$(DESTDIR)$(PREFIX)/%=%} \
		$(DESTDIR)${PREFIX}/bin

install: ${installed-bin} ${installed-lib-${uname}} $(installed-lib) $(installed-pc) $(installed-headers)

uninstall:
	rm -rf ${installed-lib} ${installed-pc} ${installed-headers} ${installed-bin}

.PHONY: all clean install uninstall
