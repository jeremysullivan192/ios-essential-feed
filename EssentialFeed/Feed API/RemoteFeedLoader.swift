//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by jsullivan on 8/12/22.
//

import Foundation

public protocol HTTPClient {
    func get(from: URL, completion: @escaping (Error) -> Void)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Error) -> Void = { _ in }){
        client.get(from: url) { error in
            completion(.connectivity)
        }
    }
}
