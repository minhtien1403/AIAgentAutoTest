import CoreData
import Foundation

protocol CategoryRepositoryProtocol: AnyObject {
    func createCategory(_ category: Category) throws
    func deleteCategory(id: UUID) throws
    func fetchCategories() throws -> [Category]
}

final class CategoryRepository: CategoryRepositoryProtocol, @unchecked Sendable {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = StorageService.shared.viewContext) {
        self.context = context
    }

    func fetchCategories() throws -> [Category] {
        let request = CategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)]
        return try context.fetch(request).map { $0.toDomain() }
    }

    func createCategory(_ category: Category) throws {
        let entity = CategoryEntity(context: context)
        entity.update(from: category)
        try context.save()
    }

    func deleteCategory(id: UUID) throws {
        let taskRequest = TaskEntity.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "categoryId == %@", id as CVarArg)
        let tasks = try context.fetch(taskRequest)
        for t in tasks {
            t.categoryId = nil
        }

        let catRequest = CategoryEntity.fetchRequest()
        catRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        catRequest.fetchLimit = 1
        if let entity = try context.fetch(catRequest).first {
            context.delete(entity)
        }
        try context.save()
    }
}
