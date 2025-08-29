PREFIX ?= /usr/local
RELDIR := .
pwd != pwd
npm-root != npm root
npm-root-dir != dirname ${npm-root}
prefix := ${pwd} \
	  /usr/local \
	  ${npm-lib:%=${npm-root}/%} \
	  ${npm-lib:%=${npm-root-dir}/../../%}
WARN := -Wall -Wextra -Wpedantic
LDLIBS += ${LIB:%=-l%} ${LIB-LDLIBS}
CFLAGS += ${prefix:%=-I%/include} ${WARN}
LIB-LDFLAGS += ${prefix:%=-L%/lib}
LDFLAGS	+= ${LIB-LDFLAGS} ${prefix:%=-Wl,-rpath,%/lib}
HEADERS += ${ONELIB:%=%.h}

bintarget := ${BIN:%=bin/%} ${INSTALL-BIN:%=bin/%}
libtarget := ${LIB:%=lib/lib%.so}

ONELIB != echo ${LIB} | awk '{print $$1}'

.SUFFIXES: .so .c .o

all: ${libtarget} ${bintarget}

${bintarget}: ${libtarget} bin ${bintarget:bin/%=src/%.c}
	@echo CC -o $@ ${@:bin/%=src/%.c} CFLAGS LDFLAGS ${LDLIBS}
	@${CC} -o $@ ${@:bin/%=src/%.c} ${CFLAGS} ${LDFLAGS} ${LDLIBS}

${libtarget}: ${LIB:%=src/lib%.c} ${HEADERS:%=include/%} lib
	@echo CC -o $@ ${@:lib/%.so=src/%.c} CFLAGS \
		-fPIC -shared LIB-LDFLAGS ${LIB-LDLIBS}
	@${CC} -o $@ ${@:lib/%.so=src/%.c} ${CFLAGS} -fPIC \
		-shared ${LIB-LDFLAGS} ${LIB-LDLIBS}

.c.o:
	echo CC -c -o ${@:%=${RELDIR}/%} CFLAGS ${<:%=${RELDIR}/%}
	@${CC} -c -o ${@:%=${RELDIR}/%} ${CFLAGS} ${<:%=${RELDIR}/%}

lib bin $(dirs):
	@mkdir $@ 2>/dev/null || true

clean:
	@rm lib/*.so bin/* src/*.o 2>/dev/null || true

installed-lib := $(LIB:%=${DESTDIR}${PREFIX}/lib/lib%.so)
installed-pc := ${ONELIB:%=${DESTDIR}${PREFIX}/lib/pkgconfig/%.pc}

$(installed-lib): ${libtarget}
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} \
		${DESTDIR}${PREFIX}/lib

$(installed-pc): ${ONELIB:%=%.pc}
	install -m 644 \
		${@:${DESTDIR}${PREFIX}/lib/pkgconfig/%=%} \
		$(DESTDIR)${PREFIX}/lib/pkgconfig

installed-headers := ${HEADERS:%=${DESTDIR}${PREFIX}/include/%}

$(installed-headers): ${HEADERS:%=include/%}
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} \
		$(DESTDIR)${PREFIX}/include

installed-bin := $(INSTALL-BIN:%=$(DESTDIR)$(PREFIX)/bin/%)

$(installed-bin): ${bintarget}
	install -m 755 ${@:$(DESTDIR)$(PREFIX)/%=%} \
		$(DESTDIR)${PREFIX}/bin

install: $(installed-lib) $(installed-pc) $(installed-headers) $(installed-bin)

.PHONY: all clean install
