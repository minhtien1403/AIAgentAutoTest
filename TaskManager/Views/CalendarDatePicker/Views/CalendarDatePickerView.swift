import UIKit

/// Card-style month calendar with Cancel / Apply. Selection updates `date` immediately; Cancel reverts to the last applied date.
final class CalendarDatePickerView: UIControl {

    var onApply: ((Date) -> Void)?
    var onCancel: (() -> Void)?

    private let helper = CalendarHelper()
    private var currentMonth: Date
    private var selectedDate: Date
    /// Date restored when the user taps Cancel (updated on Apply and on programmatic `setDate`).
    private var lastAppliedDate: Date

    private let minimumDate: Date
    private let maximumDate: Date

    private let clipView = UIView()
    private let headerView = CalendarHeaderView()
    private let weekdayHeaderView = WeekdayHeaderView()
    private let gridView: CalendarGridView
    private let actionView = CalendarActionView()

    private let mainStack = UIStackView()

    var date: Date {
        get { selectedDate }
        set { setDate(newValue, animated: false) }
    }

    init(minimumDate: Date? = nil, maximumDate: Date? = nil) {
        let calendar = Calendar.current
        let now = Date()
        let min = minimumDate
            ?? calendar.date(from: DateComponents(year: calendar.component(.year, from: now) - 50, month: 1, day: 1))
            ?? now
        let max = maximumDate ?? calendar.date(byAdding: .year, value: 30, to: now) ?? now
        let ordered = min <= max ? (min, max) : (max, min)
        self.minimumDate = ordered.0
        self.maximumDate = ordered.1

        let clampedNow: Date = {
            if now < ordered.0 { return ordered.0 }
            if now > ordered.1 { return ordered.1 }
            return now
        }()
        let start = helper.normalizeToNoon(clampedNow)
        self.currentMonth = start
        self.selectedDate = start
        self.lastAppliedDate = start

        self.gridView = CalendarGridView(helper: helper)

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = false
        // UIControl otherwise groups subviews; tools (IDB / screen_mapper) then see one leaf Group, not day cells.
        shouldGroupAccessibilityChildren = false

        clipView.translatesAutoresizingMaskIntoConstraints = false
        clipView.isAccessibilityElement = false
        clipView.shouldGroupAccessibilityChildren = false
        clipView.backgroundColor = .systemBackground
        clipView.layer.cornerRadius = 16
        clipView.layer.cornerCurve = .continuous
        clipView.layer.masksToBounds = true

        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 10

        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.shouldGroupAccessibilityChildren = false
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        gridView.delegate = self

        headerView.onPreviousYear = { [weak self] in self?.shiftMonth(byYears: -1) }
        headerView.onPreviousMonth = { [weak self] in self?.shiftMonth(byMonths: -1) }
        headerView.onNextMonth = { [weak self] in self?.shiftMonth(byMonths: 1) }
        headerView.onNextYear = { [weak self] in self?.shiftMonth(byYears: 1) }

        actionView.onCancel = { [weak self] in self?.handleCancel() }
        actionView.onApply = { [weak self] in self?.handleApply() }

        mainStack.addArrangedSubview(headerView)
        mainStack.addArrangedSubview(weekdayHeaderView)
        mainStack.addArrangedSubview(gridView)
        mainStack.addArrangedSubview(actionView)

        addSubview(clipView)
        clipView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            clipView.topAnchor.constraint(equalTo: topAnchor),
            clipView.leadingAnchor.constraint(equalTo: leadingAnchor),
            clipView.trailingAnchor.constraint(equalTo: trailingAnchor),
            clipView.bottomAnchor.constraint(equalTo: bottomAnchor),

            mainStack.topAnchor.constraint(equalTo: clipView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),

            weekdayHeaderView.heightAnchor.constraint(equalToConstant: 28)
        ])

        refreshMonthUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 16
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 16).cgPath
    }

    func setDate(_ date: Date, animated _: Bool) {
        let normalized = helper.normalizeToNoon(clamp(date, min: minimumDate, max: maximumDate))
        selectedDate = normalized
        lastAppliedDate = normalized
        currentMonth = normalized
        refreshMonthUI()
        postAccessibilityUpdate()
    }

    func configureAutomation(accessibilityIdentifier: String, accessibilityLabel: String) {
        gridView.configureAutomation(accessibilityIdentifier: accessibilityIdentifier, accessibilityLabel: accessibilityLabel)
        syncAutomationValue()
    }

    private func handleCancel() {
        selectedDate = lastAppliedDate
        currentMonth = lastAppliedDate
        refreshMonthUI()
        sendActions(for: .valueChanged)
        onCancel?()
        postAccessibilityUpdate()
    }

    private func handleApply() {
        lastAppliedDate = selectedDate
        onApply?(selectedDate)
        postAccessibilityUpdate()
    }

    private func shiftMonth(byMonths delta: Int) {
        let base = currentMonth
        currentMonth = delta > 0
            ? helper.nextMonth(from: base)
            : helper.previousMonth(from: base)
        refreshMonthUI()
    }

    private func shiftMonth(byYears delta: Int) {
        var d = currentMonth
        for _ in 0 ..< abs(delta) {
            d = delta > 0 ? helper.nextYear(from: d) : helper.previousYear(from: d)
        }
        currentMonth = d
        refreshMonthUI()
    }

    private func refreshMonthUI() {
        headerView.update(month: helper.monthTitle(for: currentMonth))
        let days = helper.generateDays(monthContaining: currentMonth)
        gridView.setDays(days, selectedDate: selectedDate)
    }

    private func clamp(_ date: Date, min: Date, max: Date) -> Date {
        if date < min { return min }
        if date > max { return max }
        return date
    }

    private func selectDay(_ date: Date) {
        let next = helper.normalizeToNoon(clamp(date, min: minimumDate, max: maximumDate))
        selectedDate = next
        refreshMonthUI()
        sendActions(for: .valueChanged)
        postAccessibilityUpdate()
    }

    private func postAccessibilityUpdate() {
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
        syncAutomationValue()
    }

    private func syncAutomationValue() {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale.current
        let value = f.string(from: selectedDate)
        gridView.updateAccessibilityValue(value)
    }
}

extension CalendarDatePickerView: CalendarGridViewDelegate {
    func calendarGridView(_: CalendarGridView, didSelectDay date: Date) {
        selectDay(date)
    }
}
