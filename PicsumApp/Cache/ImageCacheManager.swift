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
    
    private let cacheProviders: [ImageCacheProtocol]
    
    private init() {
        self.cacheProviders = [
            MemoryImageCache(maxSize: 100),
            DiskImageCache()
        ]
    }
    
    func getImage(for url: URL) -> Data? {
        let key = url.absoluteString
        for provider in self.cacheProviders {
            if let image = provider.getImage(for: key) {
                print("\(provider.identifier) Hit Cache: \(key)")
                return image
            }
        }
        print("Miss cache: \(key)")
        return nil
    }
    
    func setImage(_ image: Data, for url: URL) {
        let key = url.absoluteString
        print("Save cache: \(key)")
        for provider in self.cacheProviders {
            provider.setImage(image, for: key)
        }
    }
    
    func removeImage(for url: URL) {
        let key = url.absoluteString
        for provider in self.cacheProviders {
            provider.removeImage(for: key)
        }
    }
       
    func clearCache() {
        for provider in self.cacheProviders {
            provider.clear()
        }
    }
}
