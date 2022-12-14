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
        expect(sut, toCompleteWith: failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.completeWith(error: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                let data = makeItemsJSON([])
                client.completeWith(statusCode: code, data: data, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJson() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData)) {
            let invalidJson = Data("invalid json".utf8)
            client.completeWith(statusCode: 200, data: invalidJson)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            let emptyListJson = makeItemsJSON([])
            client.completeWith(statusCode: 200, data: emptyListJson)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponsewithJSONItems() {
        let (sut, client) = makeSUT()

        let item1 = makeItem()
        
        let item2 = makeItem(
            description: "description",
            location: "location",
            imageURL: RemoteFeedLoaderTests.testURL.appendingPathComponent("another")
        )
        
        let items = [item1.model, item2.model]
        expect(sut, toCompleteWith: .success(items)) {
            let json = makeItemsJSON([item1.json, item2.json])
            client.completeWith(statusCode: 200, data: json)
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: RemoteFeedLoaderTests.testURL, client: client)
     
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.completeWith(statusCode: 200, data: makeItemsJSON([]))
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    //MARK: Helper Methods
    
    private func failure(_ failure: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(failure)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = [ "items": items ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeItem(id: UUID = UUID(), description: String? = nil, location: String? = nil, imageURL: URL = testURL) -> (model: FeedItem, json: [String: Any]) {
        
        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
        
        let itemJSON = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0?.description }
        
        return (item, itemJSON)
        
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { capturedResult in
            switch (capturedResult, expectedResult) {
            case let (.success(capturedItems), .success(expectedItems)):
                XCTAssertEqual(capturedItems, expectedItems, file: file, line: line)
            case let (.failure(capturedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(capturedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got captured result: \(capturedResult)", file: file, line: line)
            }
            exp.fulfill()
        }
    
        action()
        wait(for: [exp], timeout: 1.0)
    }
                             
    static let testURL = URL(string: "test.com")!
    
    private func makeSUT(url: URL = testURL, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)
        return (sut, client)
    }
    
    class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((from, completion))
        }
        
        func completeWith(error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        func completeWith(statusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
