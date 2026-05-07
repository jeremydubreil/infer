// Regression test: lazy var inner closure assigns `delegate = self` on a
// receiver whose concrete type is statically known, so the Swift compiler
// emits the assignment as an inline existential-container store
// (getelementptr + store on the existential's value/witness slots) rather
// than dispatching through the witness-table `delegate.set` method.
// The Sledge frontend currently bails to [Llair.Exp.nondet] for the
// resulting static-byte-offset GEP on an opaque pointer, so Pulse misses
// the retain cycle. Marked `_bad_FN` to record the false negative; flipped
// to `_bad` once detection lands.

protocol BarDelegate: AnyObject {
    func didTap()
}

class BarView {
    var delegate: BarDelegate?
    init() {}
}

class BarViewController {

    private lazy var barView: BarView = {
        let barView = BarView()
        barView.delegate = self
        return barView
    }()

    func loadView() {
        _ = barView
    }
}

extension BarViewController: BarDelegate {
    func didTap() {}
}

func test_lazy_concrete_delegate_bad_FN() {
    let vc = BarViewController()
    vc.loadView()
}
