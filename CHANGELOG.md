# Changelog

All notable changes to the `mk` tooling ecosystem are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] (target: v0.4.0)

### Added
- **Centralized WebAssembly Toolchain & Optimization Rules (`include.mk`, `portable.mk`)**:
  - Centralized `WASM_CC`, `WASM_CFLAGS` (`-ffreestanding -flto -O3 -D__wasm__ -fvisibility=hidden`), and `WASM_LDFLAGS` (`-mexec-model=reactor -Wl,--gc-sections -Wl,--no-entry -Wl,--allow-undefined`).
  - Added declarative `make wasm` target with automatic symbol extraction from `ISO_EXPORT` and `ISO_EXPORT_AS` using dual GNU Make and BSD Make portable assignment.
  - Integrated automated post-link `wasm-opt -O3` Binaryen pass, reducing `.wasm` binary footprints by 15% to 30%.
  - Added `@tty-pt/*` auto-include discovery in `npm_inc`.
  - Added event bus, optimistic updates, `wasm_init_bin`, and kernel mount exports to WASM allowlist.
- **Universal Substrate Headers**:
  - Added `include/ttypt/stele.h` and `include/ttypt/stele_wasm.h` kernel and client definitions.

### Changed
- **BSD Make & Relinking Performance**:
  - In-memory pattern substitution for obj lists and export flags, eliminating duplicate shell invocations.
  - Safely handle empty `LIB`/`BIN` lists under BSD make.
  - Prevent spurious relinking and batch export allowlist audits.

### Fixed
- **Worktree Prefix, Header Installation & Local Prefix Priority (`include.mk`, `portable.mk`)**:
  - Prioritized local `add-prefix-dirs` and `npm_inc` include/library flags before system `PREFIX` so worktree builds never resolve stale host headers or libraries in `/usr/local`.
  - Support `WORKTREE_PREFIX` and recursive header installation across isolated worktrees.

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
