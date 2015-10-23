/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file new.h
 * @author Domen Ipavec
 *
 * @brief
 * C++ new definition, calling malloc.
 */

#ifndef NEW_H
#define NEW_H

#include "types.h"

void* operator new (u64int size);
void operator delete (void* pointer);

void* operator new[] (u64int size);
void operator delete[] (void* pointer);

#endif // NEW_H
