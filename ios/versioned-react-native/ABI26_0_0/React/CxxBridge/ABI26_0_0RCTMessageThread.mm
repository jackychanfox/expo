/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#include "ABI26_0_0RCTMessageThread.h"

#include <condition_variable>
#include <mutex>

#import <ReactABI26_0_0/ABI26_0_0RCTCxxUtils.h>
#import <ReactABI26_0_0/ABI26_0_0RCTUtils.h>
#include <ABI26_0_0jschelpers/ABI26_0_0JSCHelpers.h>

// A note about the implementation: This class is not used
// generically.  It's a thin wrapper around a run loop which
// implements a C++ interface, for use by the C++ xplat bridge code.
// This means it can make certain non-generic assumptions.  In
// particular, the sync functions are only used for bridge setup and
// teardown, and quitSynchronous is guaranteed to be called.

namespace facebook {
namespace ReactABI26_0_0 {

ABI26_0_0RCTMessageThread::ABI26_0_0RCTMessageThread(NSRunLoop *runLoop, ABI26_0_0RCTJavaScriptCompleteBlock errorBlock)
  : m_cfRunLoop([runLoop getCFRunLoop])
  , m_errorBlock(errorBlock)
  , m_shutdown(false) {
  CFRetain(m_cfRunLoop);
}

ABI26_0_0RCTMessageThread::~ABI26_0_0RCTMessageThread() {
  CFRelease(m_cfRunLoop);
}

// This is analogous to dispatch_async
void ABI26_0_0RCTMessageThread::runAsync(std::function<void()> func) {
  CFRunLoopPerformBlock(m_cfRunLoop, kCFRunLoopCommonModes, ^{ func(); });
  CFRunLoopWakeUp(m_cfRunLoop);
}

// This is analogous to dispatch_sync
void ABI26_0_0RCTMessageThread::runSync(std::function<void()> func) {
  if (m_cfRunLoop == CFRunLoopGetCurrent()) {
    func();
    return;
  }

  dispatch_semaphore_t sema = dispatch_semaphore_create(0);
  runAsync([func=std::make_shared<std::function<void()>>(std::move(func)), &sema] {
    (*func)();
    dispatch_semaphore_signal(sema);
  });
  dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

void ABI26_0_0RCTMessageThread::tryFunc(const std::function<void()>& func) {
  NSError *error = tryAndReturnError(func);
  if (error) {
    m_errorBlock(error);
  }
}

void ABI26_0_0RCTMessageThread::runOnQueue(std::function<void()>&& func) {
  if (m_shutdown) {
    return;
  }

  runAsync([this, func=std::make_shared<std::function<void()>>(std::move(func))] {
    if (!m_shutdown) {
      tryFunc(*func);
    }
  });
}

void ABI26_0_0RCTMessageThread::runOnQueueSync(std::function<void()>&& func) {
  if (m_shutdown) {
    return;
  }
  runSync([this, func=std::move(func)] {
    if (!m_shutdown) {
      tryFunc(func);
    }
  });
}

void ABI26_0_0RCTMessageThread::quitSynchronous() {
  m_shutdown = true;
  runSync([]{});
  CFRunLoopStop(m_cfRunLoop);
}

void ABI26_0_0RCTMessageThread::setRunLoop(NSRunLoop *runLoop) {
  CFRelease(m_cfRunLoop);
  m_cfRunLoop = [runLoop getCFRunLoop];
  CFRetain(m_cfRunLoop);
}

}
}
