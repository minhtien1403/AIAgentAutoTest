import CoreData
import Foundation

protocol SubtaskRepositoryProtocol: AnyObject {
    func createSubtask(_ subtask: Subtask) throws
    func deleteSubtask(id: UUID) throws
    func fetchSubtasks(taskId: UUID) throws -> [Subtask]
    func updateSubtask(_ subtask: Subtask) throws
    func setAllSubtasksCompleted(taskId: UUID, completed: Bool) throws
}

final class SubtaskRepository: SubtaskRepositoryProtocol, @unchecked Sendable {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = StorageService.shared.viewContext) {
        self.context = context
    }

    func fetchSubtasks(taskId: UUID) throws -> [Subtask] {
        let request = SubtaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "task.id == %@", taskId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SubtaskEntity.title, ascending: true)]
        return try context.fetch(request).map { $0.toDomain() }
    }

    func createSubtask(_ subtask: Subtask) throws {
        let taskRequest = TaskEntity.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "id == %@", subtask.taskId as CVarArg)
        taskRequest.fetchLimit = 1
        guard let taskEntity = try context.fetch(taskRequest).first else { return }
        let entity = SubtaskEntity(context: context)
        entity.update(from: subtask, taskEntity: taskEntity)
        try context.save()
    }

    func updateSubtask(_ subtask: Subtask) throws {
        let request = SubtaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", subtask.id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try context.fetch(request).first,
              let taskEntity = entity.task else { return }
        entity.update(from: subtask, taskEntity: taskEntity)
        try context.save()
    }

    func deleteSubtask(id: UUID) throws {
        let request = SubtaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }

    /// Sets completion on all subtasks for a task, then saves.
    func setAllSubtasksCompleted(taskId: UUID, completed: Bool) throws {
        let subs = try fetchSubtasks(taskId: taskId)
        for var s in subs {
            s.isCompleted = completed
            try updateSubtask(s)
        }
    }
}
