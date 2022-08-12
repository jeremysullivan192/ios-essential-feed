//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by jsullivan on 8/12/22.
//

import Foundation
import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load(){
        client.get(from: URL(string: "url.com")!)
    }
}

protocol HTTPClient {
    func get(from: URL)
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    func get(from: URL) {
        requestedURL = from
    }
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)
                
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromUrl() {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client)
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
        
    }
}
