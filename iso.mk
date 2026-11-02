# external/mk/iso.mk — Reusable Isomorphic C Build & Validation Module for tty.pt
#
# Provides:
#   1. Header search path to <ttypt/iso.h>
#   2. Normalized CFLAGS / LDFLAGS for native .so and browser .wasm targets
#   3. Built-in WASM binary ABI verification target (check-wasm)

MK_ISO_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

# Toolchains
CC      ?= clang
WASI_CC ?= clang

# Native Shared Library Flags
ISO_SO_CFLAGS   += -fPIC -fvisibility=hidden -I$(MK_ISO_DIR)../libqsys/include -I$(MK_ISO_DIR)include
ISO_SO_LDFLAGS  += -shared

# WebAssembly Reactor Flags
ISO_WASM_CFLAGS  += --target=wasm32-wasi -fvisibility=hidden -D__wasm__ -I$(MK_ISO_DIR)../libqsys/include -I$(MK_ISO_DIR)include
ISO_WASM_LDFLAGS += -mexec-model=reactor \
                    -Wl,--gc-sections \
                    -Wl,--no-entry \
                    -Wl,--export=malloc \
                    -Wl,--export=free \
                    -Wl,--export=_initialize \
                    -Wl,--allow-undefined

ISO_WASM_AUDIT = $(MK_ISO_DIR)scripts/wasm-audit.sh
ISO_WASM_ALLOWED_EXPORTS = $(MK_ISO_DIR)scripts/wasm-allowed-exports.lst

.PHONY: check-wasm
check-wasm:
	@if [ -n "$(WASM_TARGETS)" ]; then \
		sh $(ISO_WASM_AUDIT) $(WASM_TARGETS); \
	fi
