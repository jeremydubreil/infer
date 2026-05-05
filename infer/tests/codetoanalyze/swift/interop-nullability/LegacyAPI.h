/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

#import <Foundation/Foundation.h>

// A macro that expands to a type-attached attribute. When such a macro appears
// after a property declarator, clang wraps the property type in a
// MacroQualifiedType layer (see clang/lib/Sema/SemaType.cpp). The AST exporter
// now descends through that wrapper so the inner [_Nullable] sugar is visible
// to Infer.
#define MY_TYPE_ATTR __attribute__((annotate("my_type_attr")))

@interface LegacyAPI : NSObject
// Missing nullability - Swift imports this as String!, prone to crashes.
- (NSString*)getUnannotatedString;

// Annotated _Nonnull - Swift imports as String.
- (NSString* _Nonnull)getNonnullString;

// Annotated _Nullable - Swift imports as String?.
- (NSString* _Nullable)getNullableString;

// @property with [nullable] AND a macro-attached type attribute. The
// [nullable] qualifier survives because the AST exporter looks through the
// MacroQualifiedType wrapper.
@property(nullable, nonatomic, readonly)
    NSString* macroAnnotatedNullableProp MY_TYPE_ATTR;

// Same shape but unannotated - control case, must still be flagged.
@property(nonatomic, readonly)
    NSString* macroAnnotatedUnannotatedProp MY_TYPE_ATTR;
@end

// A category interface gated by [#ifdef __swift__]. The macro is defined
// only by Swift's clang importer, so the [@interface] is invisible during
// regular ObjC compilation. The matching [@implementation] in the .m
// therefore has nothing to merge nullability from, and infer captures the
// impl method as bare [id] / [T*] with no [_Nullable]. Swift, in contrast,
// sees the annotated declaration and imports the method as returning [T?],
// so a Swift force-unwrap is against an [Optional] (deliberate by the
// caller) - infer should NOT fire MISSING_NULLABILITY_ANNOTATION.
#ifdef __swift__
@interface LegacyAPI (SwiftOnlyRefined)
- (nullable NSString*)swiftRefinedNullableString;
@end
#endif

#pragma clang diagnostic pop
