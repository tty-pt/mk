MPATH != [ -n "${.PARSEDIR}" ] && echo "${.PARSEDIR}" || dirname "$$(echo "${MAKEFILE_LIST}" | tr " " "\\n" | tail -n 1)"
include ${MPATH}/portable.mk

WARN := -Wall -Wextra -Wpedantic
CFLAGS += ${WARN}

share-dir ?= ${bname}
all ?= ${bname}

WASM != echo "${all}" | tr ' ' '\n' | grep '\.wasm' || true
LIB != echo "${all}" | tr ' ' '\n' | grep '^lib' || true
BIN != echo "${all}" | tr ' ' '\n' | grep -v '^lib' | grep -v '\.wasm' || true

INSTALL_BIN ?= ${BIN}

ONELIB != echo "${LIB}" | awk '{print $$1}'
ONELIB := ${ONELIB:lib%=%}

FOLDER ?= ttypt
HEADERS != ls include/${FOLDER} 2>/dev/null || true
HEADERS := ${HEADERS:%=${FOLDER}/%}

.SUFFIXES: .${SO} .m .c .o .cpp

WASM_PATH ?= .
all := objects-set.mk ${LIB:%=lib/%.${SO}} ${BIN:%=bin/%${EXE}} ${WASM:%=${WASM_PATH}/%}

all: ${all}

LIB-obj-default != for l in ${LIB}; do printf 'src/%s.o ' "$$l"; done
BIN-obj-default != for b in ${BIN}; do printf 'src/%s.o ' "$$b"; done

LIB-obj-y ?= ${LIB-obj-default} ${${LIB:%=%-obj-y}} ${${LIB:%=%-obj-y-${uname}}}
BIN-obj-y ?= ${BIN-obj-default} ${${BIN:%=%-obj-y}} ${${BIN:%=%-obj-y-${uname}}}

CFLAGS-LIB := -fPIC ${EXTRA_CFLAGS}

objects-set.mk:
	@rm -f $@
	@for obj in ${LIB-obj-y} ""; do \
		[ -z "$$obj" ] && continue; \
		robj=`echo $$obj | sed 's|.*/||' | tr '.' '-'` ; \
		echo CFLAGS-$$robj := ${CFLAGS-LIB} >> $@ ; \
	done
	@for obj in ${BIN-obj-y} ""; do \
		[ -z "$$obj" ] && continue; \
		robj=`echo $$obj | sed 's|.*/||' | tr '.' '-'` ; \
		echo CFLAGS-$$robj := ${CFLAGS-BIN} >> $@ ; \
	done
	@touch $@

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
	@test -z "${SONAME-${@:lib/%.${SO}=%}}" || ln -sf ${@:lib/%=%} lib/${SONAME-${@:lib/%.${SO}=%}}.${SO}

.c.o:
	@rm -f $@.d; ${cc} ${CFLAGS} ${CFLAGS-${@:src/%.o=%-o}} -MM -MT $@ $< > $@.d 2>/dev/null || true
	${cc} -c -o $@ ${CFLAGS} ${CFLAGS-${@:src/%.o=%-o}} $<

DEP_FILES != for f in ${LIB-obj-y} ${BIN-obj-y}; do [ -n "$$f" ] && [ -f "$${f%.o}.o.d" ] && printf '%s.o.d ' "$${f%.o}"; done; printf '/dev/null'
-include ${DEP_FILES}

.m.o:
	${cc} -c -o $@ ${CFLAGS} ${CFLAGS-m-${uname}} ${CFLAGS-${@:src/%.o=%-o}} $<

.cpp.o:
	${cxx} -c -o $@ ${CFLAGS} ${CFLAGS-${@:src/%.o=%-o}} $<

dirs += bin lib
$(dirs):
	@mkdir $@ 2>/dev/null || true

clean:
	@rm -rf src/*.o ${LIB:%=lib/%.${SO}} ${LIB:%=lib/${SONAME-%}.${SO}} \
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
	test -z "${SONAME-${@:${DESTDIR}${PREFIX}/lib/%.${SO}=%}}" || ln -sf ${@:${DESTDIR}${PREFIX}/lib/%=%} ${DESTDIR}${PREFIX}/lib/${SONAME-${@:${DESTDIR}${PREFIX}/lib/%.${SO}=%}}.${SO}

installed-share := ${share:%=${DESTDIR}${PREFIX}/share/${share-dir}/%}
$(installed-share): ${install-share-dirs} ${share}
	mkdir -p ${@D}
	install -m 644 ${@:${DESTDIR}${PREFIX}/share/${share-dir}/%=%} $@

installed-lib-Windows := $(LIB:%=${DESTDIR}${PREFIX}/bin/%.${SO})
$(installed-lib-Windows): ${LIB:%=lib/%.${SO}} ${DESTDIR}${PREFIX}/bin
	install -m 644 ${@:${DESTDIR}${PREFIX}/bin/%=lib/%} $@

installed-dep-dlls-Windows := ${install-dep-dlls-Windows:%=${DESTDIR}${PREFIX}/bin/%}
$(installed-dep-dlls-Windows): ${DESTDIR}${PREFIX}/bin
	install -m 644 ${PREFIX}/bin/${@:${DESTDIR}${PREFIX}/bin/%=%} $@

installed-bin := $(INSTALL_BIN:%=$(DESTDIR)$(PREFIX)/bin/%${EXE})
$(installed-bin): ${INSTALL_BIN:%=bin/%${EXE}} ${DESTDIR}${PREFIX}/bin
	install -m 755 ${@:$(DESTDIR)$(PREFIX)/%=%} $@

install-info:
	@echo ${installed-bin}


MAN3 != test -f Doxyfile && ls man/*.3 2>/dev/null || true
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

install: ${install-dirs} ${installed-headers} ${installed-libs} ${installed-share} ${installed-bin} ${installed-lib-${SYS}} ${installed-dep-dlls-${SYS}} ${installed-man3} ${installed-man1} ${installed-extra}
	@$(MAKE) compress-man

uninstall:
	rm -rf ${installed-headers} ${installed-libs} ${installed-share} ${installed-bin} ${installed-lib-${SYS}} ${installed-dep-dlls-${SYS}} ${install-share-dirs} ${installed-man3} ${installed-man1}

${WASM_PATH}/%.wasm:
	@if echo 'int main(void){}' | ${WASI_CC} ${WASM_CFLAGS} -x c - -c -o /dev/null >/dev/null 2>&1; then \
		${WASI_CC} \
			$($*-cflags) ${WASM_CFLAGS} ${WASM_LDFLAGS} -o $@ $($*-src); \
	else \
		echo "Skipping WASM build of $@ — see README.md (WASM Setup)"; \
	fi

wasm: ${WASM:%=${WASM_PATH}/%}

clean-wasm:
	rm -f ${WASM:%=${WASM_PATH}/%}

clean: clean-wasm

.PHONY: all docs docs-bin compress-man clean install uninstall wasm clean-wasm
