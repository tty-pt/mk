# mk — Portable Build System Includes

Shared Makefile components and cross-platform detection rules used across all sub-libraries in `external/`.

## Overview

`external/mk` provides reusable Makefile snippets:
- `portable.mk` — Platform and OS detection (Linux, macOS, BSD, WASI), shared library extensions (`.so`, `.dylib`), and compiler flag normalization.
- `include.mk` — Standard build rules for C static and shared libraries, dependency generation (`.d`), and installation targets.
- `glfw.mk` — Optional GUI framework build configuration.

## Usage

In library Makefiles:

```makefile
REPO_ROOT != cd ../.. && pwd
include $(REPO_ROOT)/external/mk/portable.mk
include $(REPO_ROOT)/external/mk/include.mk
```
