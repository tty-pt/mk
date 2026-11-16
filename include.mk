MPATH := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
MPATH != if [ -n "${MPATH}" ]; then echo "${MPATH}"; elif [ -n "${.PARSEDIR}" ]; then echo "${.PARSEDIR}"; elif [ -n "${MAKEFILE_LIST:M*include.mk:H}" ]; then echo "${MAKEFILE_LIST:M*include.mk:H}"; else echo "../mk"; fi
include ${MPATH}/portable.mk

WARN := -Wall -Wextra -Wpedantic

# NPM C-Dependency Auto-Discovery (portable across GNU Make and BSD Make):
# Automatically adds node_modules/@tty-pt/*/include and node_modules/@ttypt/*/include to CFLAGS if present (except for root leaf libstele)
npm_inc := $(shell [ "${bname}" != "libstele" ] && for d in npm/node_modules/@tty-pt/*/include npm/node_modules/@ttypt/*/include node_modules/@tty-pt/*/include node_modules/@ttypt/*/include ../node_modules/@tty-pt/*/include ../node_modules/@ttypt/*/include ../../node_modules/@tty-pt/*/include ../../node_modules/@ttypt/*/include; do [ -d "$$d" ] && echo "-I$$d"; done || true)
npm_inc != [ "${bname}" != "libstele" ] && for d in npm/node_modules/@tty-pt/*/include npm/node_modules/@ttypt/*/include node_modules/@tty-pt/*/include node_modules/@ttypt/*/include ../node_modules/@tty-pt/*/include ../node_modules/@ttypt/*/include ../../node_modules/@tty-pt/*/include ../../node_modules/@ttypt/*/include; do [ -d "$$d" ] && echo "-I$$d"; done || true
CFLAGS := ${WARN} ${npm_inc} ${CFLAGS}

# Centralized WebAssembly Toolchain & Optimization Rules
WASM_CC ?= clang
WASM_CFLAGS += -I../libstele/include -I../mk/include ${npm_inc}
WASM_LDFLAGS ?=
WASM_OPT := $(shell command -v wasm-opt 2>/dev/null || true)
WASM_OPT != command -v wasm-opt 2>/dev/null || true

share-dir ?= ${bname}
all ?= ${bname}

LIB := $(shell echo "${all}" | tr ' ' '\n' | grep '^lib' || true)
LIB != echo "${all}" | tr ' ' '\n' | grep '^lib' || true
BIN := $(shell echo "${all}" | tr ' ' '\n' | grep -v '^lib' | grep -v '\.wasm' || true)
BIN != echo "${all}" | tr ' ' '\n' | grep -v '^lib' | grep -v '\.wasm' || true

INSTALL_BIN ?= ${BIN}

ONELIB := $(shell set -- ${LIB}; echo "$$1")
ONELIB != set -- ${LIB}; echo "$$1"
ONELIB := ${ONELIB:lib%=%}

# Canonical non-overlapping --global-base registry:
# [65536 .. 2097152) is reserved for downstream reactor static data & 32KB stacks.
# stele.wasm sits at 2097152 (2 MB) and its dlmalloc heap grows upward from ~2.07 MB to 4 GB.
WASM_GLOBAL_BASE ?= $(shell case "${ONELIB}" in \
	stele) echo 2097152 ;; \
	corm) echo 65536 ;; \
	lemma) echo 196608 ;; \
	sepal) echo 327680 ;; \
	joint) echo 458752 ;; \
	islet) echo 720896 ;; \
	hyle) echo 851968 ;; \
	xylem) echo 983040 ;; \
	hyle-source) echo 1114112 ;; \
	pitch|transp) echo 1245184 ;; \
	bud) echo 1376256 ;; \
	lamina) echo 1507328 ;; \
	chaff|noise) echo 1638400 ;; \
	areole|chunk) echo 1769472 ;; \
	axil-auren|auren) echo 1900544 ;; \
	*) echo 2031616 ;; \
esac)
WASM_GLOBAL_BASE != case "${ONELIB}" in \
	stele) echo 2097152 ;; \
	corm) echo 65536 ;; \
	lemma) echo 196608 ;; \
	sepal) echo 327680 ;; \
	joint) echo 458752 ;; \
	islet) echo 720896 ;; \
	hyle) echo 851968 ;; \
	xylem) echo 983040 ;; \
	hyle-source) echo 1114112 ;; \
	pitch|transp) echo 1245184 ;; \
	bud) echo 1376256 ;; \
	lamina) echo 1507328 ;; \
	chaff|noise) echo 1638400 ;; \
	areole|chunk) echo 1769472 ;; \
	axil-auren|auren) echo 1900544 ;; \
	*) echo 2031616 ;; \
esac

WASM_CORE_LDFLAGS := $(shell if [ "${bname}" = "libstele" ] || [ "${ONELIB}" = "stele" ]; then \
	echo "-mexec-model=reactor -Wl,--gc-sections -Wl,--no-entry -Wl,--allow-undefined -Wl,--global-base=${WASM_GLOBAL_BASE} -Wl,--initial-memory=16777216 -Wl,--export=malloc -Wl,--export=free -Wl,--export=calloc -Wl,--export=realloc"; \
else \
	echo "-mexec-model=reactor -Wl,--gc-sections -Wl,--no-entry -Wl,--allow-undefined -Wl,--import-memory -Wl,-z,stack-size=32768 -Wl,--global-base=${WASM_GLOBAL_BASE} -Wl,--wrap=malloc -Wl,--wrap=free -Wl,--wrap=calloc -Wl,--wrap=realloc"; \
fi)
WASM_CORE_LDFLAGS != if [ "${bname}" = "libstele" ] || [ "${ONELIB}" = "stele" ]; then \
	echo "-mexec-model=reactor -Wl,--gc-sections -Wl,--no-entry -Wl,--allow-undefined -Wl,--global-base=${WASM_GLOBAL_BASE} -Wl,--initial-memory=16777216 -Wl,--export=malloc -Wl,--export=free -Wl,--export=calloc -Wl,--export=realloc"; \
else \
	echo "-mexec-model=reactor -Wl,--gc-sections -Wl,--no-entry -Wl,--allow-undefined -Wl,--import-memory -Wl,-z,stack-size=32768 -Wl,--global-base=${WASM_GLOBAL_BASE} -Wl,--wrap=malloc -Wl,--wrap=free -Wl,--wrap=calloc -Wl,--wrap=realloc"; \
fi

WASM_ALLOC_SHIM := $(shell if [ "${bname}" != "libstele" ] && [ "${ONELIB}" != "stele" ] && [ -f "${MPATH}/wasm_alloc_shim.c" ]; then echo "${MPATH}/wasm_alloc_shim.c"; fi)
WASM_ALLOC_SHIM != if [ "${bname}" != "libstele" ] && [ "${ONELIB}" != "stele" ] && [ -f "${MPATH}/wasm_alloc_shim.c" ]; then echo "${MPATH}/wasm_alloc_shim.c"; fi

WASM_PATH ?= npm/dist
WASM ?= $(shell if [ -n "${WASM_SRCS}" ]; then echo "${ONELIB}.wasm"; fi)
WASM != if [ -n "${WASM_SRCS}" ]; then echo "${ONELIB}.wasm"; fi

WASM_MACRO_EXPORTS := $(shell for f in ${WASM_SRCS}; do [ -f "$$f" ] && awk -F'[(),]' '/ISO_EXPORT_AS/ {gsub(/[[:space:]]/, "", $$4); if ($$4 != "") print $$4; next} /(ISO_EXPORT|WASM_EXPORT)/ {gsub(/[[:space:]]/, "", $$3); if ($$3 != "") print $$3}' "$$f" 2>/dev/null; done | sort -u || true)
WASM_MACRO_EXPORTS != for f in ${WASM_SRCS}; do [ -f "$$f" ] && awk -F'[(),]' '/ISO_EXPORT_AS/ {gsub(/[[:space:]]/, "", $$4); if ($$4 != "") print $$4; next} /(ISO_EXPORT|WASM_EXPORT)/ {gsub(/[[:space:]]/, "", $$3); if ($$3 != "") print $$3}' "$$f" 2>/dev/null; done | sort -u || true

ALL_WASM_EXPORTS = ${WASM_EXPORTS} ${WASM_MACRO_EXPORTS}

WASM_EXPORT_FLAGS := ${ALL_WASM_EXPORTS:%=-Wl,--export=%}

wasmtarget := ${WASM:%=${WASM_PATH}/%}

FOLDER ?= ttypt
HEADERS := $(shell [ -d include ] && (cd include && find . -type f -name '*.h' | sed 's|^\./||') 2>/dev/null || true)
HEADERS != [ -d include ] && (cd include && find . -type f -name '*.h' | sed 's|^\./||') 2>/dev/null || true

.SUFFIXES: .${SO} .m .c .o .cpp

all := objects-set.mk ${LIB:%=lib/%.${SO}} ${BIN:%=bin/%${EXE}}

all: ${all}

LIB-obj-default := $(shell [ -n "${LIB}" ] && for l in ${LIB}; do echo "src/$$l.o"; done || true)
LIB-obj-default != [ -n "${LIB}" ] && for l in ${LIB}; do echo "src/$$l.o"; done || true
BIN-obj-default := $(shell [ -n "${BIN}" ] && for b in ${BIN}; do echo "src/$$b.o"; done || true)
BIN-obj-default != [ -n "${BIN}" ] && for b in ${BIN}; do echo "src/$$b.o"; done || true

LIB-obj-y ?= ${LIB-obj-default} ${${LIB:%=%-obj-y}} ${${LIB:%=%-obj-y-${uname}}}
BIN-obj-y ?= ${BIN-obj-default} ${${BIN:%=%-obj-y}} ${${BIN:%=%-obj-y-${uname}}}

CFLAGS-LIB := -fPIC ${EXTRA_CFLAGS}

objects-set.mk: Makefile
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
$(bintarget): ${LIB:%=lib/%.${SO}} ${BIN-obj-y}
	@mkdir -p ${@D}
	${cc} -o $@ ${@:bin/%${EXE}=src/%.o} ${${@:bin/%${EXE}=%}-obj-y} ${LDFLAGS} ${LDFLAGS-${@:bin/%${EXE}=%}} ${LDFLAGS-${@:bin/%${EXE}=%}-${SYS}} ${LDFLAGS-${@:bin/%${EXE}=%}-${uname}} ${LDLIBS-${@:bin/%${EXE}=%}-${SYS}} ${LDLIBS-${@:bin/%${EXE}=%}} ${LDLIBS-${@:bin/%${EXE}=%}-${uname}} ${LDLIBS}

libtarget := ${LIB:%=lib/%.${SO}}
$(libtarget): ${LIB:%=src/%.o} ${LIB-obj-y}
	@mkdir -p ${@D}
	${cc} -o $@ ${@:lib/%.${SO}=src/%.o} ${${@:lib/%.${SO}=%}-obj-y} ${${@:lib/%.${SO}=%}-obj-y-${uname}} -shared ${LDFLAGS} ${LDFLAGS-${@:lib/%.${SO}=%}-${SYS}} ${LDFLAGS-${@:lib/%.${SO}=%}-${uname}} ${LDFLAGS-${@:lib/%.${SO}=%}} ${LDLIBS-${@:lib/%.${SO}=%}} ${LDLIBS-${@:lib/%.${SO}=%}-${SYS}} ${LDLIBS-${@:lib/%.${SO}=%}-${uname}} ${LDLIBS}
	@test -z "${SONAME-${@:lib/%.${SO}=%}}" || ln -sf ${@:lib/%=%} lib/${SONAME-${@:lib/%.${SO}=%}}.${SO}

.c.o:
	@rm -f $@.d; ${cc} ${CFLAGS} ${CFLAGS-${@:src/%.o=%-o}} -MM -MP -MT $@ $< > $@.d 2>/dev/null || true
	${cc} -c -o $@ ${CFLAGS} ${CFLAGS-${@:src/%.o=%-o}} $<

DEP_FILES := $(shell for f in ${LIB-obj-y} ${BIN-obj-y}; do [ -f "$${f%.o}.o.d" ] && echo "$${f%.o}.o.d"; done; echo '/dev/null')
DEP_FILES != for f in ${LIB-obj-y} ${BIN-obj-y}; do [ -f "$${f%.o}.o.d" ] && echo "$${f%.o}.o.d"; done; echo '/dev/null'
-include ${DEP_FILES}

.m.o:
	${cc} -c -o $@ ${CFLAGS} ${CFLAGS-m-${uname}} ${CFLAGS-${@:src/%.o=%-o}} $<

.cpp.o:
	${cxx} -c -o $@ ${CFLAGS} ${CFLAGS-${@:src/%.o=%-o}} $<

dirs += bin lib
$(dirs):
	@mkdir $@ 2>/dev/null || true

CLEAN_EXTRA ?=

clean: clean-extra
	@rm -rf src/*.o src/*.o.d src/*.d ${LIB:%=lib/%.${SO}} ${LIB:%=lib/${SONAME-%}.${SO}} \
		${BIN:%=bin/%${EXE}} ${CLEAN_EXTRA} 2>/dev/null || true

clean-extra::


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
	mkdir -p ${@D}
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

install: ${install-dirs} ${installed-headers} ${installed-libs} ${installed-share} ${installed-bin} ${installed-lib-${SYS}} ${installed-dep-dlls-${SYS}} ${installed-man3} ${installed-man1} ${installed-extra}
	@$(MAKE) compress-man

uninstall:
	rm -rf ${installed-headers} ${installed-libs} ${installed-share} ${installed-bin} ${installed-lib-${SYS}} ${installed-dep-dlls-${SYS}} ${install-share-dirs} ${installed-man3} ${installed-man1}

wasm: ${wasmtarget}

$(wasmtarget): ${WASM_SRCS} ${WASM_ALLOC_SHIM}
	@if [ -n "${WASM_SRCS}" ]; then \
		mkdir -p ${@D} && \
		${WASM_CC} ${WASM_CFLAGS} ${WASM_EXTRA_CFLAGS} ${WASM_CORE_LDFLAGS} ${WASM_LDFLAGS} ${WASM_EXPORT_FLAGS} -o $@ ${WASM_SRCS} ${WASM_ALLOC_SHIM} && \
		if [ -n "${WASM_OPT}" ]; then ${WASM_OPT} -O3 $@ -o $@ 2>/dev/null || true; fi; \
	fi

clean-wasm:
	rm -f ${wasmtarget}

clean: clean-wasm

.PHONY: all docs docs-bin compress-man clean clean-extra install uninstall wasm clean-wasm
