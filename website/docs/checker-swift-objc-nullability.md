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



## List of Issue Types

The following issue types are reported by this checker:
- [MISSING_NULLABILITY_ANNOTATION](/docs/next/all-issue-types#missing_nullability_annotation)
