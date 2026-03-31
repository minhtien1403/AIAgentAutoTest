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

    private(set) var tasks: [Task] = []
    var searchText: String = ""
    var filter: TaskListFilter = .all

    var displayedTasks: [Task] {
        var list = tasks
        switch filter {
        case .all: break
        case .active: list = list.filter { !$0.isCompleted }
        case .completed: list = list.filter { $0.isCompleted }
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

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    func load() {
        do {
            tasks = try repository.fetchAll()
        } catch {
            tasks = []
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
        task.isCompleted.toggle()
        do {
            try repository.save(task)
            load()
        } catch {}
    }
}
