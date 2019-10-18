//
//  CoreDataStack.swift
//  MyMovies
//
//  Created by Austin Potts on 10/18/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import CoreData


class CoreDataStack {
    
    static let share = CoreDataStack()
    
    private init() {
        
    }
    
    //Create Code Snippet
    lazy var container: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "Movies")
        
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error {
                fatalError("Error loading Persistent Stores: \(error)")
            }
        })
        return container
    }() // Creating only one instance for use
    
    var mainContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func saveToPersistentStore() {
        do{
            try mainContext.save()
        } catch {
            NSLog("Error saving context \(error)")
            mainContext.reset()
        }
    }
    
    
}
