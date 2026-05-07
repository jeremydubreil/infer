/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@interface Config : NSObject

- (BOOL)isEnabled:(int)code;
- (int)getValue:(int)code;

@end

@implementation Config

- (BOOL)isEnabled:(int)code {
  return NO;
}

- (int)getValue:(int)code {
  return 0;
}

@end

@interface ConfigMethodExample : NSObject {
  Config* config;
}

@end

@implementation ConfigMethodExample

void cmDoSomething(void) {}

void cmDoSomethingElse(void) {}

- (instancetype)init {
  self = [super init];
  if (self) {
    config = [[Config alloc] init];
  }
  return self;
}

// Direct if-check on isEnabled
- (void)direct_check {
  if ([config isEnabled:42]) {
    cmDoSomething();
  }
}

// Store result in variable, then check
- (void)stored_check {
  BOOL enabled = [config isEnabled:99];
  if (enabled) {
    cmDoSomething();
  }
}

// Negated check
- (void)negated_check {
  if (![config isEnabled:42]) {
    cmDoSomething();
  }
}

// Not gated
- (void)not_gated {
  cmDoSomething();
}

@end
