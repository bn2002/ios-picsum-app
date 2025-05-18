//
//  DiskImageCache.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 19/5/25.
//
import Foundation

class DiskImageCache: ImageCacheProtocol{
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.bn2002.picsum.diskCache", attributes: .concurrent)
    private let cacheDirectory: URL
    let identifier: String = "DiskImageCache"
    
    init() {
       let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
       cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
       
       try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func fileURL(for key: String) -> URL {
           return cacheDirectory.appendingPathComponent(key.replacingOccurrences(of: "/", with: "_"))
    }
    
    func getImage(for key: String) -> Data? {
        queue.sync {
            try? Data(contentsOf: fileURL(for: key))
        }
    }
    
    func setImage(_ image: Data, for key: String) {
        queue.async(flags: .barrier) {
            try? image.write(to: self.fileURL(for: key))
        }
    }
    
    func removeImage(for key: String) {
            queue.async(flags: .barrier) {
                try? self.fileManager.removeItem(at: self.fileURL(for: key))
            }
    }
        
    func clear() {
        queue.async(flags: .barrier) {
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            try? self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    
}
