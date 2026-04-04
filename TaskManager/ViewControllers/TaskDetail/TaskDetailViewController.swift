import UIKit

final class TaskDetailViewController: UIViewController {

    private var viewModel: TaskDetailViewModel
    private let repository: TaskRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let subtaskRepository: SubtaskRepositoryProtocol
    private var subtaskViewModel: SubtaskViewModel!
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
    private let categoryLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let dueDateLabel = UILabel()
    private let taskStatusRow = UIStackView()
    private let taskStatusBadge = TaskStatusBadgeView()
    private let taskStatusChangeButton = UIButton(type: .system)
    private let subtasksHeadingLabel = UILabel()
    private let subtasksTableView = UITableView(frame: .zero, style: .plain)
    private let addSubtaskButton = UIButton(type: .system)
    private var subtasksHeightConstraint: NSLayoutConstraint!
    private let toggleCompleteButton = UIButton(type: .system)

    init(
        viewModel: TaskDetailViewModel,
        repository: TaskRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        subtaskRepository: SubtaskRepositoryProtocol,
        onDone: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.repository = repository
        self.categoryRepository = categoryRepository
        self.subtaskRepository = subtaskRepository
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
        hideKeyboardWhenTappedAround()

        subtaskViewModel = SubtaskViewModel(
            subtaskRepository: subtaskRepository,
            taskRepository: repository,
            taskId: viewModel.task.id
        )

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

        categoryLabel.font = .preferredFont(forTextStyle: .subheadline)
        categoryLabel.textColor = .secondaryLabel
        categoryLabel.numberOfLines = 0
        categoryLabel.accessibilityIdentifier = AccessibilityIDs.TaskDetail.categoryLabel

        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.accessibilityIdentifier = AccessibilityIDs.TaskDetail.description

        dueDateLabel.font = .preferredFont(forTextStyle: .body)
        dueDateLabel.accessibilityIdentifier = AccessibilityIDs.TaskDetail.dueDate

        taskStatusRow.axis = .horizontal
        taskStatusRow.alignment = .center
        taskStatusRow.spacing = 12
        taskStatusRow.distribution = .fill

        taskStatusBadge.setContentHuggingPriority(.required, for: .horizontal)
        taskStatusBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        var statusBtnConfig = UIButton.Configuration.plain()
        statusBtnConfig.title = String(localized: "Change status")
        statusBtnConfig.image = UIImage(systemName: "chevron.down.circle")
        statusBtnConfig.imagePlacement = .trailing
        statusBtnConfig.imagePadding = 6
        statusBtnConfig.baseForegroundColor = .systemBlue
        let bodyFont = UIFont.preferredFont(forTextStyle: .subheadline)
        statusBtnConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = bodyFont
            return out
        }
        taskStatusChangeButton.configuration = statusBtnConfig
        taskStatusChangeButton.accessibilityIdentifier = AccessibilityIDs.TaskDetail.taskStatusChangeButton
        taskStatusChangeButton.accessibilityLabel = String(localized: "Change status")
        taskStatusChangeButton.addAction(UIAction { [weak self] _ in self?.presentStatusPicker() }, for: .touchUpInside)

        let statusSpacer = UIView()
        statusSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        taskStatusRow.addArrangedSubview(taskStatusBadge)
        taskStatusRow.addArrangedSubview(statusSpacer)
        taskStatusRow.addArrangedSubview(taskStatusChangeButton)

        subtasksHeadingLabel.text = String(localized: "Subtasks")
        subtasksHeadingLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtasksHeadingLabel.textColor = .secondaryLabel

        subtasksTableView.translatesAutoresizingMaskIntoConstraints = false
        subtasksTableView.register(SubtaskCell.self, forCellReuseIdentifier: SubtaskCell.reuseId)
        subtasksTableView.dataSource = self
        subtasksTableView.delegate = self
        subtasksTableView.isScrollEnabled = false
        subtasksTableView.backgroundColor = .secondarySystemGroupedBackground
        subtasksTableView.separatorStyle = .singleLine
        subtasksTableView.layer.cornerRadius = 12
        if #available(iOS 13.0, *) {
            subtasksTableView.layer.cornerCurve = .continuous
        }
        subtasksTableView.clipsToBounds = true
        subtasksTableView.rowHeight = UITableView.automaticDimension
        subtasksTableView.estimatedRowHeight = 52
        subtasksTableView.sectionHeaderHeight = 0
        subtasksTableView.sectionFooterHeight = 0
        subtasksTableView.accessibilityIdentifier = AccessibilityIDs.TaskDetail.subtasksTable
        subtasksHeightConstraint = subtasksTableView.heightAnchor.constraint(equalToConstant: 0)

        addSubtaskButton.setTitle(String(localized: "Add subtask"), for: .normal)
        addSubtaskButton.addAction(UIAction { [weak self] _ in self?.addSubtaskTapped() }, for: .touchUpInside)
        addSubtaskButton.accessibilityIdentifier = AccessibilityIDs.TaskDetail.addSubtaskButton

        toggleCompleteButton.addAction(UIAction { [weak self] _ in
            self?.toggleCompleteTapped()
        }, for: .touchUpInside)

        stack.addArrangedSubview(titleRow)
        stack.addArrangedSubview(categoryLabel)
        stack.addArrangedSubview(descriptionLabel)
        stack.addArrangedSubview(dueDateLabel)
        stack.addArrangedSubview(taskStatusRow)
        stack.addArrangedSubview(subtasksHeadingLabel)
        stack.addArrangedSubview(subtasksTableView)
        stack.addArrangedSubview(addSubtaskButton)
        stack.addArrangedSubview(actionStack)
        stack.setCustomSpacing(24, after: addSubtaskButton)

        NSLayoutConstraint.activate([subtasksHeightConstraint])

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        syncSubtasksTableViewHeight()
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

    private func reloadSubtasksUI() {
        subtaskViewModel.loadSubtasks()
        subtasksTableView.reloadData()
        syncSubtasksTableViewHeight()
    }

    /// Embedded table uses a fixed height constraint; keep it equal to content size so multi-line / Dynamic Type rows are not clipped.
    private func syncSubtasksTableViewHeight() {
        subtasksTableView.layoutIfNeeded()
        let h = subtasksTableView.contentSize.height
        if abs(subtasksHeightConstraint.constant - h) < 0.5 { return }
        subtasksHeightConstraint.constant = h
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
        if let cid = t.categoryId,
           let name = (try? categoryRepository.fetchCategories())?.first(where: { $0.id == cid })?.name {
            categoryLabel.text = String(localized: "Category: \(name)")
            categoryLabel.isHidden = false
        } else {
            categoryLabel.text = nil
            categoryLabel.isHidden = true
        }
        if let d = t.dueDate {
            let f = DateFormatter()
            f.dateStyle = .full
            dueDateLabel.text = "Due: \(f.string(from: d))"
        } else {
            dueDateLabel.text = "No due date"
        }
        taskStatusBadge.configure(
            taskStatus: t.taskStatus,
            accessibilityId: AccessibilityIDs.TaskDetail.taskStatusBadge,
            style: .tag
        )
        let toggleTitle = t.isCompleted ? String(localized: "Mark as active") : String(localized: "Mark complete")
        Self.stylePlainActionButtonTitle(toggleCompleteButton, title: toggleTitle, titleColor: .white)
        toggleCompleteButton.accessibilityLabel = toggleTitle
        reloadSubtasksUI()
    }

    @objc private func editTapped() {
        let form = CreateTaskViewController(
            viewModel: CreateTaskViewModel(
                repository: repository,
                categoryRepository: categoryRepository,
                mode: .edit(viewModel.task)
            ),
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

    private func addSubtaskTapped() {
        let alert = UIAlertController(title: String(localized: "New subtask"), message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = String(localized: "Title") }
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "Add"), style: .default) { [weak self] _ in
            guard let self else { return }
            let title = alert.textFields?.first?.text ?? ""
            do {
                try self.subtaskViewModel.addSubtask(title: title)
                self.viewModel.reload()
                self.applyTask()
            } catch {
                let err = UIAlertController(
                    title: String(localized: "Cannot add"),
                    message: String(localized: "Subtask title cannot be empty."),
                    preferredStyle: .alert
                )
                err.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(err, animated: true)
            }
        })
        present(alert, animated: true)
    }

    private func toggleCompleteTapped() {
        do {
            try viewModel.toggleCompletion()
            applyTask()
        } catch {}
    }

    private func presentStatusPicker() {
        let alert = UIAlertController(
            title: String(localized: "Status"),
            message: String(localized: "Choose task status"),
            preferredStyle: .actionSheet
        )
        alert.view.accessibilityIdentifier = AccessibilityIDs.TaskDetail.statusPickerAlert
        for status in TaskStatus.allCases {
            let action = UIAlertAction(title: status.displayName, style: .default) { [weak self] _ in
                guard let self else { return }
                do {
                    try self.viewModel.setTaskStatus(status)
                    self.applyTask()
                } catch {}
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = taskStatusChangeButton
            pop.sourceRect = taskStatusChangeButton.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(alert, animated: true)
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

extension TaskDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        subtaskViewModel.subtasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SubtaskCell.reuseId, for: indexPath) as? SubtaskCell else {
            return UITableViewCell()
        }
        let sub = subtaskViewModel.subtasks[indexPath.row]
        cell.accessibilityIdentifier = AccessibilityIDs.TaskDetail.subtaskRow(subtaskId: sub.id)
        cell.configure(
            subtask: sub,
            accessibilityToggleId: AccessibilityIDs.TaskDetail.subtaskToggle(subtaskId: sub.id)
        )
        cell.onToggle = { [weak self] in
            guard let self else { return }
            do {
                try self.subtaskViewModel.toggleSubtaskCompletion(id: sub.id)
                self.viewModel.reload()
                self.applyTask()
            } catch {}
        }
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let sub = subtaskViewModel.subtasks[indexPath.row]
        let del = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [weak self] _, _, done in
            guard let self else {
                done(true)
                return
            }
            do {
                try self.subtaskViewModel.deleteSubtask(id: sub.id)
                self.viewModel.reload()
                self.applyTask()
            } catch {}
            done(true)
        }
        del.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [del])
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
