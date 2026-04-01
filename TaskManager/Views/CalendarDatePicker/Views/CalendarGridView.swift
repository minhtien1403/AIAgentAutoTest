import UIKit

protocol CalendarGridViewDelegate: AnyObject {
    func calendarGridView(_ grid: CalendarGridView, didSelectDay date: Date)
}

/// 6×7 grid of **UIButton** slots (no `UICollectionView`) so accessibility tools list each day with `smartTask_taskForm_calendarDay_*`.
final class CalendarGridView: UIView {

    weak var delegate: CalendarGridViewDelegate?

    private let helper: CalendarHelper
    private var days: [CalendarDay] = []
    private var selectedDate: Date?

    private let buttonsContainer = UIStackView()
    private var daySlots: [CalendarDaySlotView] = []

    private let rowHeight: CGFloat = 40

    init(helper: CalendarHelper) {
        self.helper = helper
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        buttonsContainer.axis = .vertical
        buttonsContainer.spacing = 0
        buttonsContainer.distribution = .fillEqually
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonsContainer.isAccessibilityElement = false
        buttonsContainer.shouldGroupAccessibilityChildren = false

        var slots: [CalendarDaySlotView] = []
        for _ in 0 ..< 6 {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 0
            row.distribution = .fillEqually
            row.translatesAutoresizingMaskIntoConstraints = false
            for _ in 0 ..< 7 {
                let slot = CalendarDaySlotView()
                slots.append(slot)
                row.addArrangedSubview(slot)
            }
            buttonsContainer.addArrangedSubview(row)
            row.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
        }
        daySlots = slots

        addSubview(buttonsContainer)
        NSLayoutConstraint.activate([
            buttonsContainer.topAnchor.constraint(equalTo: topAnchor),
            buttonsContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonsContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonsContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: rowHeight * 6)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDays(_ days: [CalendarDay], selectedDate: Date?) {
        self.days = days
        self.selectedDate = selectedDate
        let count = min(days.count, daySlots.count)
        for i in 0 ..< count {
            let day = days[i]
            let selected = selectedDate.map { helper.isDate($0, inSameDayAs: day.date) } ?? false
            let id = AccessibilityIDs.CreateTask.calendarDayCell(index: i)
            daySlots[i].configure(day: day, isSelected: selected, accessibilityIdentifier: id) { [weak self] in
                guard let self else { return }
                self.delegate?.calendarGridView(self, didSelectDay: day.date)
            }
        }
    }

    func configureAutomation(accessibilityIdentifier: String, accessibilityLabel: String) {
        buttonsContainer.accessibilityIdentifier = accessibilityIdentifier
        buttonsContainer.accessibilityLabel = accessibilityLabel
        buttonsContainer.isAccessibilityElement = false
        buttonsContainer.shouldGroupAccessibilityChildren = false
    }

    func updateAccessibilityValue(_ value: String?) {
        buttonsContainer.accessibilityValue = value
    }
}
