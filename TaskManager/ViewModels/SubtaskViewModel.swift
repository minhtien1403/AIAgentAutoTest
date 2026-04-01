import Foundation

@MainActor
final class SubtaskViewModel {
    private let subtaskRepository: SubtaskRepositoryProtocol
    private let taskRepository: TaskRepositoryProtocol
    let taskId: UUID

    private(set) var subtasks: [Subtask] = []

    init(
        subtaskRepository: SubtaskRepositoryProtocol,
        taskRepository: TaskRepositoryProtocol,
        taskId: UUID
    ) {
        self.subtaskRepository = subtaskRepository
        self.taskRepository = taskRepository
        self.taskId = taskId
    }

    func loadSubtasks() {
        do {
            subtasks = try subtaskRepository.fetchSubtasks(taskId: taskId)
        } catch {
            subtasks = []
        }
    }

    func addSubtask(title: String) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SubtaskViewModelError.titleRequired }
        let sub = Subtask(taskId: taskId, title: trimmed)
        try subtaskRepository.createSubtask(sub)
        loadSubtasks()
        try syncParentCompletionWhenHasSubtasks()
    }

    func toggleSubtaskCompletion(id: UUID) throws {
        guard var sub = subtasks.first(where: { $0.id == id }) else { return }
        sub.isCompleted.toggle()
        try subtaskRepository.updateSubtask(sub)
        loadSubtasks()
        try syncParentCompletionWhenHasSubtasks()
    }

    func deleteSubtask(id: UUID) throws {
        try subtaskRepository.deleteSubtask(id: id)
        loadSubtasks()
        try syncParentAfterDelete()
    }

    /// When subtasks exist, parent completion matches whether all are completed.
    private func syncParentCompletionWhenHasSubtasks() throws {
        let subs = try subtaskRepository.fetchSubtasks(taskId: taskId)
        guard !subs.isEmpty else { return }
        let allDone = subs.allSatisfy(\.isCompleted)
        guard var task = try taskRepository.task(id: taskId) else { return }
        guard task.isCompleted != allDone else { return }
        task.isCompleted = allDone
        try taskRepository.save(task)
    }

    private func syncParentAfterDelete() throws {
        let subs = try subtaskRepository.fetchSubtasks(taskId: taskId)
        guard !subs.isEmpty else { return }
        let allDone = subs.allSatisfy(\.isCompleted)
        guard var task = try taskRepository.task(id: taskId) else { return }
        guard task.isCompleted != allDone else { return }
        task.isCompleted = allDone
        try taskRepository.save(task)
    }
}

enum SubtaskViewModelError: Error {
    case titleRequired
}
