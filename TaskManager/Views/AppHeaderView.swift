import UIKit

/// App-wide header bar: large title, optional trailing icon actions, bottom hairline.
/// Pin below the safe area top; place content below `bottomAnchor`.
final class AppHeaderView: UIView {

    static let preferredHeight: CGFloat = 56
    static let iconButtonSize: CGFloat = 44

    let titleLabel = UILabel()
    let leadingStackView = UIStackView()
    let trailingStackView = UIStackView()

    private let separator = UIView()

    init(
        title: String,
        containerAccessibilityIdentifier: String,
        titleAccessibilityIdentifier: String
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        accessibilityIdentifier = containerAccessibilityIdentifier
        isAccessibilityElement = false
        backgroundColor = .systemGroupedBackground

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityIdentifier = titleAccessibilityIdentifier
        titleLabel.accessibilityTraits.insert(.header)

        leadingStackView.translatesAutoresizingMaskIntoConstraints = false
        leadingStackView.axis = .horizontal
        leadingStackView.alignment = .center
        leadingStackView.spacing = 4

        trailingStackView.translatesAutoresizingMaskIntoConstraints = false
        trailingStackView.axis = .horizontal
        trailingStackView.alignment = .center
        trailingStackView.spacing = 4

        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .separator

        addSubview(leadingStackView)
        addSubview(titleLabel)
        addSubview(trailingStackView)
        addSubview(separator)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.preferredHeight),

            leadingStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            leadingStackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingStackView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingStackView.leadingAnchor, constant: -12),

            trailingStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            trailingStackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ text: String) {
        titleLabel.text = text
    }

    @discardableResult
    func addLeadingIconButton(
        systemImageName: String,
        accessibilityIdentifier: String,
        accessibilityLabel: String,
        target: Any?,
        action: Selector
    ) -> UIButton {
        let button = Self.makeIconButton(
            systemImageName: systemImageName,
            accessibilityIdentifier: accessibilityIdentifier,
            accessibilityLabel: accessibilityLabel,
            target: target,
            action: action
        )
        leadingStackView.addArrangedSubview(button)
        button.widthAnchor.constraint(equalToConstant: Self.iconButtonSize).isActive = true
        button.heightAnchor.constraint(equalToConstant: Self.iconButtonSize).isActive = true
        button.tintColor = .black
        return button
    }

    @discardableResult
    func addTrailingIconButton(
        systemImageName: String,
        accessibilityIdentifier: String,
        accessibilityLabel: String,
        target: Any?,
        action: Selector
    ) -> UIButton {
        let button = Self.makeIconButton(
            systemImageName: systemImageName,
            accessibilityIdentifier: accessibilityIdentifier,
            accessibilityLabel: accessibilityLabel,
            target: target,
            action: action
        )
        trailingStackView.addArrangedSubview(button)
        button.widthAnchor.constraint(equalToConstant: Self.iconButtonSize).isActive = true
        button.heightAnchor.constraint(equalToConstant: Self.iconButtonSize).isActive = true
        button.tintColor = .black
        return button
    }

    static func makeIconButton(
        systemImageName: String,
        accessibilityIdentifier: String,
        accessibilityLabel: String,
        target: Any?,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: systemImageName), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.accessibilityIdentifier = accessibilityIdentifier
        button.accessibilityLabel = accessibilityLabel
        button.isAccessibilityElement = true
        return button
    }
}

extension UIViewController {

    /// Pins `AppHeaderView` to the top safe area and full width. Add the header as a subview first.
    func pinAppHeaderToTopSafeArea(_ header: AppHeaderView) {
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    /// Adds a tap gesture recognizer that dismisses the keyboard when tapping outside text inputs.
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardByTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboardByTap() {
        view.endEditing(true)
    }
}
