//
//  String+Extensions.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import Foundation

extension String {
    func removeDiacritic() -> String {
        // Convert to latin: Â -> A, Ê -> E, Ô -> O
        let toLatin = applyingTransform(.toLatin, reverse: false) ?? self
        // Remove combining marks: Ạ -> A, Ả -> A, Ấ -> A
        let noMarks = toLatin.applyingTransform(.stripCombiningMarks, reverse: false) ?? toLatin
        // Replace Đ -> D, đ -> d
        return noMarks
            .replacingOccurrences(of: "Đ", with: "D")
            .replacingOccurrences(of: "đ", with: "d")
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespaces)
    }
}
