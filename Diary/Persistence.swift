//
//  Persistence.swift
//  Diary
//
//  Created by 宋易軒 on 2025/2/18.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "DiaryModel")
        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Failed to load CoreData: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        return container.viewContext
    }
}
