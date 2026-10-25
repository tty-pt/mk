# mk

[![C99](https://img.shields.io/badge/C-C99-555?logo=c)](#)
[![BSD-2-Clause](https://img.shields.io/badge/License-BSD--2--Clause-blue)](#)
[![Make includes](https://img.shields.io/badge/make-includes-6B7280)](#)

> Portable shared Makefile snippets and build targets powering every library in the tty.pt C ecosystem.

`mk` provides unified platform detection, compiler flag normalization, automatic dependency tracking (`.d`), and standard installation rules shared across all libraries and modules under the `tty.pt` umbrella.

---

## Contents

- [Features](#features)
- [Module Snippets](#module-snippets)
- [Standard Targets](#standard-targets)
- [Configuration Variables](#configuration-variables)
- [Usage Example](#usage-example)
- [Installation](#installation)
- [License](#license)

---

## Features

- **Cross-Platform Normalization**: Automatic detection of Linux, macOS (Darwin), OpenBSD, FreeBSD, and WASI toolchains.
- **Shared & Static Rules**: Standard pattern rules for building `.so`, `.a`, `.dylib`, and `.wasm` targets.
- **Automatic Header Dependencies**: Emits `-MMD -MP` flags so header modifications trigger minimal incremental recompilation.
- **Packaging & Installation**: Uniform `install` and `uninstall` targets supporting `DESTDIR` and POSIX directory structures.

---

## Module Snippets

- `portable.mk` — Platform and OS detection, shared library extension (`.so`, `.dylib`), and C99 compiler flag normalization (`-Wall -Wextra -pedantic`).
- `include.mk` — Core build rules for shared and static libraries, binary executables, test execution, and system installation.
- `iso.mk` — Reusable Isomorphic C build module: toolchain flags (`-fvisibility=hidden`, `-Wl,--gc-sections`, `-Wl,--no-entry`), `<ttypt/iso.h>` integration, and automated `check-wasm` ABI verification.
- `glfw.mk` — Optional configuration for immediate-mode GUI and OpenGL libraries (`liblamina` / `libqgl`).

---

## Standard Targets

Every Makefile including `include.mk` inherits a uniform set of targets:

| Target | Description |
| :--- | :--- |
| `all` | Build all default shared libraries (`lib/*.so`), static archives, and binaries (`bin/*`) |
| `test` | Compile and run in-tree unit test suites and regression scripts |
| `clean` | Remove intermediate compilation objects (`.o`, `.d`) |
| `distclean` | Clean all build artifacts, test binaries, and generated directories |
| `install` | Install libraries (`$(LIBDIR)`), public headers (`$(INCDIR)`), and `.pc` files |
| `install-data`| Install shared runtime assets and templates (`$(DATADIR)`) |
| `install-man` | Install manual pages (`$(MANDIR)`) |
| `uninstall` | Remove all installed files from `$(PREFIX)` |

---

## Configuration Variables

Override standard paths during `make` or in environment configuration:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `PREFIX` | `/usr/local` | Base installation directory |
| `BINDIR` | `$(PREFIX)/bin` | Binary executable directory |
| `LIBDIR` | `$(PREFIX)/lib` | Shared and static library directory |
| `INCDIR` | `$(PREFIX)/include/ttypt` | Public C header directory |
| `MANDIR` | `$(PREFIX)/share/man` | Manual pages directory |
| `DATADIR` | `$(PREFIX)/share` | Runtime application assets directory |
| `PKGCONFIGDIR` | `$(LIBDIR)/pkgconfig` | Pkg-config `.pc` file directory |
| `DEBUG` | `0` | Set `DEBUG=1` to enable debug symbols and disable optimization |

---

## Usage Example

In any library `Makefile`:

```makefile
REPO_ROOT != cd ../.. && pwd
include $(REPO_ROOT)/external/mk/portable.mk
include $(REPO_ROOT)/external/mk/include.mk
```

`include.mk` automatically compiles sources from `src/`, places objects in `obj/`, generates libraries in `lib/`, and generates binaries from `bin/*.c`.

---

## Installation

`mk` consists of plain Makefile includes with nothing to compile. Install to system or reference directly from git submodules:

```sh
git clone https://github.com/tty-pt/mk.git
```

## License

BSD 2-Clause License. Copyright (c) 2026, tty-pt. See `LICENSE`.
