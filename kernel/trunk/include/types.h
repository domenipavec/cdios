/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file types.h
 * @author Domen Ipavec
 *
 * @brief
 * Defines integers of fixed size (u64int, ...) for
 * easier use, ...
 */

#ifndef TYPES_H
#define TYPES_H

// We specify lengths for easier use here.
typedef unsigned long  u64int;
typedef          long  s64int;
typedef unsigned int   u32int;
typedef          int   s32int;
typedef unsigned short u16int;
typedef          short s16int;
typedef unsigned char  u8int;
typedef          char  s8int;

#define NULL 0

#endif // TYPES_H
