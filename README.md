# mk

[![C99](https://img.shields.io/badge/C-C99-555?logo=c)](#)
[![BSD-2-Clause](https://img.shields.io/badge/License-BSD--2--Clause-blue)](#)
[![Make includes](https://img.shields.io/badge/make-includes-6B7280)](#)

> Portable shared Makefile includes used by every tty.pt C library.

A collection of reusable Makefile snippets covering cross-platform detection
and standard build rules, shared by all libraries under tty.pt's `external/`
tree so every one of them builds the same way.

## Contents

- [Features](#features)
- [Install](#install)
- [Build from source](#build-from-source)
- [Usage](#usage)
- [License](#license)

## Features

- `portable.mk` — Platform and OS detection (Linux, macOS, BSD, WASI), shared
  library extensions (`.so`, `.dylib`), and compiler flag normalization.
- `include.mk` — Standard build rules for C static and shared libraries,
  dependency generation (`.d`), and installation targets.
- `glfw.mk` — Optional GUI framework build configuration.

## Install

Prebuilt packages are distributed from tty.pt for Linux (APT / Alpine / Arch /
Fedora-RHEL), macOS (Homebrew), Windows (winget / MSYS2), and OpenBSD. Follow
the [installation instructions](https://github.com/tty-pt/ci/blob/main/docs/install.md)
and use **mk** as the package name.

## Build from source

mk has **nothing to compile** — it is a set of Makefile snippets. Clone it and
reference the snippets from your own build:

```sh
git clone https://github.com/tty-pt/mk.git
```

**Dependencies:** none.

## Usage

In library Makefiles:

```makefile
REPO_ROOT != cd ../.. && pwd
include $(REPO_ROOT)/external/mk/portable.mk
include $(REPO_ROOT)/external/mk/include.mk
```

`include.mk` provides the standard `all`, `test`, and generic `install`
targets (lib + headers + `.pc`) that every library in the tty.pt tree shares.

## License

BSD 2-Clause License. Copyright (c) 2026, tty-pt. See `LICENSE`.