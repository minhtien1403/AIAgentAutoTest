import UIKit

final class CreateTaskViewController: UIViewController {

    private let viewModel: CreateTaskViewModel
    private let onDone: () -> Void
    private let appHeaderView: AppHeaderView

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleField = TaskInputField(title: "Title", placeholder: "Required", fieldId: "title")
    private let descriptionLabel = UILabel()
    private let descriptionInputContainer = DescriptionTextInputContainer()
    private let priorityLabel = UILabel()
    private let priorityControl = UISegmentedControl(items: Priority.allCases.map(\.displayName))
    private let dueDateRow = UIStackView()
    private let includeDueDateLabel = UILabel()
    private let includeDueDateSwitch = UISwitch()
    private let dueDatePicker = CalendarDatePickerView()
    private let clearDueDateButton = UIButton(type: .system)
    private let categoryLabel = UILabel()
    private let categorySelectionRow = CategorySelectionRowView()

    init(viewModel: CreateTaskViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
        let titleText: String
        switch viewModel.mode {
        case .create: titleText = "New Task"
        case .edit: titleText = "Edit Task"
        }
        self.appHeaderView = AppHeaderView(
            title: titleText,
            containerAccessibilityIdentifier: AccessibilityIDs.AppHeader.container(context: "createTask"),
            titleAccessibilityIdentifier: AccessibilityIDs.AppHeader.title(context: "createTask")
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.layoutIfNeeded()
        let switchFrame = includeDueDateSwitch.convert(includeDueDateSwitch.bounds, to: scrollView)
        let visible = CGRect(
            origin: CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y),
            size: scrollView.bounds.size
        )
        if !visible.intersects(switchFrame) {
            scrollView.scrollRectToVisible(switchFrame.insetBy(dx: -8, dy: -12), animated: false)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        hideKeyboardWhenTappedAround()

        switch viewModel.mode {
        case .create:
            view.accessibilityIdentifier = AccessibilityIDs.CreateTask.screenCreate
        case .edit:
            view.accessibilityIdentifier = AccessibilityIDs.CreateTask.screenEdit
        }

        appHeaderView.addLeadingIconButton(
            systemImageName: "xmark",
            accessibilityIdentifier: AccessibilityIDs.CreateTask.cancelButton,
            accessibilityLabel: "Cancel",
            target: self,
            action: #selector(cancelTapped)
        )
        appHeaderView.addTrailingIconButton(
            systemImageName: "checkmark",
            accessibilityIdentifier: AccessibilityIDs.CreateTask.saveButton,
            accessibilityLabel: "Save",
            target: self,
            action: #selector(saveTapped)
        )

        view.addSubview(appHeaderView)
        pinAppHeaderToTopSafeArea(appHeaderView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        titleField.textField.text = viewModel.titleText
        titleField.textField.accessibilityIdentifier = AccessibilityIDs.CreateTask.titleField

        descriptionLabel.text = "Description"
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.isAccessibilityElement = false
        descriptionInputContainer.applyChrome()
        descriptionInputContainer.configureAccessibility(
            identifier: AccessibilityIDs.CreateTask.descriptionField,
            label: "Description"
        )
        descriptionInputContainer.textView.text = viewModel.descriptionText

        priorityLabel.text = "Priority"
        priorityLabel.font = .preferredFont(forTextStyle: .subheadline)
        priorityLabel.textColor = .secondaryLabel
        priorityLabel.isAccessibilityElement = false
        priorityControl.selectedSegmentIndex = Priority.allCases.firstIndex(of: viewModel.priority) ?? 1
        priorityControl.accessibilityIdentifier = AccessibilityIDs.CreateTask.priorityControl
        priorityControl.accessibilityLabel = "Priority"

        categoryLabel.text = String(localized: "Category")
        categoryLabel.font = .preferredFont(forTextStyle: .subheadline)
        categoryLabel.textColor = .secondaryLabel
        categoryLabel.isAccessibilityElement = false

        includeDueDateLabel.text = "Due date"
        includeDueDateLabel.font = .preferredFont(forTextStyle: .body)
        includeDueDateSwitch.isOn = viewModel.hasDueDate
        includeDueDateSwitch.accessibilityIdentifier = AccessibilityIDs.CreateTask.includeDueDateSwitch
        includeDueDateSwitch.accessibilityLabel = "Due date"
        includeDueDateSwitch.addAction(UIAction { [weak self] act in
            guard let self, let sw = act.sender as? UISwitch else { return }
            self.viewModel.hasDueDate = sw.isOn
            self.updateDueDateVisibility()
        }, for: .valueChanged)

        if let d = viewModel.dueDate {
            dueDatePicker.date = d
        } else {
            dueDatePicker.date = Date()
        }
        dueDatePicker.configureAutomation(
            accessibilityIdentifier: AccessibilityIDs.CreateTask.dueDatePicker,
            accessibilityLabel: String(localized: "Due date")
        )

        clearDueDateButton.setTitle("Clear due date", for: .normal)
        clearDueDateButton.addAction(UIAction { [weak self] _ in
            self?.includeDueDateSwitch.isOn = false
            self?.viewModel.hasDueDate = false
            self?.updateDueDateVisibility()
        }, for: .touchUpInside)
        clearDueDateButton.accessibilityIdentifier = AccessibilityIDs.CreateTask.clearDueDateButton

        dueDateRow.axis = .horizontal
        dueDateRow.alignment = .center
        dueDateRow.spacing = 12
        dueDateRow.addArrangedSubview(includeDueDateLabel)
        dueDateRow.addArrangedSubview(UIView())
        dueDateRow.addArrangedSubview(includeDueDateSwitch)

        contentStack.addArrangedSubview(titleField)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.addArrangedSubview(descriptionInputContainer)
        contentStack.addArrangedSubview(priorityLabel)
        contentStack.addArrangedSubview(priorityControl)
        contentStack.addArrangedSubview(categoryLabel)
        contentStack.addArrangedSubview(categorySelectionRow)
        contentStack.addArrangedSubview(dueDateRow)
        contentStack.addArrangedSubview(clearDueDateButton)
        contentStack.addArrangedSubview(dueDatePicker)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: appHeaderView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
            descriptionInputContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])

        viewModel.loadCategories()
        refreshCategoryRow()
        categorySelectionRow.onTap = { [weak self] in
            self?.presentCategorySelect()
        }

        updateDueDateVisibility()
    }

    private func refreshCategoryRow() {
        viewModel.loadCategories()
        categorySelectionRow.configure(categories: viewModel.categories, selectedCategoryId: viewModel.categoryId)
    }

    private func presentCategorySelect() {
        viewModel.loadCategories()
        let select = CategorySelectViewController(
            categories: viewModel.categories,
            selectedCategoryId: viewModel.categoryId
        ) { [weak self] id in
            self?.viewModel.categoryId = id
            self?.refreshCategoryRow()
        }
        navigationController?.pushViewController(select, animated: true)
    }

    private func updateDueDateVisibility() {
        let on = viewModel.hasDueDate
        dueDatePicker.isHidden = !on
        clearDueDateButton.isHidden = !on
    }

    @objc private func cancelTapped() {
        onDone()
    }

    @objc private func saveTapped() {
        viewModel.titleText = titleField.textField.text ?? ""
        viewModel.descriptionText = descriptionInputContainer.textView.text ?? ""
        let idx = priorityControl.selectedSegmentIndex
        if idx >= 0, idx < Priority.allCases.count {
            viewModel.priority = Priority.allCases[idx]
        }
        viewModel.hasDueDate = includeDueDateSwitch.isOn
        viewModel.dueDate = viewModel.hasDueDate ? dueDatePicker.date : nil
        do {
            try viewModel.save()
            onDone()
        } catch {
            let alert = UIAlertController(
                title: "Cannot save",
                message: "Title cannot be empty.",
                preferredStyle: .alert
            )
            alert.view.accessibilityIdentifier = AccessibilityIDs.CreateTask.validationAlert
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
