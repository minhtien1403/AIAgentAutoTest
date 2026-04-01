import Foundation

@MainActor
final class CategoryListViewModel {
    private let repository: CategoryRepositoryProtocol

    private(set) var categories: [Category] = []

    private static let defaultColors = ["#007AFF", "#34C759", "#FF9500", "#AF52DE", "#FF3B30", "#5AC8FA"]

    init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
    }

    func loadCategories() {
        do {
            categories = try repository.fetchCategories()
        } catch {
            categories = []
        }
    }

    func createCategory(name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CategoryListError.nameRequired }
        let colorIndex = categories.count % Self.defaultColors.count
        let category = Category(name: trimmed, color: Self.defaultColors[colorIndex])
        try repository.createCategory(category)
        loadCategories()
    }

    func deleteCategory(id: UUID) {
        do {
            try repository.deleteCategory(id: id)
            loadCategories()
        } catch {}
    }
}

enum CategoryListError: Error {
    case nameRequired
}
