//
//  ImageCacheManager.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 19/5/25.
//
import Foundation
import UIKit

final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let memoryCache: ImageCacheProtocol
    
    private init() {
        self.memoryCache = MemoryImageCache(maxSize: 100)
    }
    
    func getImage(for url: URL) -> Data? {
        let key = url.absoluteString
        if let image = self.memoryCache.getImage(for: key) {
            print("Hit cache: \(key)")
            return image
        }
        print("Miss cache: \(key)")
        return nil
    }
    
    func setImage(_ image: Data, for url: URL) {
        let key = url.absoluteString
        print("Save cache: \(key)")
        self.memoryCache.setImage(image, for: key)
    }
    
    func removeImage(for url: URL) {
        let key = url.absoluteString
        self.memoryCache.removeImage(for: key)
    }
       
    func clearCache() {
        self.memoryCache.clear()
    }
}
