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
        let expectedError = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: expectedError)
        XCTAssertEqual(expectedError.domain, receivedError?.domain)
        XCTAssertEqual(expectedError.code, receivedError?.code)
    }
    
    func test_getFromUrl_failsOnInvalidScenarios() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyNonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyNonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyNonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
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
    
    func test_getFromUrl_deliversDataOnRequestSuccess() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        let receivedResponse = resultResponseFor(data: data, response: response, error: nil)
        XCTAssertEqual(data, receivedResponse?.data)
        XCTAssertEqual(response.url, receivedResponse?.response.url)
        XCTAssertEqual(response.statusCode, receivedResponse?.response.statusCode)
    }
    
    func test_getFromUrl_deliversDataWhenDataIsNilAndValidHTTPResponse() {
        let response = anyHTTPURLResponse()
        let receivedResponse = resultResponseFor(data: nil, response: response, error: nil)
        let emptyData = Data()
        XCTAssertEqual(emptyData, receivedResponse?.data)
        XCTAssertEqual(response.url, receivedResponse?.response.url)
        XCTAssertEqual(response.statusCode, receivedResponse?.response.statusCode)
    }
    
   
    
    //MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> NSError? {
        let result = resultFor(data: data, response: response, error: error)

        switch result {
        case let .failure(capturedError as NSError):
            return capturedError
        default:
            XCTFail("Expected \(error) but got \(result) instead.", file: file, line: line)
            return nil
        }
    }
    
    private func resultResponseFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error)
        
        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            XCTFail("Expected \(error) but got \(result) instead.", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let exp = expectation(description: "Wait for completion")
        
        var receivedResult: HTTPClientResult!
        makeSUT().get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    
    private func anyURL() -> URL {
        return URL(string: "fake.com")!
    }
    
    private func anyData() -> Data {
        return Data(count: 1)
    }
    private func anyNSError() -> NSError {
        return NSError(domain: "Test Error", code: 0)
    }
    
    private func anyNonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
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
            return true
        }
        
        class override func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        
        override func startLoading() {
            if let observer = URLProtocolStub.observer {
                client?.urlProtocolDidFinishLoading(self)
                return observer(request)
            }
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
