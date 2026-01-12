//
//  book.swift
//  swiftdata
//
//  Created by Dheeraj on 30/12/25.
// created by dj

import Foundation
import SwiftData

@Model
class Book {
    var title: String
    var author: String
    var genre: String
    var review: String
    var rating: Int
    var coverImageURL: String?
    var coverImageData: Data?  // Local storage for cover image
    var publishYear: Int?
    var openLibraryKey: String?
    
    init(title: String, author: String, genre: String, review: String = "", rating: Int = 0, coverImageURL: String? = nil, coverImageData: Data? = nil, publishYear: Int? = nil, openLibraryKey: String? = nil) {
        self.title = title
        self.author = author
        self.genre = genre
        self.review = review
        self.rating = rating
        self.coverImageURL = coverImageURL
        self.coverImageData = coverImageData
        self.publishYear = publishYear
        self.openLibraryKey = openLibraryKey
    }
}
