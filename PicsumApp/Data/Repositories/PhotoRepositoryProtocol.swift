//
//  PhotoRepositoryProtocol.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//
import Foundation

protocol PhotoRepositoryProtocol {
    func fetchPhotos(page: Int, limit: Int, completion: @escaping (Result<[Photo], Error>) -> Void) -> URLSessionDataTask?
}
