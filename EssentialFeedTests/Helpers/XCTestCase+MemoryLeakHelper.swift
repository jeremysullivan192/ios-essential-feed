//
//  XCTTestCase+MemoryLeakHelper.swift
//  EssentialFeedTests
//
//  Created by jsullivan on 8/23/22.
//

import Foundation
import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "instance should have been deallocated. Potential memory leak", file: file, line: line)
        }
    }
}
