import UIKit

/// Monday-first short labels (Mo Tu We Th Fr Sa Su), localized where possible.
final class WeekdayHeaderView: UIView {

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        rebuildLabels()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func rebuildLabels() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let cal = Calendar.current
        let symbols = cal.veryShortWeekdaySymbols
        // Monday-first order
        let order = [2, 3, 4, 5, 6, 7, 1]
        for weekday in order {
            let label = UILabel()
            label.textAlignment = .center
            label.font = .preferredFont(forTextStyle: .caption1)
            label.textColor = .secondaryLabel
            label.adjustsFontForContentSizeCategory = true
            let idx = weekday - 1
            if idx >= 0, idx < symbols.count {
                label.text = symbols[idx].uppercased()
            }
            stack.addArrangedSubview(label)
        }
    }
}
