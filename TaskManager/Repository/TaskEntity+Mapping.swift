import CoreData
import Foundation

extension TaskEntity {
    func toDomain() -> Task {
        let status: TaskStatus
        if let raw = taskStatusRaw, let parsed = TaskStatus(rawValue: raw) {
            status = parsed
        } else {
            status = isCompleted ? .done : .todo
        }
        let completed = (status == .done)
        return Task(
            id: id ?? UUID(),
            title: title ?? "",
            description: details,
            priority: Priority(rawValue: priorityRaw ?? Priority.medium.rawValue) ?? .medium,
            taskStatus: status,
            dueDate: dueDate,
            isCompleted: completed,
            categoryId: categoryId,
            createdAt: createdAt ?? Date()
        )
    }

    func update(from item: Task) {
        id = item.id
        title = item.title
        details = item.description
        priorityRaw = item.priority.rawValue
        taskStatusRaw = item.taskStatus.rawValue
        dueDate = item.dueDate
        isCompleted = item.taskStatus == .done
        categoryId = item.categoryId
        createdAt = item.createdAt
    }
}
