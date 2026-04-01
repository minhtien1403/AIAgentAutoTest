import UIKit

final class CalendarHeaderView: UIView {

    var onNextMonth: (() -> Void)?
    var onPreviousMonth: (() -> Void)?
    var onNextYear: (() -> Void)?
    var onPreviousYear: (() -> Void)?

    private let monthLabel = UILabel()
    private let prevYearButton = UIButton(type: .system)
    private let prevMonthButton = UIButton(type: .system)
    private let nextMonthButton = UIButton(type: .system)
    private let nextYearButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        monthLabel.font = .preferredFont(forTextStyle: .headline)
        monthLabel.textAlignment = .center
        monthLabel.adjustsFontForContentSizeCategory = true
        monthLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        func styleNav(_ button: UIButton, symbol: String, action: Selector) {
            let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            button.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
            button.addTarget(self, action: action, for: .touchUpInside)
        }

        styleNav(prevYearButton, symbol: "chevron.backward.2", action: #selector(prevYearTapped))
        styleNav(prevMonthButton, symbol: "chevron.left", action: #selector(prevMonthTapped))
        styleNav(nextMonthButton, symbol: "chevron.right", action: #selector(nextMonthTapped))
        styleNav(nextYearButton, symbol: "chevron.forward.2", action: #selector(nextYearTapped))

        // SF Symbols like chevron.backward.2 default to "Back" for VoiceOver — breaks text-based automation.
        prevYearButton.accessibilityLabel = String(localized: "Previous year")
        prevMonthButton.accessibilityLabel = String(localized: "Previous month")
        nextMonthButton.accessibilityLabel = String(localized: "Next month")
        nextYearButton.accessibilityLabel = String(localized: "Next year")

        let leftStack = UIStackView(arrangedSubviews: [prevYearButton, prevMonthButton])
        leftStack.axis = .horizontal
        leftStack.spacing = 14
        leftStack.alignment = .center

        let rightStack = UIStackView(arrangedSubviews: [nextMonthButton, nextYearButton])
        rightStack.axis = .horizontal
        rightStack.spacing = 14
        rightStack.alignment = .center

        for v in [leftStack, monthLabel, rightStack] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }

        addSubview(leftStack)
        addSubview(monthLabel)
        addSubview(rightStack)

        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            monthLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            monthLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftStack.trailingAnchor, constant: 8),
            monthLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightStack.leadingAnchor, constant: -8),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(month title: String) {
        monthLabel.text = title
    }

    @objc private func prevYearTapped() { onPreviousYear?() }
    @objc private func prevMonthTapped() { onPreviousMonth?() }
    @objc private func nextMonthTapped() { onNextMonth?() }
    @objc private func nextYearTapped() { onNextYear?() }
}
