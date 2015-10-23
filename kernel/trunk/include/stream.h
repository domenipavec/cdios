/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file stream.h
 * @author Domen Ipavec
 *
 * @brief
 * Defines Stream abstract class.
 */

#include "types.h"

/**
   Stream class for all char streams like serial port, ...
   Provides write for different types (ints, string).

   @todo Add more types that can be printed.
 */
class Stream {
 protected:
/**
   Virtual function puts a character, implemented in each
   child class seperately, doen't do anything here, otherwise
   prints char to whatever output.

   @param[in] c Char that will be printed.
   @return No return.
 */
  virtual void put(char c);

 public:
/**
   Prints const char * by put-ing each char.

   @param[in] s String to be printed.
   @return No return.
 */
  void write(const char * s);

/**
   Just a stub funtion to put, which is protected.

   @see put Just calls this.

   @param[in] c Char to put.
   @return No return.
 */
  void write(char c);

/**
   Writes unsigned integer, contains the real number parser.
   
   @todo Rewrite the function without recursion, cause we have
   very limited stack here.
   
   @param[in] i Number to write.
   @param[in] r Numeral system to use (support from 2 to 35).
   @return No return.
 */
  void write(u64int i, u8int r = 10);
};
