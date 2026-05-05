import Foundation

func unannotatedReturn_bad(api: LegacyAPI) {
  let s = api.getUnannotatedString()!
  print(s.count)
}

func nonnullReturn_good(api: LegacyAPI) {
  let s = api.getNonnullString()
  print(s.count)
}

func nullableReturn_good(api: LegacyAPI) {
  if let s = api.getNullableString() {
    print(s.count)
  }
}

func macroAnnotatedNullableProp_good(api: LegacyAPI) {
  if let s = api.macroAnnotatedNullableProp {
    print(s.count)
  }
}

func macroAnnotatedUnannotatedProp_bad(api: LegacyAPI) {
  let s = api.macroAnnotatedUnannotatedProp!
  print(s.count)
}

// The .h's category interface is gated by `#ifdef __swift__`, so Swift's
// clang importer sees the method as returning `String?` (Optional) but
// infer's ObjC capture sees only the .m's bare `NSString*`. The `!` here
// force-unwraps an Optional the user knows is nullable; infer should not
// flag it. Today it does (FP), so the test is `_FP_*` until we fix the
// checker.
func swiftRefinedNullableString_good_FP(api: LegacyAPI) {
  let s = api.swiftRefinedNullableString()!
  print(s.count)
}

// Recommended developer workaround when the ObjC header cannot be
// annotated: cast the result to an Optional via `as?`. The LLAIR
// produced for an `as?` cast contains a downstream call to
// `_bridgeToObjectiveC`, which the bridge-analysis prepass uses as the
// signature of an explicit Optional cast. The Llair-to-Textual
// translator then attaches `Nullable` to the call's
// `cf_caller_ret_annots`, suppressing the would-be MISSING_NULLABILITY
// report for this defensive use of an unannotated method.
func unannotatedReturn_castAsOptional_good(api: LegacyAPI) {
  if let s = api.getUnannotatedString() as? NSString {
    print(s.length)
  }
}