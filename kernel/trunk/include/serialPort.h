/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file serialPort.h
 * @author Domen Ipavec
 *
 * @brief
 * Defines SerialPort class.
 */

#ifndef SERIAL_PORT_H
#define SERIAL_PORT_H

#include "types.h"
#include "stream.h"

#define SERIAL_DLAB 128

/**
   Class for operating with serial ports.

   @todo Functions setDataLength, setLongStopBit, setParity and 
   setInterrupts, to change default settings.
   @todo Reading ability, it only writes for now, since I only use it
   for bochs logging.
 */
class SerialPort: public Stream {
 private:

/**
   Store the base port for current serial port.
 */
  u16int const PORT;

/**
   Store the current value of PORT + 1 of this serial port.
 */
  u8int port1;

/**
   Store the current value of PORT + 3 of this serial port.
 */
  u8int port3;

/**
   Enables or diables DLAB bit of PORT + 3.

   @param[in] enable Whether to enable or disable DLAB bit 
   (when true bit will be set to 1).
   @return No return.
 */
  inline void enableDLAB(bool enable);

/**
   Write the value of PORT + 1 from variable
   to the real port.

   @return No return.
 */
  inline void writePort1();

/**
   Write the value of PORT + 3 from variable
   to the real port.

   @return No return.
 */
  inline void writePort3();

 protected:
/**
   Write char to serial port.

   @param[in] c Character to be written.
   @return No return.
 */
  void put(char c);

 public:
/**
   Initializes serial port with default values, that is:
     - 8 bits data
     - no parity
     - one stop bit
     - all interrupts disabled
     - divisor 0

   It enables FIFO, clear them, with 14-byte threshold, 
   IRQs enabled, RTS/DSR set.

   @param[in] basePort The base port to use for serial port.
   @return Hey it is constructor.
 */
  SerialPort(u16int basePort);


/**
   Set baud divisor of current serial port, to specified value.

   @param[in] divisor The divisor to be set.
   @return No return.
 */
  void setBaudDivisor(u16int divisor);

  void setDataLength(u8int dataLength);

  void setLongStopBit(bool longStopBit);

  void setParity(u8int parity);

  void setInterrupts(u8int ints);
};

#endif // SERIAL_PORT_H
