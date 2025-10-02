PREFIX ?= /usr/local
RELDIR := .
pwd := $(shell pwd)
pwd != pwd
uname := $(shell uname)
uname != uname
arch := $(shell uname -m)
arch != uname -m
prefix-Darwin-arm64  := /opt/homebrew
prefix-Darwin-x86_64 := /usr/local
prefix-Darwin += ${prefix-Darwin-${arch}}
prefix-Linux         := /usr
prefix := ${pwd} ${prefix-${uname}} ${PREFIX}
WARN := -Wall -Wextra -Wpedantic
distro != cat /etc/os-release | grep ID \
	| sed 's/.*=//' || true
LDLIBS-alpine := -lbsd
LIB-LDLIBS += ${LDLIBS-${distro}}
LDLIBS += ${LIB:%=-l%} ${LIB-LDLIBS}
INCFLAGS += ${prefix:%=-I%/include} ${WARN} ${CFLAGS-${uname}} ${CFLAGS}
LIB-LDFLAGS += ${prefix:%=-L%/lib}
LDFLAGS	+= ${LIB-LDFLAGS} ${prefix:%=-Wl,-rpath,%/lib}
ONELIB := $(shell echo ${LIB} | awk '{print $$1}')
ONELIB != echo ${LIB} | awk '{print $$1}'

HEADERS += ${ONELIB:%=%.h}

bintarget := ${BIN:%=bin/%} ${INSTALL-BIN:%=bin/%}
libtarget := ${LIB:%=lib/lib%.so}

.SUFFIXES: .so .c .o

all: info ${libtarget} ${bintarget}
	@echo ${installed-headers}

info:
	@echo ARCH ${arch}

${bintarget}: ${libtarget} bin ${bintarget:bin/%=src/%.c}
	${CC} -o $@ ${@:bin/%=src/%.c} ${INCFLAGS} ${LDFLAGS} ${LDLIBS}

${libtarget}: ${LIB:%=src/lib%.c} ${HEADERS:%=include/%} lib
	${CC} -o $@ ${@:lib/%.so=src/%.c} ${INCFLAGS} -fPIC \
		-shared ${LIB-LDFLAGS} ${LIB-LDLIBS}

.c.o:
	${CC} -c -o ${@:%=${RELDIR}/%} ${INCFLAGS} ${<:%=${RELDIR}/%}

lib bin $(dirs):
	@mkdir $@ 2>/dev/null || true

clean:
	@rm lib/*.so bin/* src/*.o 2>/dev/null || true

installed-lib := $(LIB:%=${DESTDIR}${PREFIX}/lib/lib%.so)
installed-pc := ${ONELIB:%=${DESTDIR}${PREFIX}/lib/pkgconfig/%.pc}

$(installed-lib): ${libtarget} ${DESTDIR}${PREFIX}/lib
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} \
		${DESTDIR}${PREFIX}/lib

install-dirs := ${DESTDIR}${PREFIX}/lib ${DESTDIR}${PREFIX}/bin \
	${DESTDIR}${PREFIX}/include ${DESTDIR}${PREFIX}/lib/pkgconfig

$(install-dirs):
	install -d $@

$(installed-pc): ${ONELIB:%=%.pc} ${DESTDIR}${PREFIX}/lib/pkgconfig
	install -m 644 \
		${@:${DESTDIR}${PREFIX}/lib/pkgconfig/%=%} \
		$(DESTDIR)${PREFIX}/lib/pkgconfig

installed-headers := ${HEADERS:%=${DESTDIR}${PREFIX}/include/%}

$(installed-headers): ${HEADERS:%=include/%} ${DESTDIR}${PREFIX}/include
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} \
		$(DESTDIR)${PREFIX}/include

installed-bin := $(INSTALL-BIN:%=$(DESTDIR)$(PREFIX)/bin/%)

$(installed-bin): ${bintarget} ${DESTDIR}${PREFIX}/bin
	install -m 755 ${@:$(DESTDIR)$(PREFIX)/%=%} \
		$(DESTDIR)${PREFIX}/bin

install: $(installed-lib) $(installed-pc) $(installed-headers) $(installed-bin)

.PHONY: all clean install
