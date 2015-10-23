/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */
/**
 * @file dalloc.h
 * @author Domen Ipavec
 *
 * @brief
 * System dynamic allocation implementation.
 */

#ifndef DALLOC_H
#define DALLOC_H

#include "types.h"

/**
   Used in all routines to set stat in DAEntryHeader to used.
 */
#define DA_USED 'U'

/**
   Used in all routines to set stat in DAEntryHeader to free.
 */
#define DA_FREE 'F'


// Predefinition for use in typedef
struct DAEntryHeader;

// Predefinition for use in typedef
struct DAFreeEntryHeader;

/**
   Pointer to DAEntryHeader, cause we use it often.
 */
typedef DAEntryHeader* DA_header_p;

/**
   Pointer to DAFreeEntryHeader, cause we use it often.
 */
typedef DAFreeEntryHeader* DA_free_header_p;

/**
   End of executable, defined in linker script.
 */
extern DAFreeEntryHeader rw_end;

/**
   Header of list used for dynamic allocation, for used objects.
 */
struct DAEntryHeader {

/**
   Specifies weather it is used or free
   ('U' || 'F').
 */
  char stat;

/**
   Size of object, excluding size of header. Can get next using
   this + sizeof(DAEntryHeader) + size.
 */
  u64int size;

/**
   Pointer to previous object in memory.
 */
  DA_header_p prev;
} __attribute__((packed));

/**
   Header of list used for dynamic allocation, extended for free objects,
   to keep them in ordered list.
 */
struct DAFreeEntryHeader : public DAEntryHeader {

/**
   We sort free entries in ordered list, so we need pointer to next object.
 */
  DA_free_header_p next;
} __attribute__((packed));

/**
   All functions dealing with allocation, pointer to first free region.

   @todo Support for enlargement of buffer.
 */
class DynamicAllocation {
 private:

  /**
     Pointer to first free object.
   */
  DA_free_header_p firstFree;

  /**
     Last possible header location for comparison when merging right,
     so we know that there is no header when deallocating right most
     object.
   */
  u64int lastPossibleHeaderLocation;

 public:
  /**
     Constructor with starting address of data space and size of data space.
   */
  DynamicAllocation(DA_free_header_p start, u64int size);
  
  /**
     Get pointer to memory size large.
   */
  void* allocate(u64int size);

  /**
     Free memory at address.
   */
  void free(void* address);
};

#endif // DALLOC_H
