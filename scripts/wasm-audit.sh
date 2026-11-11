#!/bin/sh
set -eu
# wasm-audit.sh — Integrated ABI verification for WebAssembly bundles.
# Verifies:
#   1. Zero forbidden native symbols in WASM Import section (W06 / D18)
#   2. Zero unsanctioned or internal libc symbols in WASM Export section

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_EXPORTS_ALLOWLIST="$SCRIPT_DIR/wasm-allowed-exports.lst"

EXTRA_IMPORTS_ALLOWLIST=""
EXTRA_EXPORTS_ALLOWLIST=""
WASM_FILES=""

while [ $# -gt 0 ]; do
	case "$1" in
		--allow-imports=*)
			EXTRA_IMPORTS_ALLOWLIST="${1#*=}"
			shift
			;;
		--allow-imports)
			EXTRA_IMPORTS_ALLOWLIST="$2"
			shift 2
			;;
		--allow-exports=*)
			EXTRA_EXPORTS_ALLOWLIST="${1#*=}"
			shift
			;;
		--allow-exports)
			EXTRA_EXPORTS_ALLOWLIST="$2"
			shift 2
			;;
		*)
			WASM_FILES="$WASM_FILES $1"
			shift
			;;
	esac
done

if [ -z "$WASM_FILES" ]; then
	echo "Usage: $0 [--allow-imports=<file>] [--allow-exports=<file>] <file.wasm...>" >&2
	exit 1
fi

FAIL=0

for wasm in $WASM_FILES; do
	[ -f "$wasm" ] || continue
	basename="$(basename "$wasm")"

	# 1. Audit Imports
	if command -v wasm-objdump >/dev/null 2>&1; then
		imports_out="$(wasm-objdump -j Import -x "$wasm" 2>/dev/null || true)"
		if echo "$imports_out" | grep -Eq '<(corm_|source_|axil_|hyle_source|XY_)|<- env\.(corm_|source_|axil_|hyle_source|XY_)'; then
			echo "FAIL [imports]: $basename imports forbidden native symbol:" >&2
			echo "$imports_out" | grep -E '<(corm_|source_|axil_|hyle_source|XY_)|<- env\.(corm_|source_|axil_|hyle_source|XY_)' >&2 || true
			FAIL=1
		fi
	elif strings "$wasm" 2>/dev/null | grep -qE 'corm_|source_item|axil_|xy_call'; then
		echo "WARN [imports]: $basename contains native-like strings (no wasm-objdump)" >&2
	fi

	# 2. Audit Exports
	if command -v wasm-objdump >/dev/null 2>&1; then
		exports_out="$(wasm-objdump -j Export -x "$wasm" 2>/dev/null | grep -E 'func\[' | awk '{print $NF}' | tr -d '"' || true)"
		if [ -n "$exports_out" ]; then
			leaks=$(printf '%s\n' "$exports_out" | grep -vFxf "$DEFAULT_EXPORTS_ALLOWLIST" || true)
			if [ -n "$leaks" ] && [ -n "$EXTRA_EXPORTS_ALLOWLIST" ] && [ -f "$EXTRA_EXPORTS_ALLOWLIST" ]; then
				leaks=$(printf '%s\n' "$leaks" | grep -vFxf "$EXTRA_EXPORTS_ALLOWLIST" || true)
			fi
			if [ -n "$leaks" ]; then
				for sym in $leaks; do
					echo "FAIL [exports]: $basename leaks unsanctioned symbol into export table: '$sym'" >&2
					FAIL=1
				done
			fi
		fi
	fi
done

if [ "$FAIL" -ne 0 ]; then
	echo "wasm-audit: FAILED verification" >&2
	exit 1
fi

echo "wasm-audit: PASS"
