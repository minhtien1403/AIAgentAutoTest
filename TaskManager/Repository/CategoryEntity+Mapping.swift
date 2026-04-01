import CoreData
import Foundation

extension CategoryEntity {
    func toDomain() -> Category {
        Category(
            id: id ?? UUID(),
            name: name ?? "",
            color: color ?? "#007AFF"
        )
    }

    func update(from item: Category) {
        id = item.id
        name = item.name
        color = item.color
    }
}
