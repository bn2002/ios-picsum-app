//
//  ImageCacheManagerTests.swift
//  PicsumAppTests
//
//  Created by Doanh on 20/5/25.
//

import XCTest
@testable import PicsumApp

final class ImageCacheManagerTests: XCTestCase {
    var imageCacheManager: ImageCacheManager!
    var memoryCache: MemoryImageCache!
    var diskCache: DiskImageCache!
    let testURL = URL(string: "https://picsum.photos/id/20/3670/2462")!
    var dataTest: Data!

    override func setUp() async throws {
        try await super.setUp()
        let (data, _) = try await URLSession.shared.data(from: testURL, delegate: nil)
        self.dataTest = data
        self.memoryCache = MemoryImageCache(maxSize: 100)
        self.diskCache = DiskImageCache()
        self.imageCacheManager = ImageCacheManager(cacheProviders: [self.memoryCache, self.diskCache])
        self.imageCacheManager.clearCache()
    }
    
    override func tearDown() {
        self.imageCacheManager.clearCache()
        self.imageCacheManager = nil
        super.tearDown()
    }
    
    func testCacheHit() {
        XCTAssertNotNil(dataTest)
        self.imageCacheManager.setImage(dataTest, for: testURL)
        let cachedData = self.imageCacheManager.getImage(for: testURL)
        XCTAssertNotNil(cachedData)
        XCTAssertEqual(dataTest, cachedData)
    }

    func testCacheHit_MemoryCache() {
        XCTAssertNotNil(dataTest)
        self.memoryCache.setImage(dataTest, for: testURL.absoluteString)
        let cachedData = self.memoryCache.getImage(for: testURL.absoluteString)
        XCTAssertNotNil(cachedData)
        XCTAssertEqual(dataTest, cachedData)
    }
    
    func testCacheHit_DiskCache() {
        XCTAssertNotNil(dataTest)
        self.diskCache.setImage(dataTest, for: testURL.absoluteString)
        let cachedData = self.diskCache.getImage(for: testURL.absoluteString)
        XCTAssertNotNil(cachedData)
        XCTAssertEqual(dataTest, cachedData)
    }
    
    func testPromotionFromDiskToMemory() {
        XCTAssertNotNil(dataTest)
        
        // Set image in DiskCache
        self.diskCache.setImage(dataTest, for: testURL.absoluteString)
        
        // Get image from ImageCacheManager
        let cachedData = self.imageCacheManager.getImage(for: testURL)
        XCTAssertNotNil(cachedData)
        
        // Create expectation with delay
        let delayExpectation = expectation(description: "Delay for promotion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            delayExpectation.fulfill()
        }
            
        // Wait for delay
        wait(for: [delayExpectation], timeout: 2.0)
        
        // Check if the image was promoted to MemoryCache
        let memoryCachedData = self.memoryCache.getImage(for: testURL.absoluteString)
        XCTAssertNotNil(memoryCachedData)
        XCTAssertEqual(dataTest, memoryCachedData)
    }
    
    func testClearCache() async throws {
        self.imageCacheManager.setImage(dataTest, for: testURL)
        self.imageCacheManager.clearCache()
        let cachedData = self.imageCacheManager.getImage(for: testURL)
        XCTAssertNil(cachedData)
    }
}
