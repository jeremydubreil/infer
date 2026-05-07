---
title: "Swift/Obj-C Nullability"
description: "Detects missing nullability annotations in Objective-C methods called from Swift, which can lead to runtime crashes via Implicitly Unwrapped Optionals."
---

Detects missing nullability annotations in Objective-C methods called from Swift, which can lead to runtime crashes via Implicitly Unwrapped Optionals.

Activate with `--swift-objc-nullability`.

Supported languages:
- C/C++/ObjC: Yes
- C#/.Net: No
- Erlang: No
- Hack: No
- Java: No
- Python: No
- Rust: No
- Swift: Yes

# Swift/Obj-C Nullability

Reports calls from Swift code to Objective-C methods whose declaration
has no `_Nullable` or `_Nonnull` annotation on a pointer return type.
The Swift clang importer treats such results as Implicitly Unwrapped
Optionals (`T!`), so any subsequent use that assumes the result is
non-nil traps at runtime if the method ever returns `nil`. The checker
raises the trap-prone call sites at compile time so the team that owns
the Objective-C declaration can decide the contract explicitly.

The recommended fix lives on the
[`MISSING_NULLABILITY_ANNOTATION`](/docs/next/all-issue-types#missing_nullability_annotation)
issue page: annotate the Objective-C declaration with `_Nullable` or
`_Nonnull`, or cast the result with `as?` at the Swift call site.

## What is deliberately ignored

To keep reports actionable, the checker does not report at call sites
where the developer cannot or should not be asked to act:

- Callees declared in headers under an Apple SDK or under a prebuilt
  framework's public-header directory: the consumer cannot edit those
  declarations.
- Calls whose return value is null-checked by the Swift caller
  before use, e.g. `if let s = api.foo() { ... }`.
- Calls whose return value is explicitly cast through an `as?`
  Optional cast, e.g. `if let s = api.foo() as? NSString { ... }`.

A bare force-unwrap (`api.foo()!`) is intentionally NOT treated as a
fix — it makes the trap explicit but does not eliminate it.


## List of Issue Types

The following issue types are reported by this checker:
- [MISSING_NULLABILITY_ANNOTATION](/docs/next/all-issue-types#missing_nullability_annotation)
