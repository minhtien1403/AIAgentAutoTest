import UIKit

/// Full-screen list: None + categories; selecting a row pops and returns the choice.
final class CategorySelectViewController: UIViewController {

    private let categories: [Category]
    private let selectedCategoryId: UUID?
    private let onPicked: (UUID?) -> Void

    private let appHeaderView: AppHeaderView
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private var rowCount: Int { 1 + categories.count }

    init(
        categories: [Category],
        selectedCategoryId: UUID?,
        onPicked: @escaping (UUID?) -> Void
    ) {
        self.categories = categories
        self.selectedCategoryId = selectedCategoryId
        self.onPicked = onPicked
        self.appHeaderView = AppHeaderView(
            title: String(localized: "Category"),
            containerAccessibilityIdentifier: AccessibilityIDs.AppHeader.container(context: "categorySelect"),
            titleAccessibilityIdentifier: AccessibilityIDs.AppHeader.title(context: "categorySelect")
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
        view.accessibilityIdentifier = AccessibilityIDs.CategorySelect.screen
        hideKeyboardWhenTappedAround()

        appHeaderView.addLeadingIconButton(
            systemImageName: "chevron.left",
            accessibilityIdentifier: AccessibilityIDs.CategorySelect.backButton,
            accessibilityLabel: String(localized: "Back"),
            target: self,
            action: #selector(backTapped)
        )

        view.addSubview(appHeaderView)
        pinAppHeaderToTopSafeArea(appHeaderView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = AccessibilityIDs.CategorySelect.tableView

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
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func categoryId(forRow row: Int) -> UUID? {
        if row == 0 { return nil }
        return categories[row - 1].id
    }

    private func isSelectedRow(_ row: Int) -> Bool {
        let id = categoryId(forRow: row)
        return id == selectedCategoryId
    }
}

extension CategorySelectViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        if indexPath.row == 0 {
            config.text = String(localized: "None")
            cell.accessibilityIdentifier = AccessibilityIDs.CategorySelect.rowNone
        } else {
            let cat = categories[indexPath.row - 1]
            config.text = cat.name
            cell.accessibilityIdentifier = AccessibilityIDs.CategorySelect.row(categoryId: cat.id)
        }
        cell.contentConfiguration = config
        cell.accessoryType = isSelectedRow(indexPath.row) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let id = categoryId(forRow: indexPath.row)
        onPicked(id)
        navigationController?.popViewController(animated: true)
    }
}
