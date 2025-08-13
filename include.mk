PREFIX ?= /usr/local
RELDIR := .
pwd != pwd
npm-root != npm root
npm-root-dir != dirname ${npm-root}
prefix := ${pwd} \
	  ${npm-lib:%=${npm-root}/%} \
	  ${npm-lib:%=${npm-root-dir}/../../%} \
	  /usr/local
WARN := -Wall -Wextra -Wpedantic
LDLIBS += -l${LIB}
CFLAGS += ${prefix:%=-I%/include} ${WARN}
LIB-LDFLAGS += ${prefix:%=-L%/lib} ${LIB-LDLIBS}
LDFLAGS	+= ${LIB-LDFLAGS} ${prefix:%=-Wl,-rpath,%/lib} ${LDLIBS}
HEADERS += ${LIB}.h

bintarget := ${BIN:%=bin/%} ${INSTALL-BIN:%=bin/%}
libtarget := ${LIB:%=lib/lib%.so}

.SUFFIXES: .so .c .o

all: ${libtarget} ${bintarget}

${bintarget}: ${libtarget} bin ${bintarget:bin/%=src/%.c}
	@echo CC -o $@ ${@:bin/%=src/%.c} CFLAGS ${libtarget} LDFLAGS
	@${CC} -o $@ ${@:bin/%=src/%.c} ${CFLAGS} ${libtarget} ${LDFLAGS}

${libtarget}: src/lib${LIB}.c include/${LIB}.h ${HEADERS:%=include/%} lib
	@echo CC -o $@ src/lib${LIB}.c CFLAGS -fPIC \
		-shared LIB-LDFLAGS
	@${CC} -o $@ src/lib${LIB}.c ${CFLAGS} -fPIC \
		-shared ${LIB-LDFLAGS}

.c.o:
	echo CC -c -o ${@:%=${RELDIR}/%} CFLAGS ${<:%=${RELDIR}/%}
	@${CC} -c -o ${@:%=${RELDIR}/%} ${CFLAGS} ${<:%=${RELDIR}/%}

lib bin $(dirs):
	@mkdir $@ 2>/dev/null || true

clean:
	@rm lib/*.so bin/* src/*.o 2>/dev/null || true

installed-lib := $(DESTDIR)$(PREFIX)/lib/lib$(LIB).so
installed-pc := $(DESTDIR)$(PREFIX)/lib/pkgconfig/$(LIB).pc

$(installed-lib): ${libtarget}
	install -m 644 ${libtarget} ${DESTDIR}${PREFIX}/lib

$(installed-pc): ${LIB}.pc
	install -m 644 ${LIB}.pc $(DESTDIR)${PREFIX}/lib/pkgconfig

installed-headers := ${HEADERS:%=${DESTDIR}${PREFIX}/include/%}

$(installed-headers): ${HEADERS:%=include/%}
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} \
		$(DESTDIR)${PREFIX}/include

installed-bin := $(INSTALL-BIN:%=$(DESTDIR)$(PREFIX)/bin/%)

$(installed-bin): ${bintarget}
	install -m 755 ${@:$(DESTDIR)$(PREFIX)/%=%} $(DESTDIR)${PREFIX}/bin

install: $(installed-lib) $(installed-pc) $(installed-headers) $(installed-bin)

.PHONY: all clean install
