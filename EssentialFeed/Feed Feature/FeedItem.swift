//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by jsullivan on 8/8/22.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let url: URL
}
