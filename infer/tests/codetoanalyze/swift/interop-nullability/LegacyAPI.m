/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
#import "LegacyAPI.h"

@implementation LegacyAPI
- (NSString*)getUnannotatedString {
  return @"unannotated";
}
- (NSString* _Nonnull)getNonnullString {
  return @"nonnull";
}
- (NSString* _Nullable)getNullableString {
  return nil;
}
// Use @dynamic so clang does not auto-synthesize an explicit getter on the
// implementation side; only the property declaration's synthesized accessor
// remains. This mirrors how UIKit/Foundation properties reach Infer
// (header-only via PCM, no implementation captured) so the
// MacroQualifiedType-hides-nullability bug actually surfaces.
@dynamic macroAnnotatedNullableProp;
@dynamic macroAnnotatedUnannotatedProp;
@end

// The category [@implementation] is NOT inside an [#ifdef __swift__] block,
// so it exists at runtime. But the matching [@interface] in the .h IS
// gated, so during regular ObjC compilation clang has no [nullable] to
// merge into the impl method's result type. Result: the impl method is
// stored as bare [NSString*] with no annotation.
@implementation LegacyAPI (SwiftOnlyRefined)
- (NSString*)swiftRefinedNullableString {
  return nil;
}
@end
