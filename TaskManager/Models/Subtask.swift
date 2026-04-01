import Foundation

struct Subtask: Equatable, Sendable, Identifiable {
    let id: UUID
    let taskId: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), taskId: UUID, title: String, isCompleted: Bool = false) {
        self.id = id
        self.taskId = taskId
        self.title = title
        self.isCompleted = isCompleted
    }
}
