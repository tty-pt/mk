# Portable .cx transpiler suffix rules (GNU Make + BSD bmake)
MK_CX_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
MK_CX_DIR != if [ -n "${MK_CX_DIR}" ]; then echo "${MK_CX_DIR}"; elif [ -n "${.PARSEDIR}" ]; then echo "${.PARSEDIR}"; else echo "../mk"; fi

_CX_BIN := $(shell if [ -x "${MK_CX_DIR}/../libbud/bin/cx" ]; then echo "${MK_CX_DIR}/../libbud/bin/cx"; else command -v cx 2>/dev/null || echo cx; fi)
_CX_BIN != if [ -x "${MK_CX_DIR}/../libbud/bin/cx" ]; then echo "${MK_CX_DIR}/../libbud/bin/cx"; else command -v cx 2>/dev/null || echo cx; fi
CX ?= ${_CX_BIN}

.SUFFIXES: .cx .cx.c .cx.h

.cx.cx.c:
	${CX} $< -o $@

.cx.cx.h:
	${CX} --emit-header $@ $<
