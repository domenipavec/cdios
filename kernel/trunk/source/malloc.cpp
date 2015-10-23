/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */

#include "malloc.h"
#include "new.h"

#include "kernel.h"

void* malloc(u64int size) {
  return Kernel::get_instance()->dalloc.allocate(size);
}

void free(void* pointer) {
  Kernel::get_instance()->dalloc.free(pointer);
}

void* operator new (u64int size) {
  return malloc(size);
}

void operator delete (void* pointer) {
  free(pointer);
}

void* operator new[] (u64int size) {
  return malloc(size);
}

void operator delete[] (void* pointer) {
  free(pointer);
}
