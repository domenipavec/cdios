/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file main.h
 * @author Domen Ipavec
 *
 * @brief
 * Defines kmain() as extern "C" so we can
 * specify it in linker script, define extern
 * pointers to ctors and dtors sections.
 */

#ifndef MAIN_H
#define MAIN_H

#include "kernel.h"

/**
   Creates kernel instance, and than halts the computer.
   Just a stub function to call from assembler, doesn't 
   actually do anything.

   It calls test temporarily, function shouldn't do anything, 
   for now it is used for testing purpose.

   Should never ever return, since we jump to it from assembler,
   we do not call it.

   @return No return.
 */
extern "C" {
  void kmain();
}

extern unsigned long start_ctors;
extern unsigned long end_ctors;
extern unsigned long start_dtors;
extern unsigned long end_dtors;

/**
   Some kind of guardian, just dumb functions,
   but gcc needs them for local static vars.
 */
namespace __cxxabiv1 
{
	/* guard variables */
 
	/* The ABI requires a 64-bit type.  */
	__extension__ typedef int __guard __attribute__((mode(__DI__)));
 
	extern "C" int __cxa_guard_acquire (__guard *);
	extern "C" void __cxa_guard_release (__guard *);
	extern "C" void __cxa_guard_abort (__guard *);
}

#endif // MAIN_H
