import UIKit
import RxSwift
import RxRelay
import RxCocoa

class HighlightedDescriptionCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin16
    private static let verticalMargin: CGFloat = .margin12

    private let disposeBag = DisposeBag()
    private let descriptionView = HighlightedDescriptionView()

    private let hiddenStateRelay = BehaviorRelay<Bool>(value: false)

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        commonInit()
    }

    public init(driver: Driver<String?>) {
        super.init(style: .default, reuseIdentifier: "highlighted_description_cell")

        commonInit()

        subscribe(disposeBag, driver) { [weak self] in
            self?.descriptionText = $0
        }
    }

    private func commonInit() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.clipsToBounds = true
        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(HighlightedDescriptionCell.horizontalMargin)
            maker.top.equalToSuperview().offset(HighlightedDescriptionCell.verticalMargin)
        }
    }


    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var descriptionText: String? {
        get { descriptionView.text }
        set {
            descriptionView.text = newValue
            hiddenStateRelay.accept(newValue == nil)
        }
    }

}

extension HighlightedDescriptionCell {

    var hiddenStateDriver: Driver<Bool> {
        hiddenStateRelay.asDriver()
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        guard let descriptionText = descriptionText else {
            return 0
        }

        return Self.height(containerWidth: containerWidth, text: descriptionText)
    }

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let descriptionViewWidth = containerWidth - 2 * horizontalMargin
        let descriptionViewHeight = HighlightedDescriptionView.height(containerWidth: descriptionViewWidth, text: text)
        return descriptionViewHeight + 2 * verticalMargin
    }

}
