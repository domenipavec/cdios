/*
 * System: CDIOS
 * Component Name: CDIOS, kernel 
 * Language: C++
 *
 * copyright (c) 2010 by Domen Ipavec
 * All right reserved.
 */

#include "dalloc.h"
#include "log.h"

DynamicAllocation::DynamicAllocation(DA_free_header_p start, u64int size) :
  firstFree(start), 
  lastPossibleHeaderLocation((u64int)start + 
			     size - 
			     sizeof(DAFreeEntryHeader)) 
{
  firstFree->stat = DA_FREE;
  firstFree->size = size - sizeof(DAEntryHeader);
  firstFree->prev = NULL;
  firstFree->next = NULL;
}

void* DynamicAllocation::allocate(u64int size) {
  // log number of bytes we allocate
  LOG(size);

  if (size < 8) // Minimum size, cause otherwise there is not enought place for free buffer header
    size = 8;

  // definitions
  DA_free_header_p c(firstFree);
  DA_free_header_p p(NULL);

  while (true) {
    if (c == NULL) { // We have to implement increase of buffer
      LOG("Need to increase dalloc size.");
      return NULL;
      //p = increase_size();
    }
    if (c->size >= size) { // We found buffer with enough size, break
      break;
    }
    p = c; // Move to next buffer
    c = c->next;
  }

  if (p == NULL) { // First entry
    firstFree = c->next; // Replace first entry with next
  } else { // Next in previous entry to next of current, so we remove
    p->next = c->next; // this from free list, it will be used
  }

  c->stat = DA_USED; // Set status to used.

  if (c->size >= (size + sizeof(DAFreeEntryHeader))) {
    DA_free_header_p n((DA_free_header_p)((u64int)c + sizeof(DAEntryHeader) + c->size)); // Next entry in memory

    p = (DA_free_header_p)((u64int)c + sizeof(DAEntryHeader) + size); // New entry
    p->prev = c; // Set previous to current
    p->stat = DA_FREE; // New entry is free
    p->size = c->size - size - sizeof(DAEntryHeader); // size of new entry

    if ((u64int)n <= lastPossibleHeaderLocation) { // If next exists
      n->prev = p; // Set next's previous to new entry
    }

    c->size = size; // current will now be resized

    if (firstFree == NULL) { // If we don't have any free
      p->next = NULL; // Add new entry as free
      firstFree = p;
    } else { // Else find first bigger 
      for (n = firstFree;
	   n->next != NULL && n->next->size >= p->size;
	   n = n->next);
      p->next = n->next; // And add new entry
      n->next = p;
    }
  }

  return (void*) ((u64int)c + sizeof(DAEntryHeader)); // return pointer to start of buffer
}

void DynamicAllocation::free(void* address) {
  LOG((u64int)address);

  if (address == NULL) { // Probably freeing unsuccessful allocation
    LOG("Invalid free!");
    return;
  }

  DA_free_header_p c((DA_free_header_p)((u64int)address - sizeof(DAEntryHeader)));
  DA_free_header_p l((DA_free_header_p)c->prev);
  DA_free_header_p r((DA_free_header_p)((u64int)address + c->size));
  DA_free_header_p del_r(NULL);
  DA_free_header_p p(NULL);

  if (c->stat != DA_USED) { // If not used buffer
    LOG("Invalid free!");
    return;
  }
  
  // join left
  if (l != NULL && l->stat == DA_FREE) {
    // increase size of left buffer
    l->size = l->size + sizeof(DAEntryHeader) + c->size;
    c = l; // current is left
  } else {
    // We will remove left, but because we didn't join left, we have to set to null, so we remove nothing
    l = NULL;
    // If we joined left, stat is already free, otherwise set it
    c->stat = DA_FREE; 
  }
  
  // If there is buffer to right
  if ((u64int)r <= lastPossibleHeaderLocation) {
    // join right
    if (r->stat == DA_FREE) {
      // Increase current object size to include both
      c->size = c->size + sizeof(DAEntryHeader) + r->size;
      // set right for deleting
      del_r = r;
      // r to next entry
      r = (DA_free_header_p)((u64int)r + sizeof(DAEntryHeader) + r->size);
    }
    
    // next entry's prev to current
    r->prev = c;
  }
  
  // No need for r, so we use it as pointer to current elemnt in this loop
  r = firstFree;
  while (true) {
    if (r == firstFree) {
      if (firstFree == NULL) { // If no free objects
	firstFree = c; // Add this one
	c->next = NULL;
	return;
      } else if (firstFree->size > c->size) { // If needed on first place
	c->next = firstFree;
	firstFree = c;
	return;
      }
    }

    // If current is one to be deleted
    if (r == l || r == del_r) {
      if (p == NULL) {
	firstFree = r->next;
	r = firstFree;
      } else {
	p->next = r->next;
	r = p;
      }
      continue;
    }

    // If last element
    if (r->next == NULL) {
      break; // We add element after this one
    }
    
    // If next one is bigger
    if (r->next->size > c->size) {
      break; // We add element after this one
    }

    p = r; // Previous element pointer
    r = r->next; // Set current to next
  }

  c->next = r->next; // Add element to list
  r->next = c;
}
