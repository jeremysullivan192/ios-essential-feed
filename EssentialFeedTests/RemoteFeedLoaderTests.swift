//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by jsullivan on 8/12/22.
//

import Foundation
import XCTest
import EssentialFeed


class RemoteFeedLoaderTests: XCTestCase {
    func test_init() {
        let (_, client) = makeSUT()
                
        XCTAssert(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromUrl() {
        let url = URL(string: "loadit.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestDataFromUrlTwice() {
        let url = URL(string: "loadit.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        var capturedErrors = [RemoteFeedLoader.Error]()
        
        sut.load { capturedErrors.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.completeWith(error: clientError)
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        var capturedErrors = [RemoteFeedLoader.Error]()
        
        sut.load { capturedErrors.append($0) }

        client.completeWith(statusCode: 400)
        XCTAssertEqual(capturedErrors, [.invalidData])
    }
    
    private func makeSUT(url: URL = URL(string: "test.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            messages.append((from, completion))
        }
        
        func completeWith(error: Error, at index: Int = 0) {
            messages[index].completion(error, nil)
        }
        func completeWith(statusCode: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            messages[index].completion(nil, response)
        }
    }
}
