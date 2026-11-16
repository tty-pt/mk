/*
 * Copyright (c) 2026, tty-pt
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * Universal WebAssembly Single-Allocator Linker Shim:
 * Redirects all downstream C calls to malloc, free, calloc, and realloc
 * (via wasm-ld --wrap) to the shared @tty-pt/stele substrate allocator,
 * ensuring wasi-libc's private dlmalloc and sbrk are never linked into
 * downstream reactor modules.
 */

#include <stddef.h>

#if defined(__wasm__)

__attribute__((import_module("env"), import_name("malloc")))
extern void *__stele_host_malloc(size_t sz);

__attribute__((import_module("env"), import_name("free")))
extern void __stele_host_free(void *ptr);

__attribute__((import_module("env"), import_name("calloc")))
extern void *__stele_host_calloc(size_t nmemb, size_t sz);

__attribute__((import_module("env"), import_name("realloc")))
extern void *__stele_host_realloc(void *ptr, size_t sz);

void *__wrap_malloc(size_t sz)
{
	return __stele_host_malloc(sz);
}

void __wrap_free(void *ptr)
{
	__stele_host_free(ptr);
}

void *__wrap_calloc(size_t nmemb, size_t sz)
{
	return __stele_host_calloc(nmemb, sz);
}

void *__wrap_realloc(void *ptr, size_t sz)
{
	return __stele_host_realloc(ptr, sz);
}

#endif
