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
        //Adding for multiple MOC
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }() // Creating only one instance for use
    
    var mainContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    //Changing this Standard save to persistence store, to save to the context
    func save(context: NSManagedObjectContext = CoreDataStack.share.mainContext) {
        do{
            try context.save()
        } catch {
            NSLog("Error saving context \(error)")
            context.reset()
        }
    }
    
    
}
