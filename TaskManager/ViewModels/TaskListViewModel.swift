import Foundation

enum TaskListFilter: String, CaseIterable, Sendable {
    case all
    case active
    case completed

    var displayName: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .completed: return "Completed"
        }
    }
}

@MainActor
final class TaskListViewModel {
    private let repository: TaskRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let subtaskRepository: SubtaskRepositoryProtocol

    private(set) var tasks: [Task] = []
    private(set) var categories: [Category] = []
    var searchText: String = ""
    var filter: TaskListFilter = .all
    /// `nil` means show tasks in all categories.
    var selectedCategoryId: UUID?

    var displayedTasks: [Task] {
        var list = tasks
        switch filter {
        case .all: break
        case .active: list = list.filter { !$0.isCompleted }
        case .completed: list = list.filter { $0.isCompleted }
        }
        if let cid = selectedCategoryId {
            list = list.filter { $0.categoryId == cid }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.title.lowercased().contains(q)
                || ($0.description?.lowercased().contains(q) ?? false)
            }
        }
        return list
    }

    var isEmpty: Bool { tasks.isEmpty }
    var isDisplayedEmpty: Bool { displayedTasks.isEmpty }

    init(
        repository: TaskRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        subtaskRepository: SubtaskRepositoryProtocol
    ) {
        self.repository = repository
        self.categoryRepository = categoryRepository
        self.subtaskRepository = subtaskRepository
    }

    func load() {
        do {
            tasks = try repository.fetchAll()
        } catch {
            tasks = []
        }
        do {
            categories = try categoryRepository.fetchCategories()
        } catch {
            categories = []
        }
    }

    func delete(id: UUID) {
        do {
            try repository.delete(id: id)
            load()
        } catch {}
    }

    func toggleComplete(id: UUID) {
        guard var task = tasks.first(where: { $0.id == id }) else { return }
        do {
            let subs = try subtaskRepository.fetchSubtasks(taskId: id)
            if subs.isEmpty {
                task.isCompleted.toggle()
            } else {
                let newCompleted = !task.isCompleted
                try subtaskRepository.setAllSubtasksCompleted(taskId: id, completed: newCompleted)
                task.isCompleted = newCompleted
            }
            try repository.save(task)
            load()
        } catch {}
    }
}
