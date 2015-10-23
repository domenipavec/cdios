/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file log.h
 * @author Domen Ipavec
 *
 * @brief
 * Provides logging interface through serial port.
 */

#ifndef LOG_H
#define LOG_H

#define ENABLE_LOGGING

#ifndef ENABLE_LOGGING

#define LOG(x)
#define BochsBreak()

#else // ENABLED_LOGGING

#include "kernel.h"

/**
   Logs everything to serial port with nice file, line, and function list.
   
   @param[in] x Thing to log, everything supported by Stream.
   
   @todo Remove u64int by adding more types to Stream.
   @todo Implement << operator in stream.
 */
#define LOG(x) Kernel::get_instance()->com1.write(__FILE__); \
  Kernel::get_instance()->com1.write('['); \
  Kernel::get_instance()->com1.write((u64int)__LINE__);	\
  Kernel::get_instance()->com1.write("](");	\
  Kernel::get_instance()->com1.write(__FUNCTION__); \
  Kernel::get_instance()->com1.write("): ");	\
  Kernel::get_instance()->com1.write(x);	\
  Kernel::get_instance()->com1.write('\n')

#define BOCHS_BREAK() __asm__("xchg %%bx, %%bx" : :"b"(NULL));

#endif // ENABLED_LOGGING

#endif // LOG_H
