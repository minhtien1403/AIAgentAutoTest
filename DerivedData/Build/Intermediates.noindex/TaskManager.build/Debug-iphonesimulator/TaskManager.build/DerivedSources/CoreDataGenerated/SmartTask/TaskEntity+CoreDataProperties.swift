//
//  TaskEntity+CoreDataProperties.swift
//  
//
//  Created by Tran Minh Tien on 1/4/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias TaskEntityCoreDataPropertiesSet = NSSet

extension TaskEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var categoryId: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var details: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var priorityRaw: String?
    @NSManaged public var title: String?
    @NSManaged public var subtasks: NSSet?

}

// MARK: Generated accessors for subtasks
extension TaskEntity {

    @objc(addSubtasksObject:)
    @NSManaged public func addToSubtasks(_ value: SubtaskEntity)

    @objc(removeSubtasksObject:)
    @NSManaged public func removeFromSubtasks(_ value: SubtaskEntity)

    @objc(addSubtasks:)
    @NSManaged public func addToSubtasks(_ values: NSSet)

    @objc(removeSubtasks:)
    @NSManaged public func removeFromSubtasks(_ values: NSSet)

}

extension TaskEntity : Identifiable {

}
