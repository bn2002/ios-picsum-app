//
//  Collection+Extensions.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 18/5/25.
//

extension Collection {
    // Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
