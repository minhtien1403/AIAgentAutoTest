import UIKit

/// Wraps `UITextView` in a `UIControl` for clearer accessibility / automation identity.
final class DescriptionTextInputContainer: UIControl {

    let textView = UITextView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.keyboardDismissMode = .interactive
        textView.backgroundColor = .clear
        isAccessibilityElement = false
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyChrome() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 8
        layer.borderWidth = 1.0 / UIScreen.main.scale
        layer.borderColor = UIColor.separator.cgColor
    }

    func configureAccessibility(identifier: String, label: String) {
        textView.accessibilityIdentifier = identifier
        textView.accessibilityLabel = label
    }
}
