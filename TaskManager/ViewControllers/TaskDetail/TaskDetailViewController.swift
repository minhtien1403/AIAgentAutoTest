import UIKit

final class TaskDetailViewController: UIViewController {

    private var viewModel: TaskDetailViewModel
    private let repository: TaskRepositoryProtocol
    private let onDone: () -> Void

    private let appHeaderView: AppHeaderView

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let actionStack = UIStackView()
    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)

    private let titleRow = UIStackView()
    private let titleLabel = UILabel()
    private let priorityBadge = PriorityBadgeView()
    private let descriptionLabel = UILabel()
    private let dueDateLabel = UILabel()
    private let statusLabel = UILabel()
    private let toggleCompleteButton = UIButton(type: .system)

    init(viewModel: TaskDetailViewModel, repository: TaskRepositoryProtocol, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.repository = repository
        self.onDone = onDone
        self.appHeaderView = AppHeaderView(
            title: String(localized: "Task"),
            containerAccessibilityIdentifier: AccessibilityIDs.AppHeader.container(context: "taskDetail"),
            titleAccessibilityIdentifier: AccessibilityIDs.AppHeader.title(context: "taskDetail")
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = AccessibilityIDs.TaskDetail.screen

        appHeaderView.addLeadingIconButton(
            systemImageName: "chevron.left",
            accessibilityIdentifier: AccessibilityIDs.TaskDetail.backButton,
            accessibilityLabel: String(localized: "Back"),
            target: self,
            action: #selector(backTapped)
        )
        view.addSubview(appHeaderView)
        pinAppHeaderToTopSafeArea(appHeaderView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        actionStack.axis = .vertical
        actionStack.alignment = .fill
        actionStack.spacing = 12

        let editTitle = String(localized: "Edit")
        let deleteTitle = String(localized: "Delete")
        editButton.accessibilityIdentifier = AccessibilityIDs.TaskDetail.editButton
        editButton.accessibilityLabel = editTitle
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        Self.stylePlainActionButtonTitle(editButton, title: editTitle, titleColor: .label)
        let editHost = DetailActionButtonHost(button: editButton, chrome: .secondary)

        deleteButton.accessibilityIdentifier = AccessibilityIDs.TaskDetail.deleteButton
        deleteButton.accessibilityLabel = deleteTitle
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        Self.stylePlainActionButtonTitle(deleteButton, title: deleteTitle, titleColor: .systemRed)
        let deleteHost = DetailActionButtonHost(button: deleteButton, chrome: .destructive)

        toggleCompleteButton.accessibilityIdentifier = AccessibilityIDs.TaskDetail.markCompleteButton
        let toggleTitle = String(localized: "Mark complete")
        Self.stylePlainActionButtonTitle(toggleCompleteButton, title: toggleTitle, titleColor: .white)
        let toggleHost = DetailActionButtonHost(button: toggleCompleteButton, chrome: .primary)

        actionStack.addArrangedSubview(editHost)
        actionStack.addArrangedSubview(deleteHost)
        actionStack.addArrangedSubview(toggleHost)

        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 10
        titleRow.distribution = .fill

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityIdentifier = AccessibilityIDs.TaskDetail.title
        titleLabel.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        priorityBadge.setContentHuggingPriority(.required, for: .horizontal)
        priorityBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleRow.addArrangedSubview(titleLabel)
        titleRow.addArrangedSubview(priorityBadge)

        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.accessibilityIdentifier = AccessibilityIDs.TaskDetail.description

        dueDateLabel.font = .preferredFont(forTextStyle: .body)
        dueDateLabel.accessibilityIdentifier = AccessibilityIDs.TaskDetail.dueDate

        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.accessibilityIdentifier = AccessibilityIDs.TaskDetail.completionStatus

        toggleCompleteButton.addAction(UIAction { [weak self] _ in
            self?.toggleCompleteTapped()
        }, for: .touchUpInside)

        stack.addArrangedSubview(titleRow)
        stack.addArrangedSubview(descriptionLabel)
        stack.addArrangedSubview(dueDateLabel)
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(actionStack)
        stack.setCustomSpacing(24, after: statusLabel)

        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: appHeaderView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        applyTask()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.reload()
        applyTask()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func applyTask() {
        let t = viewModel.task
        titleLabel.text = t.title
        descriptionLabel.text = (t.description?.isEmpty == false) ? (t.description ?? "") : "No description"
        priorityBadge.configure(
            priority: t.priority,
            accessibilityId: AccessibilityIDs.TaskDetail.priority,
            style: .tag
        )
        if let d = t.dueDate {
            let f = DateFormatter()
            f.dateStyle = .full
            dueDateLabel.text = "Due: \(f.string(from: d))"
        } else {
            dueDateLabel.text = "No due date"
        }
        statusLabel.text = t.isCompleted ? "Completed" : "Active"
        let toggleTitle = t.isCompleted ? String(localized: "Mark as active") : String(localized: "Mark complete")
        Self.stylePlainActionButtonTitle(toggleCompleteButton, title: toggleTitle, titleColor: .white)
        toggleCompleteButton.accessibilityLabel = toggleTitle
    }

    @objc private func editTapped() {
        let form = CreateTaskViewController(
            viewModel: CreateTaskViewModel(repository: repository, mode: .edit(viewModel.task)),
            onDone: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
                self?.viewModel.reload()
                self?.applyTask()
            }
        )
        navigationController?.pushViewController(form, animated: true)
    }

    @objc private func deleteTapped() {
        let alert = UIAlertController(
            title: "Delete task",
            message: "This cannot be undone.",
            preferredStyle: .alert
        )
        alert.view.accessibilityIdentifier = AccessibilityIDs.DeleteConfirm.alert
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            do {
                try self.viewModel.delete()
                self.onDone()
            } catch {}
        }
        deleteAction.accessibilityIdentifier = AccessibilityIDs.DeleteConfirm.deleteAction
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.accessibilityIdentifier = AccessibilityIDs.DeleteConfirm.cancelAction
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func toggleCompleteTapped() {
        do {
            try viewModel.toggleCompletion()
            applyTask()
        } catch {}
    }

    private static func stylePlainActionButtonTitle(_ button: UIButton, title: String, titleColor: UIColor) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = titleColor
        config.titleAlignment = .center
        let font = UIFont.preferredFont(forTextStyle: .body)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = font
            return out
        }
        button.configuration = config
    }
}

private final class DetailActionButtonHost: UIView {
    enum Chrome {
        case primary
        case secondary
        case destructive
    }

    private let chrome: Chrome
    private let cornerRadius: CGFloat = 14

    init(button: UIButton, chrome: Chrome) {
        self.chrome = chrome
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = false
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12

        switch chrome {
        case .primary:
            backgroundColor = .systemBlue
            layer.shadowOpacity = 0.22
        case .secondary:
            backgroundColor = .systemBackground
            layer.borderWidth = 1.0 / UIScreen.main.scale
            layer.borderColor = UIColor.separator.cgColor
            layer.shadowOpacity = 0.12
        case .destructive:
            backgroundColor = UIColor.systemRed.withAlphaComponent(0.14)
            layer.shadowOpacity = 0.12
        }

        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        if chrome == .secondary {
            layer.borderColor = UIColor.separator.cgColor
        }
    }
}
