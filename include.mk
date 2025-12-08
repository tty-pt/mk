MPATH := $(dir $(lastword $(MAKEFILE_LIST)))
MPATH != echo ${MAKEFILE_LIST} | tr ' ' '\n' | tail -n 1
MPATH != dirname ${MPATH}
include ${MPATH}/portable.mk

WARN := -Wall -Wextra -Wpedantic
CFLAGS += ${WARN}

share-dir ?= ${bname}
all ?= ${bname}

LIB := $(shell echo ${all} | tr ' ' '\n' | sed -n '/^lib/p')
LIB != echo ${all} | tr ' ' '\n' | sed -n '/^lib/p'
BIN := $(shell echo ${all} | tr ' ' '\n' | sed '/^lib/d')
BIN != echo ${all} | tr ' ' '\n' | sed '/^lib/d'

INSTALL_BIN ?= ${BIN}

ONELIB := $(shell echo ${LIB} | awk '{print $$1}')
ONELIB != echo ${LIB} | awk '{print $$1}'
ONELIB := ${ONELIB:lib%=%}

FOLDER ?= ttypt
HEADERS := $(shell ls include/${FOLDER} 2>/dev/null || true)
HEADERS != ls include/${FOLDER} 2>/dev/null || true
HEADERS := ${HEADERS:%=${FOLDER}/%}

.SUFFIXES: .${SO} .m .c .o .cpp

all := objects-set.mk ${LIB:%=lib/%.${SO}} ${BIN:%=bin/%${EXE}}

all: ${all}

LIB-obj-y ?= ${LIB:%=src/%.o} ${${LIB:%=%-obj-y}} ${${LIB:%=%-obj-y-${uname}}}
BIN-obj-y ?= ${BIN:%=src/%.o} ${${BIN:%=%-obj-y}} ${${BIN:%=lib%-obj-y-${uname}}}

CFLAGS-LIB := -fPIC

objects-set.mk:
	@for obj in ${LIB-obj-y}; do \
		robj=`echo $$obj | sed 's|.*/||' \
			| tr '.' '-'` ; \
		echo CFLAGS-$$robj := ${CFLAGS-LIB} ; \
	done > $@
	@for obj in ${BIN-obj-y}; do \
		robj=`echo $$obj | sed 's|.*/||' \
			| tr '.' '-'` ; \
		echo CFLAGS-$$robj := ${CFLAGS-BIN} ; \
	done >> $@

-include objects-set.mk

info:
	@echo MPATH ${MPATH}
	@echo BIN ${BIN}
	@echo LIB ${LIB}
	@echo LIB-obj-y ${LIB-obj-y}
	@echo BIN-obj-y ${BIN-obj-y}
	@echo HEADERS ${HEADERS}

bintarget := ${BIN:%=bin/%${EXE}}
$(bintarget): ${LIB:%=lib/%.${SO}} bin ${BIN-obj-y}
	${cc} -o $@ ${@:bin/%${EXE}=src/%.o} ${${@:bin/%${EXE}=%}-obj-y} ${LDFLAGS} ${LDFLAGS-${@:bin/%${EXE}=%}} ${LDFLAGS-${@:bin/%${EXE}=%}-${SYS}} ${LDFLAGS-${@:bin/%${EXE}=%}-${uname}} ${LDLIBS-${@:bin/%${EXE}=%}-${SYS}} ${LDLIBS-${@:bin/%${EXE}=%}} ${LDLIBS-${@:bin/%${EXE}=%}-${uname}} ${LDLIBS}

libtarget := ${LIB:%=lib/%.${SO}}
$(libtarget): lib ${LIB:%=src/%.o} ${LIB-obj-y}
	${cc} -o $@ ${@:lib/%.${SO}=src/%.o} ${${@:lib/%.${SO}=%}-obj-y} ${${@:lib/%.${SO}=%}-obj-y-${uname}} -shared ${LDFLAGS} ${LDFLAGS-${@:lib/%.${SO}=%}-${SYS}} ${LDFLAGS-${@:lib/%.${SO}=%}-${uname}} ${LDFLAGS-${@:lib/%.${SO}=%}} ${LDLIBS-${@:lib/%.${SO}=%}} ${LDLIBS-${@:lib/%.${SO}=%}-${SYS}} ${LDLIBS-${@:lib/%.${SO}=%}-${uname}} ${LDLIBS}

.c.o:
	${cc} -c -o $@ ${CFLAGS} ${CFLAGS-${@:src/%.o=%-o}} ${@:src/%.o=src/%.c}

.m.o:
	${cc} -c -o $@ ${CFLAGS} ${CFLAGS-m-${uname}} ${CFLAGS-${@:src/%.o=%-o}} ${@:src/%.o=src/%.m}

.cpp.o:
	${cxx} -c -o $@ ${CFLAGS} ${CFLAGS-${@:src/%.o=%-o}} ${@:src/%.o=src/%.cpp}

dirs += bin lib
$(dirs):
	@mkdir $@ 2>/dev/null || true

clean:
	@rm -rf src/*.o ${LIB:%=lib/%.${SO}} \
		${BIN:%=bin/%${EXE}} man 2>/dev/null || true

install-share-dirs := ${share-dirs:%=share/${share-dir}/%}
install-share-dirs := ${install-share-dirs:%=${DESTDIR}${PREFIX}/%} ${DESTDIR}${PREFIX}/share/${share-dir}

install-dirs += lib bin include include/${FOLDER} lib/pkgconfig
install-dirs += share/man/man1 share/man/man3
install-dirs := ${install-dirs:%=${DESTDIR}${PREFIX}/%}
$(install-dirs) $(install-share-dirs):
	install -d $@

$(installed-pc): ${ONELIB:%=%.pc} ${DESTDIR}${PREFIX}/lib/pkgconfig
	install -m 644 ${@:${DESTDIR}${PREFIX}/lib/pkgconfig/%=%} $@

installed-headers := ${HEADERS:%=include/%}
installed-headers := ${installed-headers:%=${DESTDIR}${PREFIX}/%}
$(installed-headers): ${DESTDIR}${PREFIX}/include ${HEADERS:%=include/%}
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} $@

installed-libs := ${LIB:%=lib/%.${SO}}
installed-libs := ${installed-libs:%=${DESTDIR}${PREFIX}/%}
$(installed-libs): ${DESTDIR}${PREFIX}/lib ${LIB:%=lib/%.${SO}}
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} $@

installed-share := ${share:%=${DESTDIR}${PREFIX}/share/${share-dir}/%}
$(installed-share): ${install-share-dirs} ${share}
	install -m 644 ${@:${DESTDIR}${PREFIX}/share/${share-dir}/%=%} $@

installed-lib-Windows := $(LIB:%=${DESTDIR}${PREFIX}/bin/%.${SO})
$(installed-lib-Windows): ${LIB:%=lib/%.${SO}} ${DESTDIR}${PREFIX}/bin
	install -m 644 ${@:${DESTDIR}${PREFIX}/bin/%=lib/%} $@

installed-bin := $(INSTALL_BIN:%=$(DESTDIR)$(PREFIX)/bin/%${EXE})
$(installed-bin): ${INSTALL_BIN:%=bin/%${EXE}} ${DESTDIR}${PREFIX}/bin
	install -m 755 ${@:$(DESTDIR)$(PREFIX)/%=%} $@

install-info:
	@echo ${installed-bin}


MAN3 := $(shell test -f Doxyfile && ls man/*.3 2>/dev/null || true)
MAN3 != test -f Doxyfile && ls man/*.3 2>/dev/null || true
MAN1 := $(shell test -f Doxyfile && ls man/*.1 2>/dev/null || true)
MAN1 != test -f Doxyfile && ls man/*.1 2>/dev/null || true

docs: docs-bin
	@test -f Doxyfile && doxygen Doxyfile || true

docs-bin:
	@test -f Doxyfile && doxygen ../mk/Doxyfile-bin || true

installed-man3 := ${MAN3:man/%=${DESTDIR}${PREFIX}/share/man/man3/%}
$(installed-man3): ${MAN3} ${DESTDIR}${PREFIX}/share/man/man3
	install -m 644 ${@:${DESTDIR}${PREFIX}/share/man/man3/%=man/%} $@

installed-man1 := ${MAN1:man/%=${DESTDIR}${PREFIX}/share/man/man1/%}
$(installed-man1): ${MAN1} ${DESTDIR}${PREFIX}/share/man/man1
	install -m 644 ${@:${DESTDIR}${PREFIX}/share/man/man1/%=man/%} $@

compress-man:
	@find ${DESTDIR}${PREFIX}/share/man -type f -name '*.[0-9]' -exec gzip -f {} \; 2>/dev/null || true

installed-extra := ${install-extra:%=${DESTDIR}${PREFIX}/%}
$(installed-extra): ${install-extra}
	install -m 644 ${@:${DESTDIR}${PREFIX}/%=%} $@

install: ${install-dirs} ${installed-headers} ${installed-libs} ${installed-share} ${installed-bin} ${installed-lib-${SYS}} ${installed-man3} ${installed-man1} ${installed-extra}
	@$(MAKE) compress-man

uninstall:
	rm -rf ${installed-headers} ${installed-libs} ${installed-share} ${installed-bin} ${installed-lib-${SYS}} ${install-share-dirs} ${installed-man3} ${installed-man1}

.PHONY: all docs docs-bin compress-man clean install uninstall
