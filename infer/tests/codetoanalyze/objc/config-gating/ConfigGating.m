/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@interface ConfigGating : NSObject

+ (BOOL)getConfigFlag:(NSString*)name;

@end

@implementation ConfigGating

// Stub: recognized as a config read by the checker
+ (BOOL)getConfigFlag:(NSString*)name {
  return NO;
}

void doSomething(void) {}

void doSomethingElse(void) {}

// Simple gated call: doSomething is gated by feature_x=true
- (void)simple_gated_call_bad {
  if ([ConfigGating getConfigFlag:@"feature_x"]) {
    doSomething();
  }
}

// Not gated: doSomething is called unconditionally
- (void)not_gated_ok {
  doSomething();
}

// Both branches gated by the same config (different polarities)
- (void)both_branches_gated_bad {
  if ([ConfigGating getConfigFlag:@"feature_y"]) {
    doSomething();
  } else {
    doSomethingElse();
  }
}

// After the join point, the guard is removed
- (void)join_removes_guard_ok {
  if ([ConfigGating getConfigFlag:@"feature_z"]) {
    doSomething();
  } else {
    doSomethingElse();
  }
  // After the join, code is NOT gated (both branches merged)
  doSomething();
}

// Config stored in a variable before being checked
- (void)config_in_variable_bad {
  BOOL flag = [ConfigGating getConfigFlag:@"stored_config"];
  if (flag) {
    doSomething();
  }
}

@end
