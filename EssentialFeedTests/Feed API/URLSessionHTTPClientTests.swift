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
    func test_getFromUrl_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "fake.com")!
        let error = NSError(domain: "Test Error", code: 0)
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: error)
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "Wait for completion")
        
        sut.get(from: url) { result in
            switch result {
            case let .failure(capturedError as NSError):
                XCTAssertEqual(error.domain, capturedError.domain)
            default:
                XCTFail("Expected \(error) but got \(result) instead.")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequests()
    }
    
   
    
    //MARK: Helpers
    
    private class URLProtocolStub: URLProtocol {
        static var stubs = [URL: Stub]()
        
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
        }

        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error?) {
            stubs[url] = Stub(data: data, response: response, error: error)
        }
        
        class override  func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else {
                return false
            }
            return stubs[url] != nil
        }
        
        class override func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        
        override func startLoading() {
            guard let url = request.url,
                  let stub = URLProtocolStub.stubs[url] else {
                return
            }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
