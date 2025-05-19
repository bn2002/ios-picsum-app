//
//  InitializePhotosUseCase.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import Foundation

enum InitializeError: Error {
    case networkError(Error)
    case storageError(StorageError)
    case cancelled
}

protocol InitializePhotosUseCaseProtocol {
    // Execute the use case to initialize photos
    func execute(
        force: Bool,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<Void, InitializeError>
    ) -> Void)
    
    // cancel initialization
    func cancel()
}

final class InitializePhotosUseCase: InitializePhotosUseCaseProtocol {
    private let photoRepository: PhotoRepositoryProtocol
    private let storageRepository: PhotoStorageRepositoryProtocol
    private let totalPages = 10
    private let batchSize = 3
    private var isCancelled = false
    private var currentTasks: [URLSessionDataTask] = []
    
    init(photoRepository: PhotoRepositoryProtocol, storageRepository: PhotoStorageRepositoryProtocol) {
        self.photoRepository = photoRepository
        self.storageRepository = storageRepository
    }
    
    func execute(force: Bool, progress: @escaping (Float) -> Void, completion: @escaping (Result<Void, InitializeError>) -> Void) {
        self.isCancelled = false
        self.currentTasks.removeAll()
        
        if(!force && storageRepository.isDataValid()) {
            completion(.success(()))
            return
        }
        
        self.fetchAllPhotos(progess: progress, completion: completion)
    }
    
    func cancel() {
        self.isCancelled = true
        self.currentTasks.forEach { $0.cancel() }
        self.currentTasks.removeAll()
    }
    
    // - MARK: Private methods
    private func fetchAllPhotos(
        progess: @escaping (Float) -> Void,
        completion: @escaping (Result<Void, InitializeError>) -> Void
    ) {
        var allPhotos: [Photo] = []
        var currentBatch = 1
        
        func fetchNextBatch() {
            if self.isCancelled {
                completion(.failure(InitializeError.cancelled))
                return
            }
            
            
            // If all batches are fetched, save the photos to storage
            guard currentBatch <= self.totalPages else {
                self.storageRepository.savePhotos(allPhotos) { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(InitializeError.storageError(error)))
                    }
                }
                return
            }
            
            let endPage = min(currentBatch + self.batchSize - 1, self.totalPages)
            self.fetchBatch(startPage: currentBatch, endPage: endPage) { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let photos):
                    allPhotos.append(contentsOf: photos)
                    
                    // Calculate progress
                    let currentProgress = Float(currentBatch) / Float(self.totalPages)
                    progess(currentProgress)
                    currentBatch = endPage + 1
                    fetchNextBatch()
                case .failure(let error):
                    self.cancel()
                    completion(.failure(InitializeError.networkError(error)))
                }
            }
        }
        
        fetchNextBatch()
    }
    
    private func fetchBatch(
        startPage: Int,
        endPage: Int,
        completion: @escaping (Result<[Photo], Error>) -> Void
    ) {
        var batchPhotos: [Photo] = []
        let group = DispatchGroup()
        var batchError: Error?
        
        for page in startPage...endPage {
            group.enter()
            let task = self.photoRepository.fetchPhotos(page: page, limit: 100) { result in
                switch result {
                case .success(let photos):
                    batchPhotos.append(contentsOf: photos)
                case .failure(let error):
                    batchError = error
                }
                group.leave()
            }
            
            if let task = task {
                self.currentTasks.append(task)
            }
        }
        
        group.notify(queue: .main) {
            if let error = batchError {
                completion(.failure(error))
            } else {
                print("Fetched \(batchPhotos.count) photos from pages \(startPage) to \(endPage)")
                completion(.success(batchPhotos))
            }
        }
    }
    
}
