// Coverage for a false-positive `RETAIN_CYCLE` (and a paired
// `NULLPTR_DEREFERENCE`) that fires on a property write whose mangled symbol
// uses Swift's substitution compression for the field name.
//
// Swift's mangler compresses substrings that repeat across enclosing names.
// For a property `reactionBubbleView` declared on class `OuterBubble`, the
// shared "Bubble" substring lets the mangler back-reference earlier text:
// the property name encodes as roughly `08reactionC4View...` (literal "8
// reaction" followed by a substitution for "Bubble" and a literal "4View").
//
// `Llair2TextualField.extract_field_name_from_getter` derives the field name
// for the field-offset map by chopping `.get` off the getter's plain name.
// When that plain name has been demangled WITHOUT expanding substitutions,
// the chopped result is just the leading literal chunk (`reaction`), and
// every property on the same class whose mangled name starts with the same
// literal collapses onto the same key in the offset map. Pulse then sees
// what looks like writes back into a self-referential field and reports
// fictional retain cycles.
//
// Symptom matches three of the un-categorised RETAIN_CYCLE reports on the
// most recent fbobjc capture: `OuterBubble.reactionBubbleView`,
// `MAIConsentNuxBaseToast.retainedSelf`, and `BCNSpoolStreamAdapter`'s
// `nextContentState` chain. The repro below mirrors the first.

import Foundation
import UIKit

final class InnerBubble: UIView {
    var caretAngleOverride: CGFloat?
}

final class OuterBubble: UIView {
    private var reactionBubbleView: InnerBubble?

    var reactionBubbleCaretAngle: CGFloat? {
        didSet {
            reactionBubbleView?.caretAngleOverride = reactionBubbleCaretAngle
        }
    }

    func setup() {
        reactionBubbleView = InnerBubble()
    }
}

@MainActor
public func test_compressed_field_name_no_cycle_good_FP() {
    let o = OuterBubble()
    o.setup()
    o.reactionBubbleCaretAngle = .pi / 4
}
