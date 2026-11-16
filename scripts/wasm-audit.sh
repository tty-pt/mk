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
CHECK_SUBSTRATE=0
WASM_FILES=""

while [ $# -gt 0 ]; do
	case "$1" in
		--check-substrate)
			CHECK_SUBSTRATE=1
			shift
			;;
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

if [ "$CHECK_SUBSTRATE" -eq 1 ]; then
	if ! command -v wasm-objdump >/dev/null 2>&1; then
		echo "wasm-audit [--check-substrate]: skipped (no wasm-objdump)"
		exit 0
	fi
	REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." 2>/dev/null && pwd || pwd)"
	STELE_WASM="$REPO_ROOT/external/libstele/npm/dist/stele.wasm"
	SUB_FAIL=0

	if [ ! -f "$STELE_WASM" ]; then
		echo "FAIL [substrate]: missing $STELE_WASM" >&2
		exit 1
	fi

	# 1. Verify stele.wasm exports memory, malloc, free, calloc, realloc, _initialize, and has no 256MB max cap
	stele_dump="$(wasm-objdump -x "$STELE_WASM" 2>/dev/null)"
	for req in '"memory"' '"malloc"' '"free"' '"calloc"' '"realloc"' '"_initialize"'; do
		if ! printf '%s\n' "$stele_dump" | grep -qF -- "-> $req"; then
			echo "FAIL [substrate]: stele.wasm missing required export $req" >&2
			SUB_FAIL=1
		fi
	done
	if printf '%s\n' "$stele_dump" | grep -E 'pages: initial=[0-9]+ max=4096' >/dev/null 2>&1; then
		echo "FAIL [substrate]: stele.wasm still has 256MB (max=4096 pages) hard memory cap" >&2
		SUB_FAIL=1
	fi
	stele_sp="$(printf '%s\n' "$stele_dump" | sed -n 's/.*global\[0\].*init i32=\([0-9]*\).*/\1/p')"
	if [ -n "$stele_sp" ] && [ "$stele_sp" -lt 2097152 ]; then
		echo "FAIL [substrate]: stele.wasm stack pointer ($stele_sp) is below 2MB (2097152) reservation" >&2
		SUB_FAIL=1
	fi

	# 2. Verify all downstream npm/dist/*.wasm modules
	BANDS_FILE="$(mktemp)"
	trap 'rm -f "$BANDS_FILE"' EXIT
	if [ -z "$WASM_FILES" ]; then
		WASM_FILES="$(find "$REPO_ROOT/external" -maxdepth 4 -path "*/npm/dist/*.wasm" -not -path "*/wllama/*" | sort)"
	fi
	for w in $WASM_FILES; do
		[ -f "$w" ] || continue
		[ -L "$w" ] && continue
		b="$(basename "$w")"
		case "$b" in
			stele.wasm|axil-auren.wasm) continue ;;
			chunk.wasm)
				# chunk.wasm is an alias of areole.wasm
				if [ -f "$REPO_ROOT/external/libareole/npm/dist/areole.wasm" ] && cmp -s "$w" "$REPO_ROOT/external/libareole/npm/dist/areole.wasm"; then
					continue
				fi
				;;
		esac
		dump="$(wasm-objdump -x "$w" 2>/dev/null)"
		dis="$(wasm-objdump -d "$w" 2>/dev/null | head -n 25)"

		if ! printf '%s\n' "$dump" | grep -q '<- env\.memory'; then
			echo "FAIL [substrate]: $w does not import env.memory (private memory isolation bug)" >&2
			SUB_FAIL=1
		fi
		if printf '%s\n' "$dump" | grep -qF -- '-> "memory"'; then
			echo "FAIL [substrate]: $w exports its own memory alongside env.memory" >&2
			SUB_FAIL=1
		fi
		if ! printf '%s\n' "$dump" | grep -qF -- '-> "_initialize"'; then
			echo "FAIL [substrate]: $w is not a reactor module (missing _initialize export)" >&2
			SUB_FAIL=1
		fi
		for forbidden_exp in '"_start"' '"malloc"' '"free"' '"calloc"' '"realloc"'; do
			if printf '%s\n' "$dump" | grep -qF -- "-> $forbidden_exp"; then
				echo "FAIL [substrate]: $w exports $forbidden_exp (violates single-allocator / reactor invariant)" >&2
				SUB_FAIL=1
			fi
		done

		# Determine [base_min, sp_max] band
		sp="$(printf '%s\n' "$dump" | sed -n 's/.*global\[0\].*init i32=\([0-9]*\).*/\1/p')"
		data_min="$(printf '%s\n' "$dump" | sed -n 's/.*segment\[0\] memory=0 size=[0-9]* - init i32=\([0-9]*\).*/\1/p')"
		init_const="$(printf '%s\n' "$dis" | sed -n 's/.*i32\.const \([0-9][0-9]*\).*/\1/p' | head -n 1)"

		low="${data_min:-$init_const}"
		high="${sp:-$low}"
		if [ -n "$low" ] && [ -n "$high" ]; then
			if [ "$low" -lt 65536 ] || [ "$high" -ge 2097152 ]; then
				echo "FAIL [substrate]: $w band [$low .. $high] is outside [65536 .. 2097152)" >&2
				SUB_FAIL=1
			fi
			printf '%s %s %s\n' "$low" "$high" "$b" >> "$BANDS_FILE"
		fi
	done

	# Check pairwise non-overlap of [low, high] bands sorted by low
	prev_low=0
	prev_high=0
	prev_name=""
	while read -r low high name; do
		[ -z "$low" ] && continue
		if [ "$prev_high" -gt "$low" ]; then
			echo "FAIL [substrate]: memory band overlap between $prev_name [$prev_low..$prev_high] and $name [$low..$high]" >&2
			SUB_FAIL=1
		fi
		prev_low="$low"
		prev_high="$high"
		prev_name="$name"
	done <<EOF
$(sort -n -k1,1 "$BANDS_FILE")
EOF

	if [ "$SUB_FAIL" -ne 0 ]; then
		echo "wasm-audit [--check-substrate]: FAILED" >&2
		exit 1
	fi
	echo "wasm-audit [--check-substrate]: PASS (all modules share env.memory, single stele allocator, disjoint bands in [64KB..2MB), unbounded 4GB heap)"
	exit 0
fi

if [ -z "$WASM_FILES" ]; then
	echo "Usage: $0 [--check-substrate] [--allow-imports=<file>] [--allow-exports=<file>] <file.wasm...>" >&2
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
