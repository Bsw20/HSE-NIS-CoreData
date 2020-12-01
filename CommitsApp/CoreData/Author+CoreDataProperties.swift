//
//  Author+CoreDataProperties.swift
//  CommitsApp
//
//  Created by Ярослав Карпунькин on 01.12.2020.
//
//

import Foundation
import CoreData


extension Author {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<Author> {
        return NSFetchRequest<Author>(entityName: "Author")
    }

    @NSManaged public var email: String
    @NSManaged public var name: String
    @NSManaged public var relationship: NSSet

}

// MARK: Generated accessors for relationship
extension Author {

    @objc(addRelationshipObject:)
    @NSManaged public func addToRelationship(_ value: Commit)

    @objc(removeRelationshipObject:)
    @NSManaged public func removeFromRelationship(_ value: Commit)

    @objc(addRelationship:)
    @NSManaged public func addToRelationship(_ values: NSSet)

    @objc(removeRelationship:)
    @NSManaged public func removeFromRelationship(_ values: NSSet)

}

extension Author : Identifiable {

}
