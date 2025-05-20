//
//  ImageLoader.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 18/5/25.
//
import Foundation
import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    private let operationQueue: OperationQueue
    private let operations: ThreadSafeDictionary<String, ImageLoaderOperation> = ThreadSafeDictionary()
    private let cacheManager = ImageCacheManager.shared
    
    private init() {
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 10
        self.operationQueue.qualityOfService = .userInteractive
        self.operationQueue.name = "com.bn2002.picsum.imageLoader"
    }
    
    func loadImage(from url: URL, completion: @escaping (Data?) -> Void) -> String {
        let taskId = UUID().uuidString
        
        if let cachedData = self.cacheManager.getImage(for: url) {
            completion(cachedData)
            return UUID().uuidString
        }
        
        let operation = ImageLoaderOperation(url: url) { [weak self] image in
            guard let `self` = self else { return }

            DispatchQueue.main.async {
                completion(image)
            }
            
            if let data = image {
                DispatchQueue.global().async { [weak self] in
                    self?.cacheManager.setImage(data, for: url)
                }
            }
            self.removeOperation(for: taskId)
        }
        
        self.addOperation(operation, for: taskId)
        self.operationQueue.addOperation(operation)
        return taskId
    }
    
    func cancelAllOperations() {
        self.operationQueue.cancelAllOperations()
    }
    
    func cancelTask(with taskId: String) {
        if let operation = self.operations[taskId] {
            operation.cancel()
            self.removeOperation(for: taskId)
        }
    }
    
    func addOperation(_ operation: ImageLoaderOperation, for taskId: String) {
        self.operations[taskId] = operation
    }
    
    func removeOperation(for taskId: String) {
        self.operations.removeValue(forKey: taskId)
    }
}

final class ImageLoaderOperation: Operation {
    private let url: URL
    private let completion: (Data?) -> Void
    private var dataTask: URLSessionDataTask?
    
    init(url: URL, completion: @escaping (Data?) -> Void, dataTask: URLSessionDataTask? = nil) {
        self.url = url
        self.completion = completion
        super.init()
    }
    
    override func main() {
        guard !self.isCancelled else { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        print("Loading image from: \(url)")
        self.dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard
                let `self` = self,
                !isCancelled,
                error == nil,
                let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode),
                let data = data,
                data.isEmpty == false
            else {
                self?.completion(nil)
                semaphore.signal()
                return
            }
            
            self.completion(data)
            semaphore.signal()
        }
        self.dataTask?.resume()
        semaphore.wait()
    }
    
    override func cancel() {
        super.cancel()
        self.dataTask?.cancel()
    }
}
    
