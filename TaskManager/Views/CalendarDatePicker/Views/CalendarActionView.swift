import UIKit

final class CalendarActionView: UIView {

    var onCancel: (() -> Void)?
    var onApply: (() -> Void)?

    private let cancelButton = UIButton(type: .system)
    private let applyButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle(String(localized: "Cancel"), for: .normal)
        cancelButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        cancelButton.addAction(UIAction { [weak self] _ in self?.onCancel?() }, for: .touchUpInside)

        applyButton.setTitle(String(localized: "Apply"), for: .normal)
        applyButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        applyButton.addAction(UIAction { [weak self] _ in self?.onApply?() }, for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [cancelButton, UIView(), applyButton])
        row.axis = .horizontal
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
