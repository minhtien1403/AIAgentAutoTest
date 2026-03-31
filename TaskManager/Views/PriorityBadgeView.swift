import UIKit

final class PriorityBadgeView: UIView {
    enum DisplayStyle {
        case row
        case tag
    }

    private let label = UILabel()
    private var labelLeading: NSLayoutConstraint!
    private var labelTrailing: NSLayoutConstraint!
    private var labelTop: NSLayoutConstraint!
    private var labelBottom: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(label)
        labelLeading = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6)
        labelTrailing = label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6)
        labelTop = label.topAnchor.constraint(equalTo: topAnchor, constant: 2)
        labelBottom = label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        NSLayoutConstraint.activate([labelLeading, labelTrailing, labelTop, labelBottom])
        layer.cornerRadius = 6
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(priority: Priority, accessibilityId: String, style: DisplayStyle = .row) {
        label.text = priority.displayName.uppercased()
        switch priority {
        case .low:
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.25)
            label.textColor = .systemGreen
        case .medium:
            backgroundColor = UIColor.systemOrange.withAlphaComponent(0.25)
            label.textColor = .systemOrange
        case .high:
            backgroundColor = UIColor.systemRed.withAlphaComponent(0.25)
            label.textColor = .systemRed
        }

        switch style {
        case .row:
            labelLeading.constant = 6
            labelTrailing.constant = -6
            labelTop.constant = 2
            labelBottom.constant = -2
            label.font = .preferredFont(forTextStyle: .caption1)
            layer.cornerRadius = 6
        case .tag:
            labelLeading.constant = 5
            labelTrailing.constant = -5
            labelTop.constant = 1
            labelBottom.constant = -1
            label.font = .preferredFont(forTextStyle: .caption2)
            layer.cornerRadius = 5
        }

        accessibilityLabel = "Priority \(priority.displayName)"
        accessibilityIdentifier = accessibilityId
        accessibilityValue = priority.displayName
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        let padH = labelLeading.constant + abs(labelTrailing.constant)
        let padV = labelTop.constant + abs(labelBottom.constant)
        let labelSize = label.intrinsicContentSize
        guard labelSize.width > 0, labelSize.height > 0 else {
            return super.intrinsicContentSize
        }
        return CGSize(width: labelSize.width + padH, height: labelSize.height + padV)
    }
}
