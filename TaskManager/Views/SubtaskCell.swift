import UIKit

final class SubtaskCell: UITableViewCell {
    static let reuseId = "SubtaskCell"

    private let checkboxButton = UIButton(type: .system)
    private let titleLabel = UILabel()

    var onToggle: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            backgroundConfiguration = UIBackgroundConfiguration.clear()
        }
        contentView.addSubview(checkboxButton)
        contentView.addSubview(titleLabel)
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        checkboxButton.setImage(UIImage(systemName: "circle"), for: .normal)
        checkboxButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        checkboxButton.tintColor = .tertiaryLabel
        checkboxButton.addAction(UIAction { [weak self] _ in
            self?.onToggle?()
        }, for: .touchUpInside)

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        NSLayoutConstraint.activate([
            checkboxButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            checkboxButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 36),
            checkboxButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(subtask: Subtask, accessibilityToggleId: String) {
        titleLabel.text = subtask.title
        titleLabel.textColor = subtask.isCompleted ? .secondaryLabel : .label
        checkboxButton.isSelected = subtask.isCompleted
        checkboxButton.tintColor = subtask.isCompleted ? .systemGreen : .tertiaryLabel
        checkboxButton.accessibilityIdentifier = accessibilityToggleId
        checkboxButton.accessibilityLabel = subtask.isCompleted
            ? String(localized: "Mark subtask incomplete")
            : String(localized: "Mark subtask complete")
    }
}
