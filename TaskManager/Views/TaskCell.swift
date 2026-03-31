import UIKit

final class TaskCell: UITableViewCell {
    static let reuseId = "TaskCell"

    private let titleLabel = UILabel()
    private let dueDateLabel = UILabel()
    private let priorityBadge = PriorityBadgeView()
    private let completeButton = UIButton(type: .system)

    var onCompleteTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        contentView.addSubview(titleLabel)
        contentView.addSubview(dueDateLabel)
        contentView.addSubview(priorityBadge)
        contentView.addSubview(completeButton)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityBadge.translatesAutoresizingMaskIntoConstraints = false
        completeButton.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        dueDateLabel.font = .preferredFont(forTextStyle: .caption1)
        dueDateLabel.textColor = .secondaryLabel
        dueDateLabel.adjustsFontForContentSizeCategory = true

        completeButton.setImage(UIImage(systemName: "circle"), for: .normal)
        completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        completeButton.addAction(UIAction { [weak self] _ in
            self?.onCompleteTapped?()
        }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            completeButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            completeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            completeButton.widthAnchor.constraint(equalToConstant: 36),
            completeButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: completeButton.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),

            priorityBadge.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            priorityBadge.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            priorityBadge.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor),

            dueDateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dueDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dueDateLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            dueDateLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(task: Task) {
        accessibilityIdentifier = AccessibilityIDs.TaskCell.container(taskId: task.id)
        titleLabel.text = task.title
        titleLabel.accessibilityIdentifier = AccessibilityIDs.TaskCell.title(taskId: task.id)
        titleLabel.textColor = task.isCompleted ? .secondaryLabel : .label

        let dateStr: String
        if let d = task.dueDate {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .none
            dateStr = f.string(from: d)
        } else {
            dateStr = "No due date"
        }
        dueDateLabel.text = dateStr
        dueDateLabel.accessibilityIdentifier = AccessibilityIDs.TaskCell.dueDate(taskId: task.id)

        priorityBadge.configure(
            priority: task.priority,
            accessibilityId: AccessibilityIDs.TaskCell.priorityBadge(taskId: task.id)
        )

        completeButton.isSelected = task.isCompleted
        completeButton.tintColor = task.isCompleted ? .systemGreen : .tertiaryLabel
        completeButton.accessibilityIdentifier = AccessibilityIDs.TaskCell.completeToggle(taskId: task.id)
        completeButton.accessibilityLabel = task.isCompleted ? "Mark incomplete" : "Mark complete"
    }
}
