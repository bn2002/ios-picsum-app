//
//  ImageLoaderTests.swift
//  PicsumAppTests
//
//  Created by Doanh on 20/5/25.
//

import XCTest

import XCTest
@testable import PicsumApp

final class ImageLoaderTests: XCTestCase {
    var imageLoader: ImageLoader!
    var cacheManager: ImageCacheManager!
    
    override func setUp() {
        super.setUp()
        self.imageLoader = ImageLoader.shared
        self.cacheManager = ImageCacheManager.shared
    }
    
    override func tearDown() {
        self.imageLoader.cancelAllOperations()
        super.tearDown()
    }
    
    func testLoadImage_Success() async throws {
        let expectation = self.expectation(description: "Image loaded")
        let testURL = URL(string: "https://picsum.photos/id/20/3670/2462")!
        let (testData, _) = try await URLSession.shared.data(from: testURL, delegate: nil)
        
        let taskId = imageLoader.loadImage(from: testURL) { data in
            XCTAssertNotNil(data)
            XCTAssertEqual(data, testData)
            expectation.fulfill()
        }
        
        XCTAssertNotNil(taskId)
        wait(for: [expectation], timeout: 2)
    }
    
    func testLoadImage_CacheHit() async throws {

        let expectation = self.expectation(description: "Image loaded from cache")
        let testURL = URL(string: "https://picsum.photos/id/20/3670/2462")!
        let (testData, _) = try await URLSession.shared.data(from: testURL, delegate: nil)
        
        self.cacheManager.setImage(testData, for: testURL)

        let taskId = self.imageLoader.loadImage(from: testURL) { data in
            XCTAssertNotNil(data)
            XCTAssertEqual(data, testData)
            expectation.fulfill()
        }

        XCTAssertNotNil(taskId)
        wait(for: [expectation], timeout: 2)
    }
    
    func testLoadImage_Failure() {
        let expectation = self.expectation(description: "Image load failed")
        let testURL = URL(string: "https://picsum.photos/id/2000/3670/2462")!
        let taskId = self.imageLoader.loadImage(from: testURL) { data in
            XCTAssertNil(data)
            expectation.fulfill()
        }
        
        XCTAssertNotNil(taskId)
        waitForExpectations(timeout: 5)
    }
    
    func testCancelTask() {
        let testURL = URL(string: "https://picsum.photos/id/6/1138/758")!
        
        let taskId = self.imageLoader.loadImage(from: testURL) { _ in
            XCTFail("Completion should not be called after cancellation")
        }
        
        self.imageLoader.cancelTask(with: taskId)
        let expectation = self.expectation(description: "Wait for potential completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }
    
    func testCancelAllOperations() {
        let urls = [
            URL(string: "https://picsum.photos/id/20/3670/2462")!,
            URL(string: "https://picsum.photos/id/21/3008/2008")!,
            URL(string: "https://picsum.photos/id/22/4434/3729")!
        ]
        
        urls.forEach { url in
            let _ = self.imageLoader.loadImage(from: url) { _ in
                XCTFail("Completion should not be called after cancellation")
            }
        }
        
        self.imageLoader.cancelAllOperations()
        let expectation = self.expectation(description: "Wait for potential completions")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }
    
    func testConcurrentImageLoading() {
        let expectation = self.expectation(description: "All images loaded")
        expectation.expectedFulfillmentCount = 3
        
        let urls = [
            URL(string: "https://picsum.photos/id/20/3670/2462")!,
            URL(string: "https://picsum.photos/id/21/3008/2008")!,
            URL(string: "https://picsum.photos/id/22/4434/3729")!
        ]
        
        var completedCount = 0
        urls.forEach { url in
            let _ = self.imageLoader.loadImage(from: url) { data in
                // Then
                XCTAssertNotNil(data)
                completedCount += 1
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3)
        XCTAssertEqual(completedCount, 3)
    }
    
    func testLoadImage_InvalidResponse() {
        let expectation = self.expectation(description: "Image load failed")
        let testURL = URL(string: "https://example.com/image.jpg")!
        let _ = self.imageLoader.loadImage(from: testURL) { data in
            XCTAssertNil(data)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }
}
