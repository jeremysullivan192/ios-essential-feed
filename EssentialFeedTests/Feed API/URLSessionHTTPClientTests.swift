//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by jsullivan on 8/19/22.
//

import Foundation
import XCTest
import EssentialFeed

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromUrl_resumesDataTaskWithURL() {
        let url = URL(string: "fake.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromUrl_failsOnRequestError() {
        let url = URL(string: "fake.com")!
        let session = URLSessionSpy()
        let error = NSError(domain: "Test Error", code: 0)
        session.stub(url: url, error: error)
        let sut = URLSessionHTTPClient(session: session)
        
        let exp = expectation(description: "Wait for completion")
        
        sut.get(from: url) { result in
            switch result {
            case let .failure(capturedError as NSError):
                XCTAssertEqual(error, capturedError)
            default:
                XCTFail("Expected \(result) but got \(error) instead.")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: Helpers
    
    private class URLSessionSpy: URLSession {
        var stubs = [URL: Stub]()
        
        struct Stub {
            let task: URLSessionDataTask
            let error: Error?
        }
        
        func stub(url: URL, task: URLSessionDataTask = FakeDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }
        
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
        
        
    }
    
    private class FakeDataTask: URLSessionDataTask {
        override func resume() {
            
        }
    }
    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }

    
}
