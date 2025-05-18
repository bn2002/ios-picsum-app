//
//  SearchPhotosUseCase.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//
import Foundation

protocol SearchPhotosUseCaseProtocol {
    func execute(query: String, in photos: [Photo]) -> [Photo]
}

final class SearchPhotosUseCase: SearchPhotosUseCaseProtocol {
    private let maxLength = 15
    
    private lazy var allowedCharset: CharacterSet = {
        var allowedCharset = CharacterSet.alphanumerics
        allowedCharset.formUnion(CharacterSet(charactersIn: "!@#$%^&*():.,<>/\\[]?"))
        
        return allowedCharset
    }()
    
    func execute(query: String, in photos: [Photo]) -> [Photo] {
        let lowercasedQuery = query.lowercased()
        return photos.filter { photo in
            return  photo.author.lowercased().contains(lowercasedQuery) ||
                    photo.id.lowercased().contains(lowercasedQuery)
            
        }
    }
}
