import UIKit

final class TaskListViewController: UIViewController {

    private let viewModel: TaskListViewModel
    private let repository: TaskRepositoryProtocol

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchBar = UISearchBar(frame: .zero)
    private let emptyStateView = EmptyStateView()
    private let floatingAddButton = UIButton(type: .system)

    private let appHeaderView = AppHeaderView(
        title: "SmartTask",
        containerAccessibilityIdentifier: AccessibilityIDs.TaskList.customHeader,
        titleAccessibilityIdentifier: AccessibilityIDs.TaskList.headerTitle
    )
    private var filterHeaderButton: UIButton!

    init(viewModel: TaskListViewModel, repository: TaskRepositoryProtocol) {
        self.viewModel = viewModel
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = AccessibilityIDs.TaskList.screen

        filterHeaderButton = appHeaderView.addTrailingIconButton(
            systemImageName: "line.3.horizontal.decrease.circle",
            accessibilityIdentifier: AccessibilityIDs.TaskList.filterButton,
            accessibilityLabel: "Filter",
            target: self,
            action: #selector(filterTapped)
        )
        appHeaderView.addTrailingIconButton(
            systemImageName: "plus",
            accessibilityIdentifier: AccessibilityIDs.TaskList.addButton,
            accessibilityLabel: "Add",
            target: self,
            action: #selector(addTapped)
        )

        searchBar.placeholder = "Search tasks"
        searchBar.delegate = self
        searchBar.accessibilityIdentifier = AccessibilityIDs.TaskList.searchBar
        searchBar.searchBarStyle = .minimal

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.accessibilityIdentifier = AccessibilityIDs.TaskList.tableView

        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true

        floatingAddButton.translatesAutoresizingMaskIntoConstraints = false
        var fabConfig = UIButton.Configuration.filled()
        fabConfig.image = UIImage(systemName: "plus")
        fabConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        fabConfig.baseForegroundColor = .white
        fabConfig.baseBackgroundColor = .systemBlue
        fabConfig.cornerStyle = .capsule
        floatingAddButton.configuration = fabConfig
        floatingAddButton.accessibilityIdentifier = AccessibilityIDs.TaskList.floatingAddButton
        floatingAddButton.accessibilityLabel = "Add task"
        floatingAddButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        view.addSubview(appHeaderView)
        pinAppHeaderToTopSafeArea(appHeaderView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(floatingAddButton)

        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 56))
        searchBar.sizeToFit()
        headerContainer.addSubview(searchBar)
        searchBar.frame = headerContainer.bounds
        searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.tableHeaderView = headerContainer

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: appHeaderView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            floatingAddButton.widthAnchor.constraint(equalToConstant: 56),
            floatingAddButton.heightAnchor.constraint(equalToConstant: 56),
            floatingAddButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            floatingAddButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let height: CGFloat = 56
        if header.frame.width != width || header.frame.height != height {
            header.frame = CGRect(x: 0, y: 0, width: width, height: height)
            tableView.tableHeaderView = header
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refresh()
    }

    private func refresh() {
        viewModel.load()
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        let displayedEmpty = viewModel.isDisplayedEmpty
        emptyStateView.isHidden = !displayedEmpty
        tableView.isScrollEnabled = !displayedEmpty || !viewModel.isEmpty
        if displayedEmpty {
            if viewModel.isEmpty {
                emptyStateView.configure(
                    title: "No tasks yet",
                    message: "Tap the + button or the floating add button to create your first task."
                )
            } else {
                emptyStateView.configure(
                    title: "No matching tasks",
                    message: "Try a different search or filter."
                )
            }
        }
    }

    @objc private func addTapped() {
        let form = CreateTaskViewController(
            viewModel: CreateTaskViewModel(repository: repository, mode: .create)
        ) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
            self?.refresh()
        }
        navigationController?.pushViewController(form, animated: true)
    }

    @objc private func filterTapped() {
        let alert = UIAlertController(title: "Filter", message: "Show tasks by status", preferredStyle: .actionSheet)
        alert.view.accessibilityIdentifier = AccessibilityIDs.Filter.alert
        for filter in TaskListFilter.allCases {
            let action = UIAlertAction(title: filter.displayName, style: .default) { [weak self] _ in
                self?.viewModel.filter = filter
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = filterHeaderButton
            pop.sourceRect = filterHeaderButton.bounds
            pop.permittedArrowDirections = .up
        }
        present(alert, animated: true)
    }

    private func openDetail(_ task: Task) {
        let detail = TaskDetailViewController(
            viewModel: TaskDetailViewModel(repository: repository, task: task),
            repository: repository
        ) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
            self?.refresh()
        }
        navigationController?.pushViewController(detail, animated: true)
    }

}

extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.displayedTasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.reuseId, for: indexPath) as? TaskCell else {
            return UITableViewCell()
        }
        let task = viewModel.displayedTasks[indexPath.row]
        cell.configure(task: task)
        cell.onCompleteTapped = { [weak self] in
            self?.viewModel.toggleComplete(id: task.id)
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            self?.updateEmptyState()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = viewModel.displayedTasks[indexPath.row]
        openDetail(task)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let task = viewModel.displayedTasks[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.viewModel.delete(id: task.id)
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
            self?.updateEmptyState()
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let task = viewModel.displayedTasks[indexPath.row]
        let title = task.isCompleted ? "Mark active" : "Complete"
        let complete = UIContextualAction(style: .normal, title: title) { [weak self] _, _, done in
            self?.viewModel.toggleComplete(id: task.id)
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            self?.updateEmptyState()
            done(true)
        }
        complete.backgroundColor = .systemGreen
        complete.image = UIImage(systemName: task.isCompleted ? "circle" : "checkmark.circle.fill")
        return UISwipeActionsConfiguration(actions: [complete])
    }
}

extension TaskListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
        tableView.reloadData()
        updateEmptyState()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
