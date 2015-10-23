/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */

#include "stream.h"

void Stream::put(char) {}

void Stream::write(const char * s) {
  while (*s != '\0') { // Loop through C styled (0 ended) string
    put(*s); // put each char
    s++;
  }
}

void Stream::write(char c) {
  put(c); // write char
}

void Stream::write(u64int i, u8int r) {
  if (r < 2 || r > 35) // If invalid r, default to 10
    r = 10;
  if (i/r >= 1) // If number bigger than one place
    write(i/r, r); // Write previous place
  put("0123456789ABCDEFGHIJKLMNOPRSTUVWXYZ"[i%r]); // Write current place
}
