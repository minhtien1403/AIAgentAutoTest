import Foundation

@MainActor
final class TaskDetailViewModel {
    private let repository: TaskRepositoryProtocol
    private let subtaskRepository: SubtaskRepositoryProtocol
    private(set) var task: Task

    init(repository: TaskRepositoryProtocol, subtaskRepository: SubtaskRepositoryProtocol, task: Task) {
        self.repository = repository
        self.subtaskRepository = subtaskRepository
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
        try toggleCompletion()
    }

    func toggleCompletion() throws {
        let subs = try subtaskRepository.fetchSubtasks(taskId: task.id)
        var t = task
        if subs.isEmpty {
            t.toggleCompletionWithStatusSync()
        } else {
            let newCompleted = !t.isCompleted
            try subtaskRepository.setAllSubtasksCompleted(taskId: task.id, completed: newCompleted)
            t.isCompleted = newCompleted
            if newCompleted {
                t.taskStatus = .done
            } else if t.taskStatus == .done {
                t.taskStatus = .todo
            }
        }
        try repository.save(t)
        task = t
    }

    func setTaskStatus(_ newStatus: TaskStatus) throws {
        var t = task
        t.applyTaskStatus(newStatus)
        try repository.save(t)
        task = t
    }
}
