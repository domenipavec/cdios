/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */

#include "main.h"
#include "log.h"

extern int stack_end;

void kmain() {
  //- call all the static constructors in the list.
  for(unsigned long * call = &start_ctors; call < &end_ctors; call++) {
    ((void (*)(void))*call)();
  }

  static Kernel kernel_instance; // Create kernel_instance, constructor called
  kernel_instance.test(); // run tests

  __asm__("hlt"); // hlt processor (should be in loop?)

}

namespace __cxxabiv1 // guardians, maybe one day I will actually implement them.
{                    // used for static or something.
  extern "C" int __cxa_guard_acquire (__guard *g) 
  {
    return !*(char *)(g);
  }

  extern "C" void __cxa_guard_release (__guard *g)
  {
    *(char *)g = 1;
  }

  extern "C" void __cxa_guard_abort (__guard *)
  {

  }
}
