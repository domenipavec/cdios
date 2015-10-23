/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file isr.h
 * @author Domen Ipavec
 *
 * @brief
 * Provides extern c handler function for interrupts
 * and extern assembler function to initialize idt.
 */

#ifndef ISR_H
#define ISR_H

#include "types.h"

/** 
    Contains registers as pushed by interrupt routine.

    @todo Put structs Registers and ProcessEssentials in 
    seperate header for reuse.
 */
struct Registers {
  u64int r15, r14, r13, r12, r11, r10, r9, r8;
  u64int rbp, rsi, rdi;
  u64int rdx, rcx, rbx, rax;
} __attribute__((packed));

/**
   Contains interrupt number and error code as pushed by
   interrupt routine.
 */
struct Interrupt {
  u64int inNum, inErrCode;
} __attribute__((packed));

/**
   Contains intrupction pointer, code segment, flags,
   stack pointer, stack selector as auto pushed by processor
   when interrupt happens.
 */
struct ProcessEssentials {
  u64int ip, cs, flags, sp, ss;
} __attribute__((packed));

/**
   Contains Registers, Interrupt and ProcessEssentials packed together,
   to use in c_isr_handler parameters. If I put them for parameters
   separately, gcc makes some weird padding between them.
 */
struct InterruptParams {
  Registers reg;
  Interrupt in;
  ProcessEssentials pe;
} __attribute__((packed));

extern "C" {
/**
   Main function called when interrupt happens. Called from
   assebmler so must be extern "C".

   @param[in] params Pushed registers, interrupt number, error code, and processor pushed stuff.
   @return No return.
 */
  void c_isr_handler(InterruptParams params);
}

#endif
