//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by jsullivan on 8/12/22.
//

import Foundation

public protocol HTTPClient {
    func get(from: URL)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(){
        client.get(from: url)
    }
}
