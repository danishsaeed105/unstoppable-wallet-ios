import ThemeKit
import UIKit
import RxSwift
import RxCocoa

class KeyboardAwareViewController: ThemeViewController {
    private let scrollViews: [UIScrollView]

    private var translucentContentOffset: CGFloat = 0
    private var keyboardFrame: CGRect?

    // handling accessory view position
    var oldPadding: CGFloat = 0
    var accessoryView: UIView?
    private var pseudoAccessoryView: PseudoAccessoryView?

    public var shouldObserveKeyboard = true
    var pendingFrame: CGRect?

    open var accessoryViewHeight: CGFloat {
        floor(accessoryView?.frame.size.height ?? 0)
    }

    override open var inputAccessoryView: UIView? {
        pseudoAccessoryView
    }

    override open var canBecomeFirstResponder: Bool {
        accessoryView != nil ? shouldObserveKeyboard : super.canBecomeFirstResponder
    }

    init(scrollViews: [UIScrollView], accessoryView: UIView? = nil) {
        self.scrollViews = scrollViews
        self.accessoryView = accessoryView

        super.init()

        if accessoryView != nil {
            let pseudoAccessoryView = PseudoAccessoryView()
            pseudoAccessoryView.backgroundColor = UIColor.clear
            pseudoAccessoryView.isUserInteractionEnabled = false

            pseudoAccessoryView.delegate = self

            self.pseudoAccessoryView = pseudoAccessoryView
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func loadView() {
        super.loadView()

        view.becomeFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        pseudoAccessoryView?.heightValue = accessoryViewHeight

        for scrollView in scrollViews {
            scrollView.alwaysBounceVertical = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.keyboardDismissMode = .interactive
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        shouldObserveKeyboard = true
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let frame = pendingFrame {
            layoutAccessoryView(keyboardFrame: frame)
        }
        pendingFrame = nil

        translucentContentOffset = scrollViews[0].contentOffset.y
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)

        shouldObserveKeyboard = false
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let frame = pendingFrame {
            layoutAccessoryView(keyboardFrame: frame)
        }
        pendingFrame = nil
    }

    @objc private func keyboardWillShow(notification: Notification) {
        guard let oldKeyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
              let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              oldKeyboardFrame != keyboardFrame else {
            return
        }
        // check in visible only accessoryView. If true - keyboard is hidden
        if let inputAccessoryViewHeight = inputAccessoryView?.height, keyboardFrame.height == inputAccessoryViewHeight {
            keyboardWillHide(notification: notification)
            return
        }

        // try to disable dismiss controller by swipe when keyboard is visible
        navigationController?.presentationController?.presentedView?.gestureRecognizers?.first?.isEnabled = false
        self.keyboardFrame = keyboardFrame

        for scrollView in scrollViews {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height - view.safeAreaInsets.bottom, right: 0)
            scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        // try to enable dismiss controller by swipe when keyboard is hidden
        navigationController?.presentationController?.presentedView?.gestureRecognizers?.first?.isEnabled = true
        keyboardFrame = nil

        for scrollView in scrollViews {
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
        }
    }

    public func setInitialState(bottomPadding: CGFloat) {
        pseudoAccessoryView?.heightValue = bottomPadding
        oldPadding = -bottomPadding
    }

    public func updateUIKeyboard(initial: Bool = false) {
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()

            self.pseudoAccessoryView?.heightValue = self.accessoryViewHeight
        }
    }

    private func layoutAccessoryView(keyboardFrame: CGRect) {
        let inputHeight = pseudoAccessoryView?.heightValue ?? 0
        var bottomPadding = -inputHeight

        if !keyboardFrame.equalTo(CGRect.zero) {
            bottomPadding += view.frame.size.height - keyboardFrame.origin.y
        }

        bottomPadding = min(max(0, bottomPadding), keyboardFrame.size.height - inputHeight)

        accessoryView?.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-bottomPadding)
        }

        oldPadding = bottomPadding

        view.layoutIfNeeded()
    }

    override open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if !viewControllerToPresent.isKind(of: UISearchController.self) {
            view.endEditing(true)
        }

        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    func syncContentOffsetIfRequired(textView: UITextView) {
        guard let keyboardFrame = keyboardFrame else {
            return
        }

        var shift: CGFloat = 0

        if let cursorPosition = textView.selectedTextRange?.start {
            let caretPositionFrame: CGRect = textView.convert(textView.caretRect(for: cursorPosition), to: nil)
            let caretVisiblePosition = caretPositionFrame.origin.y - .margin2x + translucentContentOffset

            if caretVisiblePosition < 0 {
                shift = caretVisiblePosition + scrollViews[0].contentOffset.y
            } else {
                shift = max(0, caretPositionFrame.origin.y + caretPositionFrame.height + .margin2x - keyboardFrame.origin.y) + scrollViews[0].contentOffset.y
            }
        }

        scrollViews[0].setContentOffset(CGPoint(x: 0, y: shift), animated: true)
    }

}

extension KeyboardAwareViewController: PseudoAccessoryViewDelegate {

    func pseudoAccessoryView(_ pseudoAccessoryView: PseudoAccessoryView, keyboardFrameDidChange frame: CGRect) {
        let keyboardFrame = view.convert(frame, from: nil)

        if shouldObserveKeyboard {
            layoutAccessoryView(keyboardFrame: keyboardFrame)
        } else {
            pendingFrame = keyboardFrame
        }
    }

}
