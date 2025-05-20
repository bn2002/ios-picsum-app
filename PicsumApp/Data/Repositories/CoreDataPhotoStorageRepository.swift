//
//  CoreDataPhotoStorage.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import Foundation
import CoreData

final class CoreDataPhotoStorageRepository: PhotoStorageRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let expirationInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }
    
    func isDataValid() -> Bool {
        guard let lastUpdate = self.getLastUpdateTime() else {
            return false
        }
        
        let now = Date()
        return now.timeIntervalSince(lastUpdate) < expirationInterval
    }
    
    func savePhotos(_ photos: [Photo], completion: @escaping (Result<Void, StorageError>) -> Void) {
        let context = self.coreDataStack.newBackgroundContext()
        
        context.perform {
            do {
                // Clear existing data
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = PhotoEntity.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try context.execute(deleteRequest)
                
                // Insert new data
                photos.forEach { photo in
                    let entity = PhotoEntity(context: context)
                    entity.id = Int32(photo.id) ?? 0
                    entity.author = photo.author
                    entity.width = Int32(photo.width)
                    entity.height = Int32(photo.height)
                    entity.url = photo.url
                    entity.downloadURL = photo.downloadURL
                    entity.timestamp = Date()
                }
                
                try context.save()
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.saveError))
                }
            }
        }
    }
    
    func fetchPhotos(
        page: Int,
        limit: Int,
        completion: @escaping (Result<[Photo], StorageError>) -> Void
    ) {
        let context = self.coreDataStack.newBackgroundContext()
        
        context.perform {
            do {
                let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                
                fetchRequest.fetchOffset = (page - 1) * limit
                fetchRequest.fetchLimit = limit
                
                let entities = try context.fetch(fetchRequest)
                var photos: [Photo] = []
                entities.forEach { entity in
                    guard
                        let url = entity.url,
                        let downloadURL = entity.downloadURL
                    else { return }
                            
                    let photo = Photo(
                        id: "\(entity.id)",
                        author: entity.author ?? "",
                        width: Int(entity.width),
                        height: Int(entity.height),
                        url: url,
                        downloadURL: downloadURL
                    )
                    photos.append(photo)
                    
                }
                
                DispatchQueue.main.async {
                    completion(.success(photos))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.fetchError))
                }
            }
        }
    }
    
    func searchPhotos(
        query: String,
        page: Int,
        limit: Int,
        completion: @escaping (Result<[Photo], StorageError>) -> Void
    ) {
        let context = self.coreDataStack.newBackgroundContext()

        context.perform {
            do {
                let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                // Check if query contains only numbers
                let isNumeric = query.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
                
                if isNumeric {
                    // Search by exact ID match
                    fetchRequest.predicate = NSPredicate(format: "id == %d", Int32(query) ?? 0)
                } else {
                    // Search by author name (case-insensitive, contains)
                    fetchRequest.predicate = NSPredicate(format: "author CONTAINS[cd] %@", query)
                }
                
                // Add pagination
                fetchRequest.fetchOffset = (page - 1) * limit
                fetchRequest.fetchLimit = limit
                
                let entities = try context.fetch(fetchRequest)
                let photos = entities.compactMap { entity -> Photo? in
                    guard
                        let url = entity.url,
                        let downloadURL = entity.downloadURL
                    else { return nil }
                    
                    return Photo(
                        id: "\(entity.id)",
                        author: entity.author ?? "",
                        width: Int(entity.width),
                        height: Int(entity.height),
                        url: url,
                        downloadURL: downloadURL
                    )
                }
                
                DispatchQueue.main.async {
                    completion(.success(photos))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.fetchError))
                }
            }
        }
    }
    
    func clearAll(completion: @escaping (Result<Void, StorageError>) -> Void) {
        let context = self.coreDataStack.newBackgroundContext()
        
        context.perform {
            do {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = PhotoEntity.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try context.execute(deleteRequest)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.saveError))
                }
            }
        }
    }
    
    func getLastUpdateTime() -> Date? {
        let context = self.coreDataStack.mainContext
        
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first?.timestamp
        } catch {
            return nil
        }
    }
}


extension Photo {
    init(entity: PhotoEntity) {
        self.id = "\(entity.id)"
        self.author = entity.author ?? ""
        self.width = Int(entity.width)
        self.height = Int(entity.height)
        self.url = entity.url ?? URL(string: "https://picsum.photos/0/200/300")!
        self.downloadURL = entity.downloadURL ?? URL(string: "https://picsum.photos/0/200/300")!
    }
}
