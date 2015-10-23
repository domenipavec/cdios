/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */

#include "serialPort.h"
#include "kernel.h"

SerialPort::SerialPort(u16int basePort):PORT(basePort), port1(0), port3(3) {
  Kernel::get_instance()->outb((u16int)(PORT + 4), 0x0B);    // IRQs enabled, RTS/DSR set
  Kernel::get_instance()->outb((u16int)(PORT + 2), 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
  this->writePort1();
  this->writePort3();
  this->setBaudDivisor(0);
}

inline void SerialPort::enableDLAB(bool enable) {
  if (enable) {
    port3 |= SERIAL_DLAB; // enable SERIAL_DLAB bit in port 3
  } else {
    port3 &= (u8int)~SERIAL_DLAB; // disable SERIAL_DLAB bit in port 3
  }
  writePort3(); // write port 3
}

inline void SerialPort::writePort1() {
  Kernel::get_instance()->outb((u16int)(PORT + 1), port1);
}

inline void SerialPort::writePort3() {
  Kernel::get_instance()->outb((u16int)(PORT + 3), port3);
}

void SerialPort::setBaudDivisor(u16int divisor) {
  enableDLAB(true);
  Kernel::get_instance()->outb((u16int)(PORT + 0), (u8int)(divisor & 0xFF));        // Set divisor (lo byte)
  Kernel::get_instance()->outb((u16int)(PORT + 1), (u8int)((divisor >> 8) & 0xFF)); //             (hi byte)
  enableDLAB(false);
}

void SerialPort::put(char c) {
  // Wait for port to be ready for data
  while ((Kernel::get_instance()->inb((u16int)(PORT + 5)) & 0x20) == 0);
  Kernel::get_instance()->outb(PORT,c); // Write char
}
