import Foundation

@MainActor
final class TaskDetailViewModel {
    private let repository: TaskRepositoryProtocol
    private(set) var task: Task

    init(repository: TaskRepositoryProtocol, task: Task) {
        self.repository = repository
        self.task = task
    }

    func reload() {
        if let fresh = try? repository.task(id: task.id) {
            task = fresh
        }
    }

    func delete() throws {
        try repository.delete(id: task.id)
    }

    func toggleComplete() throws {
        var t = task
        t.isCompleted.toggle()
        try repository.save(t)
        task = t
    }

    func toggleCompletion() throws {
        var t = task
        t.isCompleted.toggle()
        try repository.save(t)
        task = t
    }
}
