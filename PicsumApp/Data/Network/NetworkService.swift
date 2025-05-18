//
//  NetworkService.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//
import Foundation

enum NetworkError: Error {
    case noData
    case invalidURL
}

final class NetworkService {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }
    
    @discardableResult
    func request<T: Decodable>(url: URL, completion: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
        return task
    }

}
