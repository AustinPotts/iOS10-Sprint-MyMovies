//
//  MovieController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData


enum HTTPMethod: String{
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}


class MovieController {
    
    //MARK: - URL's
    
    private let apiKey = "4cc920dab8b729a619647ccc4d191d5e"
    private let baseURL = URL(string: "https://api.themoviedb.org/3/search/movie")!
    let firebaseURL = URL(string: "https://movies-f2bd9.firebaseio.com")!
    
    
    
    //MARK: - Networking Fetch
    
    func searchForMovie(with searchTerm: String, completion: @escaping (Error?) -> Void) {
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        
        let queryParameters = ["query": searchTerm,
                               "api_key": apiKey]
        
        components?.queryItems = queryParameters.map({URLQueryItem(name: $0.key, value: $0.value)})
        
        guard let requestURL = components?.url else {
            completion(NSError())
            return
        }
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error searching for movie with search term \(searchTerm): \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                completion(NSError())
                return
            }
            
            do {
                let movieRepresentations = try JSONDecoder().decode(MovieRepresentations.self, from: data).results
                self.searchedMovies = movieRepresentations
                completion(nil)
            } catch {
                NSLog("Error decoding JSON data: \(error)")
                completion(error)
            }
        }.resume()
    }
    
    // MARK: - Properties
    
    var searchedMovies: [MovieRepresentation] = []
    
    
    
    // MARK: - CRUD MEthods
    
    func createMovie(with title: String, hasWatched: Bool, context: NSManagedObjectContext){
        
       let movie = Movie(title: title, hasWatched: true, context: context)
        CoreDataStack.share.save()
        put(movie: movie)
        
    }
    
    func updateMovie(movie: Movie, title: String, hasWatched: Bool){
        
        movie.title = title
        movie.hasWatched = true
        CoreDataStack.share.save()
        put(movie: movie)
    }
    
    
    func delete(movie: Movie) {
        CoreDataStack.share.mainContext.delete(movie)
        CoreDataStack.share.save()
    }
    
    
    //MARK: Cloud Sync Methods
    
    //Fetch any movie from the server
    func fetchMovieFromServer(completion: @escaping()-> Void = {}) {
        
        
        
        let requestURL = firebaseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error{
                NSLog("error fetching movie: \(error)")
                completion()
            }
            
            guard let data = data else{
                NSLog("Error getting data movie:")
                completion()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                
                let movieRepresentations = Array(try decoder.decode([String: MovieRepresentation].self, from: data).values)
                
                self.updateFirebaseMovie(with: movieRepresentations)
                
                
                
            } catch {
                NSLog("Error decoding: \(error)")
              }
            }.resume()
    }
    
    //Update any Movie on the server
    
    func updateFirebaseMovie(with representation: [MovieRepresentation]) {
        
        let identifiersToFetch = representation.map({ $0.identifier }) //Grab the first identifier
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, representation))
        var movieToCreate = representationsByID
        
        //Creating Background Context for Thread Safety
        let context = CoreDataStack.share.container.newBackgroundContext()
        
        context.performAndWait {
            
            do {
                
                let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
                //Name of Attibute
                fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
                
                //Which of these Movies already exist in core data?
                let exisitingMovie = try context.fetch(fetchRequest)
                
                //Which need to be updated? Which need to be put into core data?
                for movie in exisitingMovie {
                    guard let identifier = movie.identifier,
                        // This gets the Movie representation that corresponds to the Movie from Core Data
                        let representation = representationsByID[identifier] else{return}
                    
                    movie.title = representation.title
                    movie.hasWatched = representation.hasWatched ?? true
                    
                    movieToCreate.removeValue(forKey: identifier)
                    
                }
                //Take these Movies that arent in core data and create
                for representation in movieToCreate.values{
                    Movie(movieRepresentation: representation, context: context)
                }
                
                CoreDataStack.share.save(context: context)
                
            } catch {
                NSLog("Error fetching tasks from persistent store: \(error)")
            }
            
        }
        
    }
    
    //Put Movie to Server
    func put(movie: Movie, completion: @escaping()-> Void = {}) {
        
        let identifier = movie.identifier ?? UUID()
        movie.identifier = identifier
        
        let requestURL = firebaseURL.appendingPathComponent(identifier.uuidString).appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.put.rawValue
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let movieRepresentation = movie.movieRepresentation else{
            NSLog("Error")
            completion()
            return
        }
        
        do{
            request.httpBody = try JSONEncoder().encode(movieRepresentation)
        } catch {
            NSLog("Error encoding movie: \(error)")
            completion()
            return
        }
        
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            if let error = error{
                NSLog("Error putting movie: \(error)")
                completion()
                return
            }
            completion()
            }.resume()
        
    }
    
    
    
}
