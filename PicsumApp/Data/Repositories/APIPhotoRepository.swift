//
//  APIPhotoRepository.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//
import Foundation

class APIPhotoRepository: PhotoRepositoryProtocol {
    private let network: NetworkService
    private let baseURL = "https://picsum.photos/v2/list"
    
    init(network: NetworkService) {
        self.network = network
    }
    
    func fetchPhotos(page: Int, limit: Int, completion: @escaping (Result<[Photo], any Error>) -> Void) -> URLSessionDataTask? {
        let urlString = "\(baseURL)?page=\(page)&limit=\(limit)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return nil
        }
        
        return self.network.request(url: url, completion: completion)
    }
}
