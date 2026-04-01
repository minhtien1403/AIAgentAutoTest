import Foundation

enum TaskStatus: String, CaseIterable, Codable, Sendable {
    case todo
    case doing
    case done
    case late

    var displayName: String {
        switch self {
        case .todo: return "TODO"
        case .doing: return "DOING"
        case .done: return "DONE"
        case .late: return "LATE"
        }
    }
}

enum Priority: String, CaseIterable, Codable, Sendable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var sortIndex: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
}

struct Task: Equatable, Sendable, Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var priority: Priority
    var taskStatus: TaskStatus
    var dueDate: Date?
    var isCompleted: Bool
    var categoryId: UUID?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        priority: Priority = .medium,
        taskStatus: TaskStatus = .todo,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        categoryId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.taskStatus = taskStatus
        self.dueDate = dueDate
        self.isCompleted = (taskStatus == .done) ? true : isCompleted
        self.categoryId = categoryId
        self.createdAt = createdAt
    }

    /// Updates workflow status and keeps `isCompleted` aligned (`true` only for `.done`).
    mutating func applyTaskStatus(_ newStatus: TaskStatus) {
        taskStatus = newStatus
        isCompleted = (newStatus == .done)
    }

    /// Toggles completion and maps to `.done` / `.todo` for status.
    mutating func toggleCompletionWithStatusSync() {
        if isCompleted {
            isCompleted = false
            if taskStatus == .done { taskStatus = .todo }
        } else {
            isCompleted = true
            taskStatus = .done
        }
    }
}
