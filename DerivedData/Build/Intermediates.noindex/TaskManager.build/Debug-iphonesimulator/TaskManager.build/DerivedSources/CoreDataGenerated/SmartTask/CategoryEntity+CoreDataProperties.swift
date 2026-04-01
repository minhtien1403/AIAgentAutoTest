//
//  CategoryEntity+CoreDataProperties.swift
//  
//
//  Created by Tran Minh Tien on 1/4/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias CategoryEntityCoreDataPropertiesSet = NSSet

extension CategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }

    @NSManaged public var color: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?

}

extension CategoryEntity : Identifiable {

}
