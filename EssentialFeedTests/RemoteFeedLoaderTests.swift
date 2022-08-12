//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by jsullivan on 8/12/22.
//

import Foundation
import XCTest

class RemoteFeedLoader {
}

class HTTPClient {
    var requestedURL: URL?
}
class RemoteFeedLoaderTests: XCTestCase {
    func test_init() {
        let client = HTTPClient()
        _ = RemoteFeedLoader()
                
        XCTAssertNil(client.requestedURL)
    }
}
