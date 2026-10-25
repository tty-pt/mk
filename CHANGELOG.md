# Changelog

All notable changes to the `mk` tooling ecosystem are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
