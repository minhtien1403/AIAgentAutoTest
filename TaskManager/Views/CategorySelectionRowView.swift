import UIKit

/// "Category" heading + tappable row that navigates to a separate picker screen.
final class CategorySelectionRowView: UIView {

    var onTap: (() -> Void)?

    private let headingLabel = UILabel()
    private let tapControl = UIControl()
    private let valueLabel = UILabel()
    private let chevronView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        headingLabel.text = String(localized: "Category")
        headingLabel.font = .preferredFont(forTextStyle: .subheadline)
        headingLabel.textColor = .secondaryLabel

        tapControl.translatesAutoresizingMaskIntoConstraints = false
        tapControl.backgroundColor = .secondarySystemGroupedBackground
        tapControl.layer.cornerRadius = 10
        tapControl.layer.cornerCurve = .continuous
        tapControl.addAction(UIAction { [weak self] _ in
            self?.onTap?()
        }, for: .touchUpInside)
        tapControl.accessibilityIdentifier = AccessibilityIDs.CreateTask.categorySelectionRow
        tapControl.accessibilityLabel = String(localized: "Category")
        tapControl.accessibilityTraits.insert(.button)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .preferredFont(forTextStyle: .body)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.isAccessibilityElement = false

        chevronView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.image = UIImage(systemName: "chevron.right")
        chevronView.tintColor = .tertiaryLabel
        chevronView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body, scale: .default)
        chevronView.isAccessibilityElement = false

        addSubview(headingLabel)
        addSubview(tapControl)
        tapControl.addSubview(valueLabel)
        tapControl.addSubview(chevronView)

        NSLayoutConstraint.activate([
            headingLabel.topAnchor.constraint(equalTo: topAnchor),
            headingLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            headingLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            tapControl.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 6),
            tapControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            tapControl.bottomAnchor.constraint(equalTo: bottomAnchor),
            tapControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            valueLabel.leadingAnchor.constraint(equalTo: tapControl.leadingAnchor, constant: 12),
            valueLabel.centerYAnchor.constraint(equalTo: tapControl.centerYAnchor),
            valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronView.leadingAnchor, constant: -8),

            chevronView.trailingAnchor.constraint(equalTo: tapControl.trailingAnchor, constant: -12),
            chevronView.centerYAnchor.constraint(equalTo: tapControl.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 12),
            chevronView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(categories: [Category], selectedCategoryId: UUID?) {
        if let id = selectedCategoryId,
           let name = categories.first(where: { $0.id == id })?.name {
            valueLabel.text = name
        } else {
            valueLabel.text = String(localized: "None")
        }
        tapControl.accessibilityValue = valueLabel.text
    }
}
