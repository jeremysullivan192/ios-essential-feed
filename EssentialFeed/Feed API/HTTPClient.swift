//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by jsullivan on 8/19/22.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from: URL, completion: @escaping (HTTPClientResult) -> Void)
}
