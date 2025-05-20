//
//  SearchPhotosUseCase.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//
import Foundation

protocol SearchPhotosUseCaseProtocol {
    func execute(query: String, page: Int, limit: Int, completion: @escaping ([Photo]) -> Void)
    func cancel()
}

final class SearchPhotosUseCase: SearchPhotosUseCaseProtocol {
    private let storageRepository: PhotoStorageRepositoryProtocol
    private var searchTimer: Timer?
    private let debounceInterval: TimeInterval = 0.3
    
    init(storageRepository: PhotoStorageRepositoryProtocol) {
        self.storageRepository = storageRepository
    }
    
    // MARK: - Public Methods
    func execute(query: String, page: Int, limit: Int, completion: @escaping ([Photo]) -> Void) {
        // Cancel any existing timer
        searchTimer?.invalidate()
        
        // Create a new timer
        self.searchTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { _ in
            self.performSearch(query: query, page: page, limit: limit, completion: completion)
        }
    }
    
    func cancel() {
        self.searchTimer?.invalidate()
        self.searchTimer = nil
    }
    
    // MARK: - Private Methods
    private func performSearch(query: String, page: Int, limit: Int, completion: @escaping ([Photo]) -> Void) {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // If query is empty, fetch all photos
        if query.isEmpty {
            self.storageRepository.fetchPhotos(page: page, limit: limit) { result in
               switch result {
               case .success(let photos):
                   completion(photos)
               case .failure:
                   completion([])
               }
            }
            return
        }
        
        // Perform search
        self.storageRepository.searchPhotos(query: query, page: page, limit: limit) { result in
            switch result {
            case .success(let photos):
                completion(photos)
            case .failure:
                completion([])
            }
        }
    }
    
    deinit {
        self.cancel()
    }
}
