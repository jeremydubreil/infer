// Coverage for a previously-fictional retain cycle on a pure-value
// computed property that switches on its enclosing enum to extract a payload.
//
// `ScanNumberType` is a Swift enum with payload that fits in registers, so the
// Swift compiler direct-passes it as `(payload: i64, tag: i8)` at the LLVM
// level instead of by reference. The Llair body reconstructs the enum on the
// stack and switches on the tag — entirely value semantics, no heap writes,
// no reference types involved.
//
// Until `Llair2TextualState.subst_formal_local` learned to skip aliasing the
// stack-reconstruction local with the LLVM-scalar formal, the textual body
// looked like writes into `self.field_X` and Pulse fired a fake `RETAIN_CYCLE`
// (plus a `NULLPTR_DEREFERENCE_LATENT`) on this getter. A separate
// `CONSTANT_ADDRESS_DEREFERENCE` on the constructor call remains as a known
// FP — a follow-up clean-up — but the retain-cycle pattern this file was
// added for is fixed.

private enum ScanNumberType {
    case ignore
    case valid(number: Int)
    case invalid

    var scanNumber: Int? {
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
    return t.scanNumber
}
