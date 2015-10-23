/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */

#include "kernel.h"

Kernel * Kernel::instance;

/**
   @todo Create all members after memory manager with new.
   @todo Initialize dalloc with page-aligned end.
 */
Kernel::Kernel():com1(0x3f8),dalloc(&rw_end, 0x1000) {
  instance = this; // instance is used from get_instance, 
                   // so it has to be set as soon as posible
  LOG("Start kernel constructor.");

  //__asm__("sti");

  LOG("End kernel constructor.");
}

void Kernel::test() { // tests only
  LOG("Start test function.");

  LOG("End test function.");
}

Kernel * Kernel::get_instance() {
  return instance;
}

void Kernel::outb(u16int port, u8int value) {
  __asm__("outb %1, %0" : : "dN" (port), "a" (value));
}

void Kernel::outw(u16int port, u16int value) {
  __asm__("outw %1, %0" : : "dN" (port), "a" (value));
}

u8int Kernel::inb(u16int port) {
  u8int ret;
  __asm__("inb %1, %0" : "=a" (ret) : "dN" (port));
  return ret;
}

u16int Kernel::inw(u16int port) {
  u16int ret;
  __asm__("inw %1, %0" : "=a" (ret) : "dN" (port));
  return ret;
 
}
