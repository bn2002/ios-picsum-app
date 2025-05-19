//
//  SearchTextValidator.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import Foundation

final class SearchTextValidator {
    static let shared = SearchTextValidator()
    
    private let allowedCharacters: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*():.,<>/\\[]? "
    
    let maxLength = 15
    
    func cleanSearchText(_ text: String) -> String {
        var cleanedText = text.removeDiacritic()
        cleanedText = cleanedText.filter { allowedCharacters.contains($0) }
        
        return cleanedText
    }
    
}
