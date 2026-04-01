import UIKit

/// One calendar day: circle chrome + **UIButton** as a direct subview of the grid (not inside `UICollectionView`) so IDB / `screen_mapper` enumerate each day.
final class CalendarDaySlotView: UIView {

    private let circleView = UIView()
    private let dayButton = UIButton(type: .system)
    private var onSelect: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = false
        clipsToBounds = false

        addSubview(circleView)
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.layer.cornerRadius = 18
        circleView.layer.cornerCurve = .continuous
        circleView.isUserInteractionEnabled = false

        dayButton.translatesAutoresizingMaskIntoConstraints = false
        dayButton.backgroundColor = .clear
        dayButton.addAction(UIAction { [weak self] _ in self?.onSelect?() }, for: .touchUpInside)
        addSubview(dayButton)

        let size: CGFloat = 36
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: size),
            circleView.heightAnchor.constraint(equalToConstant: size),

            dayButton.topAnchor.constraint(equalTo: topAnchor),
            dayButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            dayButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            dayButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        day: CalendarDay,
        isSelected: Bool,
        accessibilityIdentifier: String,
        onSelect: @escaping () -> Void
    ) {
        self.onSelect = onSelect
        let title = String(day.number)

        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = dayForeground(day: day, isSelected: isSelected)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.preferredFont(forTextStyle: .body)
            return out
        }
        config.contentInsets = .zero
        config.background.backgroundColor = .clear
        dayButton.configuration = config

        if isSelected {
            circleView.backgroundColor = .label
            circleView.layer.borderWidth = 0
            dayButton.accessibilityTraits = [.button, .selected]
        } else {
            circleView.backgroundColor = .clear
            dayButton.accessibilityTraits = .button
            if day.isToday {
                circleView.layer.borderWidth = 1.5
                circleView.layer.borderColor = UIColor.label.cgColor
            } else {
                circleView.layer.borderWidth = 0
                circleView.layer.borderColor = nil
            }
        }

        dayButton.accessibilityIdentifier = accessibilityIdentifier
        dayButton.accessibilityLabel = String(localized: "Day \(title)")
        dayButton.isAccessibilityElement = true
    }

    private func dayForeground(day: CalendarDay, isSelected: Bool) -> UIColor {
        if isSelected { return .systemBackground }
        return day.isCurrentMonth ? .label : .tertiaryLabel
    }
}
