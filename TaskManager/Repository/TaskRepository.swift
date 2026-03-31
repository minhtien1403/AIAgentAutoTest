import CoreData
import Foundation

protocol TaskRepositoryProtocol: AnyObject {
    func fetchAll() throws -> [Task]
    func save(_ task: Task) throws
    func delete(id: UUID) throws
    func task(id: UUID) throws -> Task?
}

final class TaskRepository: TaskRepositoryProtocol, @unchecked Sendable {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = StorageService.shared.viewContext) {
        self.context = context
    }

    func fetchAll() throws -> [Task] {
        let request = TaskEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
        ]
        let results = try context.fetch(request)
        return results.map { $0.toDomain() }
    }

    func save(_ task: Task) throws {
        let request = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        request.fetchLimit = 1
        let entity: TaskEntity
        if let existing = try context.fetch(request).first {
            entity = existing
        } else {
            entity = TaskEntity(context: context)
        }
        entity.update(from: task)
        try context.save()
    }

    func delete(id: UUID) throws {
        let request = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }

    func task(id: UUID) throws -> Task? {
        let request = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first?.toDomain()
    }
}
