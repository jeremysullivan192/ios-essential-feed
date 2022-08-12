//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by jsullivan on 8/8/22.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
