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
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromUrl_failsOnRequestError() {
        let url = URL(string: "fake.com")!
        let error = NSError(domain: "Test Error", code: 0)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let exp = expectation(description: "Wait for completion")
        
        makeSUT().get(from: url) { result in
            switch result {
            case let .failure(capturedError as NSError):
                XCTAssertEqual(error.domain, capturedError.domain)
            default:
                XCTFail("Expected \(error) but got \(result) instead.")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    
    func test_getFromUrl_performsGetWithURL() {
        
        let url = URL(string: "fake.com")!

        makeSUT().get(from: url) { _ in }
        
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
   
    
    //MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private class URLProtocolStub: URLProtocol {
        static var stub: Stub? = nil
        static var observer: ((URLRequest) -> Void)? = nil

        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(self)
            stub = nil
            observer = nil
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            self.observer = observer
        }
        
        class override  func canInit(with request: URLRequest) -> Bool {
            observer?(request)
            return true
        }
        
        class override func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
