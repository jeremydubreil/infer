// Coverage for a false-positive RETAIN_CYCLE that fires on a pure-value
// computed property that switches on its enclosing enum to extract a payload.
//
// `ScanNumberType` is a Swift enum with payload that fits in registers, so the
// Swift compiler direct-passes it as `(payload: i64, tag: i8)` at the LLVM
// level instead of by reference. The Llair body reconstructs the enum on the
// stack and switches on the tag — entirely value-semantics, no heap writes,
// no reference types involved. After the multi-entry-switch translation
// landed, Pulse can now reach the body and ends up reporting a fictional
// retain cycle on `self -> self->field_1` (the stack-reconstructed enum
// header). The model gap is that `Llair2Textual.to_formal_types` keeps the
// demangled-signature pointer type for an LLVM-level scalar parameter, so the
// stack-reconstruction stores look like writes into a heap object.
//
// `_good_FP` is renamed to `_good` and the `issues.exp` line is dropped once
// the frontend stops promoting register-passed scalar parameters to the
// signature pointer type.

private enum ScanNumberType {
    case ignore
    case valid(number: Int)
    case invalid

    // Triggers the FP when called on any case.
    var scanNumber_FP: Int? {
        switch self {
        case .ignore:
            return nil
        case .valid(let number):
            return number
        case .invalid:
            return nil
        }
    }
}

public func test_enum_switch_getter_no_cycle_good_FP() -> Int? {
    let t = ScanNumberType.valid(number: 5)
    return t.scanNumber_FP
}
