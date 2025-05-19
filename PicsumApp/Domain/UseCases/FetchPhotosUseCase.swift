//
//  FetchPhotosUseCase.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//

import Foundation


protocol FetchPhotosUseCaseProtocol {
    func execute(page: Int, limit: Int, completion: @escaping (Result<[Photo], Error>) -> Void)
}

final class FetchPhotosUseCase: FetchPhotosUseCaseProtocol {
    private let photoRepository: PhotoRepositoryProtocol
    private let storageRepository: PhotoStorageRepositoryProtocol
    
    init(
        repository: PhotoRepositoryProtocol,
        storageRepository: PhotoStorageRepositoryProtocol
    ) {
        self.photoRepository = repository
        self.storageRepository = storageRepository
    }
    
    func execute(page: Int, limit: Int, completion: @escaping (Result<[Photo], any Error>) -> Void) {
        storageRepository.fetchPhotos(page: page, limit: limit) { result in
                    switch result {
                    case .success(let photos):
                        completion(.success(photos))
                    case .failure:
                        completion(.failure(StorageError.invalidData))
                        print("Local fetch failed")
                    }
        }
    }

}


