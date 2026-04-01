//
//  SubtaskEntity+CoreDataProperties.swift
//  
//
//  Created by Tran Minh Tien on 1/4/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias SubtaskEntityCoreDataPropertiesSet = NSSet

extension SubtaskEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SubtaskEntity> {
        return NSFetchRequest<SubtaskEntity>(entityName: "SubtaskEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var title: String?
    @NSManaged public var task: TaskEntity?

}

extension SubtaskEntity : Identifiable {

}
