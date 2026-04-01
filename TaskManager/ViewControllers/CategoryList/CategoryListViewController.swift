import UIKit

final class CategoryListViewController: UIViewController {

    private let viewModel: CategoryListViewModel
    private let onDone: () -> Void

    private let appHeaderView: AppHeaderView
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(viewModel: CategoryListViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
        self.appHeaderView = AppHeaderView(
            title: String(localized: "Categories"),
            containerAccessibilityIdentifier: AccessibilityIDs.AppHeader.container(context: "categoryList"),
            titleAccessibilityIdentifier: AccessibilityIDs.AppHeader.title(context: "categoryList")
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = AccessibilityIDs.CategoryList.screen

        appHeaderView.addLeadingIconButton(
            systemImageName: "chevron.left",
            accessibilityIdentifier: AccessibilityIDs.CategoryList.backButton,
            accessibilityLabel: String(localized: "Back"),
            target: self,
            action: #selector(backTapped)
        )
        appHeaderView.addTrailingIconButton(
            systemImageName: "plus",
            accessibilityIdentifier: AccessibilityIDs.CategoryList.addButton,
            accessibilityLabel: String(localized: "Add category"),
            target: self,
            action: #selector(addTapped)
        )

        view.addSubview(appHeaderView)
        pinAppHeaderToTopSafeArea(appHeaderView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = AccessibilityIDs.CategoryList.tableView

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: appHeaderView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refresh()
    }

    private func refresh() {
        viewModel.loadCategories()
        tableView.reloadData()
    }

    @objc private func backTapped() {
        onDone()
    }

    @objc private func addTapped() {
        let alert = UIAlertController(
            title: String(localized: "New category"),
            message: nil,
            preferredStyle: .alert
        )
        alert.view.accessibilityIdentifier = AccessibilityIDs.CategoryList.newCategoryAlert
        alert.addTextField { field in
            field.placeholder = String(localized: "Name")
            field.accessibilityIdentifier = AccessibilityIDs.CategoryList.newCategoryNameField
        }
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "Create"), style: .default) { [weak self] _ in
            guard let self else { return }
            let name = alert.textFields?.first?.text ?? ""
            do {
                try self.viewModel.createCategory(name: name)
                self.tableView.reloadData()
            } catch {
                let err = UIAlertController(
                    title: String(localized: "Cannot create"),
                    message: String(localized: "Name cannot be empty."),
                    preferredStyle: .alert
                )
                err.view.accessibilityIdentifier = AccessibilityIDs.CategoryList.validationAlert
                err.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(err, animated: true)
            }
        })
        present(alert, animated: true)
    }
}

extension CategoryListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let cat = viewModel.categories[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = cat.name
        cell.contentConfiguration = config
        cell.accessibilityIdentifier = AccessibilityIDs.CategoryList.row(categoryId: cat.id)
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let cat = viewModel.categories[indexPath.row]
        let del = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [weak self] _, _, done in
            self?.viewModel.deleteCategory(id: cat.id)
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }
        del.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [del])
    }
}
