// Coverage for a previously-fictional retain cycle on a pure-value
// computed property that switches on its enclosing enum to extract a payload.
//
// `ScanNumberType` is a Swift enum with payload that fits in registers, so the
// Swift compiler direct-passes it as `(payload: i64, tag: i8)` at the LLVM
// level instead of by reference. The Llair body reconstructs the enum on the
// stack and switches on the tag — entirely value semantics, no heap writes,
// no reference types involved.
//
// Two frontend bugs originally fired here, both fixed:
// - `Llair2TextualState.subst_formal_local` aliased the stack-reconstruction
//   local with the LLVM-scalar formal, making the body's reconstruction
//   stores look like writes into a heap object → fake `RETAIN_CYCLE` and
//   `NULLPTR_DEREFERENCE_LATENT`.
// - The `Store` handler in `Llair2Textual` only redirected `store &t <- v`
//   into `store &t.field_0 <- v` for Swift structs (`V` mangled suffix), not
//   for enums (`O` suffix). On a pointer-typed local enum, the raw store
//   looked like assigning the literal to the pointer itself → fake
//   `CONSTANT_ADDRESS_DEREFERENCE`.

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

public func test_enum_switch_getter_no_cycle_good() -> Int? {
    let t = ScanNumberType.valid(number: 5)
    return t.scanNumber
}
