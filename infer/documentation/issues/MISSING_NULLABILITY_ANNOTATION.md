An Objective-C method that returns a pointer is being called from Swift,
but its declaration carries no nullability annotation (`_Nullable` or
`_Nonnull`). Without an annotation Swift's clang importer treats the result
as an Implicitly Unwrapped Optional (`T!`), so any subsequent use that
assumes non-nil values traps at runtime if the method ever returns `nil`.

### Why this matters

Objective-C uses raw pointers and signals "may be nil" only by convention.
Swift, by contrast, requires nullability to be explicit in the type system:

| Objective-C declaration             | Swift import      | Behaviour on `nil`             |
| ----------------------------------- | ----------------- | ------------------------------ |
| `- (NSString *)foo;`                | `func foo() -> String!` | implicit unwrap, **trap**      |
| `- (NSString * _Nonnull)foo;`       | `func foo() -> String`  | impossible by contract         |
| `- (NSString * _Nullable)foo;`      | `func foo() -> String?` | safe; caller must unwrap       |

The unannotated form is the dangerous one: Swift will silently let you
write `api.foo().count` even though the underlying call may return `nil`,
and the trap fires far away from the missing annotation.

### Example

```objc
// LegacyAPI.h - third-party header, no annotation
@interface LegacyAPI : NSObject
- (NSString *)getOptionalThing;
@end
```

```swift
func bad(api: LegacyAPI) {
  let s = api.getOptionalThing()  // imported as String!
  print(s.count)                  // crashes if getOptionalThing returns nil
}
```

Infer reports `MISSING_NULLABILITY_ANNOTATION` on the call to
`getOptionalThing`.

### Preferred fix: annotate the Objective-C header

Edit the declaration to state the contract explicitly. If the method may
return `nil`, mark it `_Nullable`; otherwise mark it `_Nonnull`:

```objc
// LegacyAPI.h
@interface LegacyAPI : NSObject
- (NSString * _Nullable)getOptionalThing;
@end
```

Now Swift imports the result as `String?` and the compiler forces the
caller to handle the nil case:

```swift
func good(api: LegacyAPI) {
  if let s = api.getOptionalThing() {
    print(s.count)
  }
}
```

For headers that already wrap whole regions in
`NS_ASSUME_NONNULL_BEGIN` / `NS_ASSUME_NONNULL_END`, only the exception
needs the explicit `_Nullable`.

### Workaround when you cannot edit the header

If the declaration lives in a third-party framework or a header you do not
own, defend at the Swift call site by casting the result to an Optional
with `as?`:

```swift
func goodWorkaround(api: LegacyAPI) {
  if let s = api.getOptionalThing() as? NSString {
    print(s.length)
  }
}
```

The `as?` cast lifts the IUO into a real `Optional`, and `if let` /
`guard let` then forces the nil case to be handled. Infer recognises this
defensive shape (an `objc_msgSend` whose result feeds a
`_bridgeToObjectiveC` call in the lowered IR) and stops reporting on the
call.

A bare force-unwrap (`api.getOptionalThing()!`) is **not** a fix: it makes
the trap explicit but does not eliminate it, and infer will continue to
report on the call.
