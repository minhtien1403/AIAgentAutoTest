import UIKit

/// Tappable row that navigates to a separate picker screen. Use a section label above (e.g. in the form stack) for the field title.
final class CategorySelectionRowView: UIView {

    var onTap: (() -> Void)?

    private let tapControl = UIControl()
    private let valueLabel = UILabel()
    private let chevronView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

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

        addSubview(tapControl)
        tapControl.addSubview(valueLabel)
        tapControl.addSubview(chevronView)

        NSLayoutConstraint.activate([
            tapControl.topAnchor.constraint(equalTo: topAnchor),
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
