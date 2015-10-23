/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */

#include "isr.h"
#include "log.h"

void c_isr_handler(InterruptParams params) {
  LOG("Interrupt happend");
  LOG(params.in.inNum);
  LOG(params.in.inErrCode);
}
