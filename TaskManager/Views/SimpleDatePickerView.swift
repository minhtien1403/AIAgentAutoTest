import UIKit

/// Wheel-style date picker (month · day · year) without using `UIDatePicker`.
final class SimpleDatePickerView: UIControl {

    private let picker = AutomationPickerView()
    private let calendar = Calendar.current

    private let minYear: Int
    private let maxYear: Int

    private var selectionMonthIndex = 0
    private var selectionDayIndex = 0
    private var selectionYearIndex = 0

    var date: Date {
        get { dateFromSelection() }
        set { applyDate(clamping(newValue), animated: false) }
    }

    private let minimumDate: Date
    private let maximumDate: Date

    init(minimumDate: Date? = nil, maximumDate: Date? = nil) {
        let now = Date()
        let min = minimumDate
            ?? calendar.date(from: DateComponents(year: calendar.component(.year, from: now) - 50, month: 1, day: 1))
            ?? now
        let max = maximumDate ?? calendar.date(byAdding: .year, value: 30, to: now) ?? now
        let ordered = min <= max ? (min, max) : (max, min)
        self.minimumDate = ordered.0
        self.maximumDate = ordered.1
        self.minYear = calendar.component(.year, from: self.minimumDate)
        self.maxYear = calendar.component(.year, from: self.maximumDate)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        picker.valueSource = self
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.delegate = self
        picker.dataSource = self
        isAccessibilityElement = false
        addSubview(picker)
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: topAnchor),
            picker.leadingAnchor.constraint(equalTo: leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: trailingAnchor),
            picker.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 216)
        ])
    }

    func configureAutomation(accessibilityIdentifier: String, accessibilityLabel: String) {
        picker.accessibilityIdentifier = accessibilityIdentifier
        picker.accessibilityLabel = accessibilityLabel
        picker.isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDate(_ date: Date, animated: Bool) {
        applyDate(clamping(date), animated: animated)
    }

    private func applyDate(_ date: Date, animated: Bool) {
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        let d = calendar.component(.day, from: date)

        selectionYearIndex = min(max(0, y - minYear), maxYear - minYear)
        selectionMonthIndex = m - 1
        let maxDay = daysInMonth(year: minYear + selectionYearIndex, month: m)
        selectionDayIndex = min(max(0, d - 1), maxDay - 1)

        picker.selectRow(selectionYearIndex, inComponent: 2, animated: animated)
        picker.selectRow(selectionMonthIndex, inComponent: 0, animated: animated)
        picker.reloadComponent(1)
        picker.selectRow(selectionDayIndex, inComponent: 1, animated: animated)
        postAccessibilityValueUpdate()
    }

    private func clamping(_ date: Date) -> Date {
        if date < minimumDate { return minimumDate }
        if date > maximumDate { return maximumDate }
        return date
    }

    private func daysInMonth(year: Int, month: Int) -> Int {
        var c = DateComponents(year: year, month: month, day: 1)
        guard let ref = calendar.date(from: c),
              let range = calendar.range(of: .day, in: .month, for: ref)
        else { return 31 }
        return range.count
    }

    private func dateFromSelection() -> Date {
        let year = minYear + selectionYearIndex
        let month = selectionMonthIndex + 1
        let maxDay = daysInMonth(year: year, month: month)
        let day = min(selectionDayIndex + 1, maxDay)
        var c = DateComponents(year: year, month: month, day: day)
        c.hour = 12
        c.minute = 0
        c.second = 0
        return calendar.date(from: c).map(clamping) ?? minimumDate
    }

    private func monthSymbols() -> [String] {
        calendar.shortMonthSymbols
    }

    fileprivate func formattedDateForAccessibility() -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale.current
        return f.string(from: date)
    }

    private func postAccessibilityValueUpdate() {
        UIAccessibility.post(notification: .layoutChanged, argument: picker)
    }
}

private final class AutomationPickerView: UIPickerView {
    weak var valueSource: SimpleDatePickerView?

    override var accessibilityValue: String? {
        get { valueSource?.formattedDateForAccessibility() ?? super.accessibilityValue }
        set { }
    }
}

extension SimpleDatePickerView: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in _: UIPickerView) -> Int { 3 }

    func pickerView(_: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return 12
        case 1:
            let year = minYear + selectionYearIndex
            let month = selectionMonthIndex + 1
            return daysInMonth(year: year, month: month)
        case 2: return maxYear - minYear + 1
        default: return 0
        }
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0: return monthSymbols()[row]
        case 1: return String(row + 1)
        case 2: return String(minYear + row)
        default: return nil
        }
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0: selectionMonthIndex = row
        case 1: selectionDayIndex = row
        case 2: selectionYearIndex = row
        default: break
        }

        if component == 0 || component == 2 {
            picker.reloadComponent(1)
            let year = minYear + selectionYearIndex
            let month = selectionMonthIndex + 1
            let maxDay = daysInMonth(year: year, month: month)
            if selectionDayIndex >= maxDay {
                selectionDayIndex = maxDay - 1
                picker.selectRow(selectionDayIndex, inComponent: 1, animated: true)
            }
        }
        sendActions(for: .valueChanged)
        postAccessibilityValueUpdate()
    }
}
