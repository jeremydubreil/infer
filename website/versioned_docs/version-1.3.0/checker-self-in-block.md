---
title: "Self in Block"
description: "An Objective-C-specific analysis to detect when a block captures `self`."
---

An Objective-C-specific analysis to detect when a block captures `self`.

Activate with `--self-in-block`.

Supported languages:
- C/C++/ObjC: Yes
- C#/.Net: No
- Erlang: No
- Hack: No
- Java: No
- Python: No
- Rust: No
- Swift: No



## List of Issue Types

The following issue types are reported by this checker:
- [CAPTURED_STRONG_SELF](/docs/all-issue-types#captured_strong_self)
- [CXX_REF_CAPTURED_IN_BLOCK](/docs/all-issue-types#cxx_ref_captured_in_block)
- [CXX_STRING_CAPTURED_IN_BLOCK](/docs/all-issue-types#cxx_string_captured_in_block)
- [MIXED_SELF_WEAKSELF](/docs/all-issue-types#mixed_self_weakself)
- [MULTIPLE_WEAKSELF](/docs/all-issue-types#multiple_weakself)
- [NSSTRING_INTERNAL_PTR_CAPTURED_IN_BLOCK](/docs/all-issue-types#nsstring_internal_ptr_captured_in_block)
- [SELF_IN_BLOCK_PASSED_TO_INIT](/docs/all-issue-types#self_in_block_passed_to_init)
- [STRONG_SELF_NOT_CHECKED](/docs/all-issue-types#strong_self_not_checked)
- [WEAK_SELF_IN_NO_ESCAPE_BLOCK](/docs/all-issue-types#weak_self_in_no_escape_block)
