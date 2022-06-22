/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/NSObject.h>

@interface InferTaint : NSObject

+ (NSObject*)source;
+ (void)taintsArg:(NSObject*)param;
+ (void)sink:(NSObject*)param;
+ (NSObject*)sanitizer:(NSObject*)param;
+ (void)sanitizeThenSink:(NSObject*)param;
+ (void)twoSinks:(NSObject*)param;
+ (void)twoKindSink:(NSObject*)param;
+ (void)notASink:(NSObject*)param;
+ (void)call_block:(void (^)(InferTaint*))completion;
@end

@implementation InferTaint

+ (NSObject*)source {
  return [NSObject new];
};

+ (void)taintsArg:(NSObject*)param {
}

+ (void)sink:(NSObject*)param {
}

+ (NSObject*)sanitizer:(NSObject*)param {
  return param;
}

+ (void)sanitizeThenSink:(NSObject*)param {
  NSObject* sanitized = [InferTaint sanitizer:param];
  [InferTaint sink:sanitized];
}

+ (void)twoSinks:(NSObject*)param {
  [InferTaint sink:param];
  [InferTaint twoKindSink:param];
}

+ (void)twoKindSink:(NSObject*)param {
}

+ (void)notASink:(NSObject*)param {
}

@end

void callSinkDirectBad() {
  NSObject* source = [InferTaint source];
  [InferTaint sink:source];
}

void callTwoKindSinkDirectBad() {
  NSObject* source = [InferTaint source];
  [InferTaint twoKindSink:source];
}

void callTwoKindSinkOnTwiceTaintedDirectBad() {
  NSObject* source = [InferTaint source];
  [InferTaint taintsArg:source];
  [InferTaint twoKindSink:source];
}

void callTwoSinksIndirectBad() {
  NSObject* source = [InferTaint source];
  [InferTaint twoSinks:source];
}

void callSinkOnNonSourceOk() {
  NSObject* source = [NSObject new];
  [InferTaint sink:source];
}

void callNonSinkOnSourceOk() {
  NSObject* source = [InferTaint source];
  [InferTaint notASink:source];
}

void taintSourceParameterBad(InferTaint* source) { [InferTaint sink:source]; }

void taintSourceParameterBlockBad() {
  [InferTaint call_block:^(InferTaint* source) {
    [InferTaint sink:source];
  }];
}

void viaSanitizerOk() {
  NSObject* source = [InferTaint source];
  [InferTaint sanitizeThenSink:source];
}