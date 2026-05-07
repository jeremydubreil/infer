// Coverage for a fictional `RETAIN_CYCLE` that Pulse fires on a Swift
// `for x in [Struct]` loop where each loop body switches on a
// payload-bearing enum field of the loop variable and runs an external
// value-type initializer (e.g. `Date()`) in a non-zero-tagged arm.
//
// Production qualifier (paraphrased):
//   "Retain cycle found between event->field_3 and event->field_3->field_1"
//
// Repro ingredients (all required to trigger):
//   1. `for x in arrayOfStruct` — `IndexingIterator.next()` is
//      summary-less stdlib, so Pulse uses the unknown-call fallback.
//   2. The struct's stored properties include an enum with at least
//      one payload-bearing case (e.g. `UNRECOGNIZED(Int)`), so the
//      enum is laid out as tag + payload at the LLVM level.
//   3. The body switches on that enum field.
//   4. The matched arm is for a **non-first** case (the bug doesn't
//      fire when the matched arm is for the case at tag 0).
//   5. That arm calls an opaque value-type initializer (e.g. `Date()`,
//      `UUID()`) — another summary-less constructor.
//
// All operations are pure value semantics; no reference type is ever
// allocated, so Pulse should not report a retain cycle. The Llair
// frontend currently emits a raw scalar store followed by a struct-
// pointer load against the same address (`event->field_3`), which
// Pulse interprets as a self-referential write.

import Foundation

private enum E {
    case unknown
    case chargingStart
    case chargingEnd
    case thermalCritical
    case thermalShutdown
    case batteryShutdown
    case genericShutdown
    case boot
    case UNRECOGNIZED(Int)
}

private struct S {
    var timestamp: Int64 = 0
    var batterLevel: Int32 = 0
    var eventType: E = .unknown
    init() {}
}

@inline(never)
private func loop(events: [S]) -> Int {
    var count = 0
    for event in events {
        switch event.eventType {
        case .chargingStart:
            let _ = Date()
            count += 1
        case .unknown, .chargingEnd, .thermalCritical, .thermalShutdown, .batteryShutdown,
             .genericShutdown, .boot, .UNRECOGNIZED:
            break
        }
    }
    return count
}

public func test_payload_enum_in_iter_switch_no_cycle_good_FP() -> Int {
    loop(events: [])
}
