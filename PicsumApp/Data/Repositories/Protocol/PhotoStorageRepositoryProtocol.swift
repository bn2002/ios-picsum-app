//
//  PhotoStorageRepository.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import Foundation

enum StorageError: Error {
    case saveError
    case fetchError
    case invalidData
}


protocol PhotoStorageRepositoryProtocol {
    // Check is data valid(last time fetch)
    func isDataValid() -> Bool
    
    // Save photo to storage
    func savePhotos(_ photos: [Photo], completion: @escaping (Result<Void, StorageError>) -> Void)
    
    // Fetch photo from storage
    func fetchPhotos(completion: @escaping (Result<[Photo], StorageError>) -> Void)
    
    // Remove all photos from storage
    func clearAll(completion: @escaping (Result<Void, StorageError>) -> Void)
    
    // Get last time fetch
    func getLastUpdateTime() -> Date?
}
