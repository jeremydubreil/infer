// Lazy var inner closure assigns `delegate = self` on a receiver whose
// concrete type is statically known. Pulse must follow the call result of
// the lazy-getter through ARC's post-call `retainAutoreleasedReturnValue`
// handshake to reach the `delegate.set` and detect the retain cycle.
//
// The companion case lives in rc_delegate.swift: there the receiver is
// protocol-typed (`var contentView: ContentViewType`), the compiler must
// dispatch through the witness method, and the cycle is detected via that
// path.

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

func test_lazy_concrete_delegate_bad() {
    let vc = BarViewController()
    vc.loadView()
}
