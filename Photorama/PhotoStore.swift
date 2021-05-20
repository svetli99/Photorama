//
//  PhotoStore.swift
//  Photorama
//
//  Created by Svetlio on 2.05.21.
//

import UIKit
import CoreData

enum PhotoError: Error {
    case imageCreationError
    case missingImageURL
}

class PhotoStore {
    static let shared = PhotoStore()
    let imageStore = ImageStore.shared
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photorama")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error setting up Core Data (\(error)).")
            }
        }
        return container
    }()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    func fetchInterestingPhotos(completion: @escaping (Result<[Photo], Error>) -> Void ) {
        let url = FlickrAPI.interestingPhotosURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) {
            (data, response, error) in

            self.processPhotosRequest(data: data, error: error) { result in
                OperationQueue.main.addOperation {
                    completion(result)
                }
            }
        }
        task.resume()
    }
    
    func fetchImage(for photo: Photo, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let photoKey = photo.photoID else {
            preconditionFailure("Photo expected to have a photoID.")
        }
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        guard let photoURL = photo.remoteURL else {
            completion(.failure(PhotoError.missingImageURL))
            return
        }
        let request = URLRequest(url: photoURL)

        let task = session.dataTask(with: request) {
            (data, response, error) in
            let result = self.processImageRequest(data: data, error: error)
            if case let .success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    private func processPhotosRequest(data: Data?, error: Error?, completion: @escaping (Result<[Photo], Error>) -> Void) {
        guard let jsonData = data else {
            completion(.failure(error!))
            return
        }
        
        persistentContainer.performBackgroundTask { context in
            switch FlickrAPI.photos(fromJSON: jsonData) {
            case let .success(flickrPhotos):
                let setPhotos = Set(self.allPhotos)
                
                flickrPhotos.forEach { photo in
                    if !setPhotos.contains(where: { $0.photoID == photo.photoID }) {
                        var newPhoto: Photo!
                        context.performAndWait {
                            newPhoto = Photo(context: context)
                            newPhoto.title = photo.title
                            newPhoto.photoID = photo.photoID
                            newPhoto.remoteURL = photo.remoteURL
                            newPhoto.dateTaken = photo.dateTaken
                        }
                        self.allPhotos.append(newPhoto)
                    }
                }
                
                do {
                    try context.save()
                } catch {
                    print("Error saving to Core Data: \(error)")
                }
                
                let viewContext = self.persistentContainer.viewContext
                let viewContextPhotos = self.allPhotos.map { viewContext.object(with: $0.objectID) } as! [Photo]
                completion(.success(viewContextPhotos))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func processImageRequest(data: Data?, error: Error?) -> Result<UIImage, Error> {
        guard let imageData = data, let image = UIImage(data: imageData) else {
            if data == nil {
                return .failure(error!)
            } else {
                return .failure(PhotoError.imageCreationError)
            }
        }
        
        return .success(image)
    }
    
    var allPhotos = [Photo]()
    
    func fetchAllPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken),
                                               ascending: true)
        fetchRequest.sortDescriptors = [sortByDateTaken]

        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                self.allPhotos = try viewContext.fetch(fetchRequest)
                completion(.success(self.allPhotos))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchAllTags(completion: @escaping (Result<[Tag], Error>) -> Void) {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        let sortByName = NSSortDescriptor(key: #keyPath(Tag.name), ascending: true)
        fetchRequest.sortDescriptors = [sortByName]

        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allTags = try fetchRequest.execute()
                completion(.success(allTags))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
