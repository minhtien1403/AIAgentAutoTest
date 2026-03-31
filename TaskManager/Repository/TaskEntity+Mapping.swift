import CoreData
import Foundation

extension TaskEntity {
    func toDomain() -> Task {
        Task(
            id: id ?? UUID(),
            title: title ?? "",
            description: details,
            priority: Priority(rawValue: priorityRaw ?? Priority.medium.rawValue) ?? .medium,
            dueDate: dueDate,
            isCompleted: isCompleted,
            createdAt: createdAt ?? Date()
        )
    }

    func update(from item: Task) {
        id = item.id
        title = item.title
        details = item.description
        priorityRaw = item.priority.rawValue
        dueDate = item.dueDate
        isCompleted = item.isCompleted
        createdAt = item.createdAt
    }
}
