//
//  Movie+Convenience.swift
//  MyMovies
//
//  Created by Austin Potts on 10/18/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import CoreData



extension Movie {
    
    //MARK: - Computed Property for Model Representation
    
    var movieRepresentation: MovieRepresentation? {
        
        guard let title = title,
            let identifier = identifier else{return nil}
        
        return MovieRepresentation(title: title, identifier: identifier, hasWatched: hasWatched)
        
    }
    
    
    
    //MARK: - Convenience Initializer
    @discardableResult convenience init(title: String, hasWatched: Bool, identifier: UUID = UUID(), context: NSManagedObjectContext){
        
        self.init(context: context)
        
        
        self.title = title
        self.hasWatched = hasWatched
        self.identifier = identifier
        
        
    }
    
    
    //MARK: - Convenience Init for Model Representation
    @discardableResult convenience init?(movieRepresentation: MovieRepresentation, context: NSManagedObjectContext) {
        guard let identifier = movieRepresentation.identifier else{return nil}
        
        self.init(title: movieRepresentation.title, hasWatched: true, identifier: identifier, context:context)
        
    }
    
    
    
}
