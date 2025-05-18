//
//  FetchPhotosUseCase.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//

import Foundation

protocol FetchPhotosUseCaseProtocol {
    @discardableResult
    func execute(page: Int, limit: Int, completion: @escaping (Result<[Photo], Error>) -> Void) -> URLSessionDataTask?
}

final class FetchPhotosUseCase: FetchPhotosUseCaseProtocol {
    private let repository: PhotoRepositoryProtocol
    
    init(repository: PhotoRepositoryProtocol) {
        self.repository = repository
    }
    
    @discardableResult
    func execute(page: Int, limit: Int, completion: @escaping (Result<[Photo], any Error>) -> Void) -> URLSessionDataTask? {
        return repository.fetchPhotos(page: page, limit: limit, completion: completion)
    }

}


