/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file kernel.h
 * @author Domen Ipavec
 *
 * @brief
 * Defines main kernel class.
 */

#ifndef KERNEL_H
#define KERNEL_H

#include "types.h"
#include "serialPort.h"
#include "log.h"
#include "isr.h"
#include "dalloc.h"

/**
   Main kernel class, contains everything else.
 */
class Kernel {
 private:

/**
   Pointer to one instance of me, for use in Kernel::get_instance().
 */
  static Kernel * instance;

 public:

/**
    First serial port (aka COM1)
 */
  SerialPort com1;

/**
    Dynamic allocation class.
 */
  DynamicAllocation dalloc;

/**
   Should initalize the whole kernel.

   @return Hey it is constructor.
 */
  Kernel();

/**
   For testing purpose only.

   @return No return.
 */
  void test();

/**
   Returns an instance of kernel, for use from other classes.

   @return Kernel instance.
 */
  static Kernel * get_instance();

/**
   Write byte value to port.

   @param[in] port  Port to which you wanna write.
   @param[in] value Value to write.
   @return No return.
 */
  void outb(u16int port, u8int value);

/**
   Write word value to port.

   @param[in] port  Port to which you wanna write.
   @param[in] value Value to write.
   @return No return.
 */
  void outw(u16int port, u16int value);

/**
   Read byte from port.

   @param[in] port  Port you wanna read.
   @return Read byte value.
 */
  u8int inb(u16int port);

/**
   Read word from port.

   @param[in] port  Port you wanna read.
   @return Read word value.
 */
  u16int inw(u16int port);
};

#endif // KERNEL_H
