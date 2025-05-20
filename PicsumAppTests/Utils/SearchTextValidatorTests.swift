//
//  SearchTextValidatorTests.swift
//  PicsumAppTests
//
//  Created by Doanh on 20/5/25.
//

import XCTest
@testable import PicsumApp

final class SearchTextValidatorTests: XCTestCase {
    var validator: SearchTextValidator!
    
    override func setUp() {
        super.setUp()
        self.validator = SearchTextValidator.shared
    }
    
    override func tearDown() {
        self.validator = nil
        super.tearDown()
    }
    
    func testCleanSearchText_WithAllowedCharacters() {
        let input = "Hello123"
        let result = self.validator.cleanSearchText(input)
        XCTAssertEqual(result, input)
    }
    
    func testCleanSearchText_WithSpecialCharacters() {
        let input = "Hello!@#$%^&*():.,<>/\\[]?"
        let result = self.validator.cleanSearchText(input)
        XCTAssertEqual(result, input)
    }
    
    func testCleanSearchText_WithDisallowedCharacters() {
        let input = "Hello{}|+=~`😃"
        let expected = "Hello"
        let result = self.validator.cleanSearchText(input)
        XCTAssertEqual(result, expected)
    }
    
    func testCleanSearchText_WithDiacritics() {
        let inputs = [
            "áéíóú": "aeiou",
            "ñ": "n",
            "ăâđêôơư": "aadeoou",
            "ẮẰẲẴẶ": "AAAAA"
        ]
        
        inputs.forEach { input, expected in
            let result = self.validator.cleanSearchText(input)
            XCTAssertEqual(result, expected, "Failed for input: \(input)")
        }
    }
    
    func testCleanSearchText_WithMixedCharacters() {
        let inputs = [
            "Hello@Thế_Giới": "Hello@TheGioi",
            "Test#123{}: ": "Test#123: ",
            "Xin.Chào/123": "Xin.Chao/123"
        ]
        
        inputs.forEach { input, expected in
            let result = self.validator.cleanSearchText(input)
            XCTAssertEqual(result, expected, "Failed for input: \(input) \(result) expected: \(expected)")
        }
    }
    
    func testCleanSearchText_WithOnlyDisallowedCharacters() {
        let input = "{}|+=~`"
        let result = self.validator.cleanSearchText(input)
        XCTAssertEqual(result, "")
    }
}
