# Changelog

All notable changes to the `mk` tooling ecosystem are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] (target: v0.4.0)

### Added
- **Portable `.cx` Transpiler Suffix Rules (`cx.mk`, `include.mk`)**:
  - Added `cx.mk` with portable GNU Make and BSD `bmake` suffix rules (`.cx.cx.c` and `.cx.cx.h`, auto-probing `../libbud/bin/cx` or `cx` in `PATH`), included automatically from `include.mk`, and extended `clean` to remove `src/*.cx.c` and `src/*.cx.h` (`c85d5ca`).
- **Centralized Single-Allocator `--wrap` Shim & Non-Overlapping Global-Base Registry (`include.mk`, `wasm_alloc_shim.c`, `scripts/wasm-audit.sh`)**:
  - Added `wasm_alloc_shim.c` and `-Wl,--wrap=malloc/free/calloc/realloc` linker flags for client WASM modules that import `env.memory`, routing all heap allocations through `@tty-pt/stele` (`stele_malloc`/`stele_free`/`stele_calloc`/`stele_realloc`) and eliminating shadow allocator corruption.
  - Enforced non-overlapping `--global-base` registry offsets across all co-loaded WASM modules, including new `WASM_GLOBAL_BASE` entries for `mm` (`131072`) and `jarvis` (`589824`) (`b9bc0f8`).
  - Extended `scripts/wasm-audit.sh` to reject any `--import-memory` WASM binary that exports a competing `malloc`/`free` allocator instead of importing `env.stele_malloc`/`env.stele_free`.
- **Centralized WebAssembly Toolchain & Optimization Rules (`include.mk`, `portable.mk`, `scripts/wasm-allowed-exports.lst`)**:
  - Centralized `WASM_CC`, `WASM_CFLAGS` (`+= -ffreestanding -flto -O3 -D__wasm__ -fvisibility=hidden`), and `WASM_LDFLAGS` (`-mexec-model=reactor -Wl,--gc-sections -Wl,--no-entry -Wl,--allow-undefined`).
  - Added declarative `make wasm` target with automatic symbol extraction from `ISO_EXPORT` and `ISO_EXPORT_AS` using dual GNU Make and BSD Make portable assignment.
  - Integrated automated post-link `wasm-opt -O3` Binaryen pass, reducing `.wasm` binary footprints by 15% to 30%.
  - Added `@tty-pt/*` auto-include discovery in `npm_inc` (checking both root `node_modules/@tty-pt/*/include` and `npm/node_modules/@tty-pt/*/include`).
  - Added event bus, optimistic updates, `wasm_init_bin`, kernel mount, and Stele workqueue (`stl_cpu_count`, `stl_wq_create`, `stl_wq_submit`, `stl_wq_step`, `stl_wq_wait`, `stl_wq_drain`, `stl_wq_destroy`, `stl_wq_worker_entry`) exports to `scripts/wasm-allowed-exports.lst` (`c6c28ec`).
- **Universal Substrate Headers**:
  - Added `include/ttypt/stele.h` and `include/ttypt/stele_wasm.h` kernel and client definitions.

### Changed
- **Atomic Linking, Content-Preserving Install & Single-Invocation Depgen (`include.mk`, `package.json`, `README.md`)**:
  - Switched binary and shared library link targets to atomic `$@.tmp && mv -f $@.tmp $@` writes, changed `.pc`/header/library install rules to content-preserving `cmp -s || install`, and collapsed `.c.o` dependency generation into a single compiler invocation (`-MMD -MP -MT $@ -MF $@.d`) (`3e80dc5`).
  - Standardized package author (`Paulo Quirino <quirinpa@gmail.com>`) and `BSD-2-Clause` license metadata (`1d343c6`).
- **BSD Make & Relinking Performance**:
  - In-memory pattern substitution for obj lists and export flags, eliminating duplicate shell invocations.
  - Safely handle empty `LIB`/`BIN` lists under BSD make.
  - Prevent spurious relinking and batch export allowlist audits.

### Fixed
- **Multi-Library Object Expansion, `clang-18` WASI Probing & Audit Exemptions (`include.mk`, `iso.mk`, `scripts/wasm-audit.sh`)**:
  - Fixed `LIB-obj-y` and `BIN-obj-y` expansion for multi-library/multi-binary Makefiles using `$(foreach ...)` (`a51463e`).
  - Probed `clang-18` for `WASI_CC` in `iso.mk` when available before falling back to `clang` (`bc43bc7`).
  - Skipped standalone `scribe_ux.wasm` in `scripts/wasm-audit.sh` substrate check (`1457347`).
  - Prioritized local `add-prefix-dirs` and `npm_inc` include/library flags before system `PREFIX` and supported `WORKTREE_PREFIX` and recursive header installation across isolated worktrees.

## [0.2.0] - 2026-10-25

### Added
- **Reusable Isomorphic C Engine (`iso.mk`)**: Added normalized toolchain configuration for dual-compiling C modules to native `.so` (SSR) and WebAssembly `.wasm` (browser client). Configures `-fvisibility=hidden`, `-mexec-model=reactor`, `-Wl,--gc-sections`, and `-Wl,--no-entry`.
- **WASM ABI Quality Gate (`scripts/wasm-audit.sh`)**: Added automated auditor checking both WASM imports (preventing native leaks like `corm_`, `axil_`, `source_`, `xy_`) and WASM exports against `wasm-allowed-exports.lst`.
- **Target `check-wasm`**: Build target integrated into `iso.mk` for instant verification of all generated WASM client binaries.

### Changed
- **Purged `-Wl,--export-all` from `portable.mk`**: WASM link flags now require explicit symbol exports via `<ttypt/iso.h>` (`ISO_EXPORT`), eliminating over 300 leaked internal libc symbols per client bundle and reducing binary size by up to 26%.

## [0.1.18] - 2026-09-24

### Changed
- Portable compatibility enhancements across Linux, macOS, and BSD toolchains.
- Improved header search paths and include directives.
