import CoreData
import Foundation

extension SubtaskEntity {
    func toDomain() -> Subtask {
        Subtask(
            id: id ?? UUID(),
            taskId: task?.id ?? UUID(),
            title: title ?? "",
            isCompleted: isCompleted
        )
    }

    func update(from item: Subtask, taskEntity: TaskEntity) {
        id = item.id
        title = item.title
        isCompleted = item.isCompleted
        task = taskEntity
    }
}
