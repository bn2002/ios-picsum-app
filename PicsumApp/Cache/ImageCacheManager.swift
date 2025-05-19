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
    private let queue = DispatchQueue(label: "com.bn2002.picsum.cacheManager", attributes: .concurrent)
    
    private init() {
        self.cacheProviders = [
            MemoryImageCache(maxSize: 100),
            DiskImageCache()
        ]
    }
    
    func getImage(for url: URL) -> Data? {
        let key = url.absoluteString
        for (index, provider) in self.cacheProviders.enumerated() {
            if let image = provider.getImage(for: key) {
                print("\(provider.identifier) Hit Cache: \(key)")
                if index > 0 {
                    self.promoteToHigherPriorityCaches(data: image, key: key, fromIndex: index)
                }
                return image
            }
        }
        print("Miss cache: \(key)")
        return nil
    }
    
    private func promoteToHigherPriorityCaches(data: Data, key: String, fromIndex: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Promote to higher priority caches
            for index in 0..<fromIndex {
                let provider = self.cacheProviders[index]
                print("Promoting to \(provider.identifier): \(key)")
                provider.setImage(data, for: key)
                return
            }
        }
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
