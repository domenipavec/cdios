/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file malloc.h
 * @author Domen Ipavec
 *
 * @brief
 * Malloc function, calling kernel dalloc class.
 */

#ifndef MALLOC_H
#define MALLOC_H

#include "types.h"

void* malloc(u64int size);

void free(void* pointer);

#endif // MALLOC_H
