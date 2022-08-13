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
    let url: URL
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load(){
        client.get(from: url)
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
        _ = RemoteFeedLoader(url: URL(string: "test.com")!, client: client)
                
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromUrl() {
        let url = URL(string: "loadit.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
        
    }
}
