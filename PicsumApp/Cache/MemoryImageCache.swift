//
//  MemoryImageCache.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 19/5/25.
//
import Foundation
import UIKit

class MemoryImageCache: ImageCacheProtocol {
    private let cache = NSCache<NSString, NSData>()
    let identifier: String = "MemoryImageCache"
    
    init(maxSize: Int = 30) {
        self.cache.totalCostLimit = maxSize * 1024 * 1024 // MB
    }
    
    func getImage(for key: String) -> Data? {
        let data = self.cache.object(forKey: NSString(string: key))
        if let data = data as? Data {
            return data
        }
        return nil
    }
    
    func setImage(_ image: Data, for key: String) {
        self.cache.setObject(image as NSData, forKey: NSString(string: key))
    }
    
    func removeImage(for key: String) {
        self.cache.removeObject(forKey: NSString(string: key))
    }
    
    func clear() {
        self.cache.removeAllObjects()
    }
    
}
