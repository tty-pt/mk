PREFIX ?= /usr/local
RELDIR := .
pwd != pwd
prefix := ${pwd} ${DESTDIR}${PREFIX}
WARN := -Wall -Wextra -Wpedantic
LDLIBS += ${LIB:%=-l%} ${LIB-LDLIBS}
CFLAGS += ${prefix:%=-I%/include} ${WARN}
LIB-LDFLAGS += ${prefix:%=-L%/lib}
LDFLAGS	+= ${LIB-LDFLAGS} ${prefix:%=-Wl,-rpath,%/lib}
ONELIB != echo ${LIB} | awk '{print $$1}'

HEADERS += ${ONELIB:%=%.h}

bintarget := ${BIN:%=bin/%} ${INSTALL-BIN:%=bin/%}
libtarget := ${LIB:%=lib/lib%.so}

.SUFFIXES: .so .c .o

all: ${libtarget} ${bintarget}
	@echo ${installed-headers}

${bintarget}: ${libtarget} bin ${bintarget:bin/%=src/%.c}
	${CC} -o $@ ${@:bin/%=src/%.c} ${CFLAGS} ${LDFLAGS} ${LDLIBS}

${libtarget}: ${LIB:%=src/lib%.c} ${HEADERS:%=include/%} lib
	${CC} -o $@ ${@:lib/%.so=src/%.c} ${CFLAGS} -fPIC \
		-shared ${LIB-LDFLAGS} ${LIB-LDLIBS}

.c.o:
	${CC} -c -o ${@:%=${RELDIR}/%} ${CFLAGS} ${<:%=${RELDIR}/%}

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
