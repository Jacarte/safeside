/*
 * Copyright 2019 Google LLC
 *
 * Licensed under both the 3-Clause BSD License and the GPLv2, found in the
 * LICENSE and LICENSE.GPL-2.0 files, respectively, in the root directory.
 *
 * SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0
 */
#include "compiler_specifics.h"

#include "utils.h"

#include <cstddef>
#include <iostream>
#if SAFESIDE_LINUX
#include <sched.h>
#include <sys/types.h>
#include <unistd.h>
#endif

#include "hardware_constants.h"
#include "instr.h"

namespace {

// Returns the address of the first byte of the cache line *after* the one on
// which `addr` falls.
const void* StartOfNextCacheLine_GuestAddr(const void* addr) {
  auto addr_n = reinterpret_cast<uintptr_t>(addr);

  // Create an address on the next cache line, then mask it to round it down to
  // cache line alignment.
  auto next_n = (addr_n + kCacheLineBytes) & ~(kCacheLineBytes - 1);
  return reinterpret_cast<const void*>(next_n);
}

// Returns the address of the first byte of the cache line *after* the one on
// which `addr` falls.
uint64_t StartOfNextCacheLine_HostAddr(uint64_t addr) {
  auto addr_n = addr;

  // Create an address on the next cache line, then mask it to round it down to
  // cache line alignment.
  const uint64_t kCacheLineBytes_n = kCacheLineBytes;
  auto next_n = (addr_n + kCacheLineBytes_n) & ~(kCacheLineBytes_n - 1);
  return reinterpret_cast<uint64_t>(next_n);
}

}  // namespace

void FlushFromDataCache_GuestAddr(const void *begin, const void *end) {
  for (; begin < end; begin = StartOfNextCacheLine_GuestAddr(begin)) {
    FlushDataCacheLineNoBarrier_GuestAddr(begin);
  }
  MemoryAndSpeculationBarrier();
}

void FlushFromDataCache_HostAddr(uint64_t begin, uint64_t end) {
  for (; begin < end; begin = StartOfNextCacheLine_HostAddr(begin)) {
    FlushDataCacheLineNoBarrier_HostAddr(begin);
  }
  MemoryAndSpeculationBarrier();
}

// This implementation delays the retirement of later instructions by making
// them wait for an uncached read. We arrange the read so it is unlikely to
// interfere with the cache state of other data.
void ExtendSpeculationWindow() {
  // Choose an address with at least kPageBytes padding before and after. That
  // ensures our memory access will be on its own page and reduces the chance
  // it will interfere with caching or prefetching of other data.
  //
  // A more clever implementation might use 2*kPageBytes + kCacheLineBytes.
  static char buffer[3 * kPageBytes] = {0};
  const char* read_offset = &buffer[kPageBytes];

  FlushFromDataCache_GuestAddr(read_offset, read_offset + 1);
  ForceRead(read_offset);
}

#if SAFESIDE_LINUX
void PinToTheFirstCore() {
  cpu_set_t set;
  CPU_ZERO(&set);
  CPU_SET(0, &set);
  int res = sched_setaffinity(getpid(), sizeof(set), &set);
  if (res != 0) {
    std::cout << "CPU affinity setup failed." << std::endl;
    exit(EXIT_FAILURE);
  }
}
#endif
