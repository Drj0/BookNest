// SearchResult.swift
import Foundation

struct SearchResult: Codable {
    let numFound: Int
    let docs: [BookDoc]

    enum CodingKeys: String, CodingKey {
        case numFound = "num_found"
        case docs
    }
}

struct BookDoc: Codable, Identifiable {
    let key: String
    let title: String?
    let authorName: [String]?

    enum CodingKeys: String, CodingKey {
        case key, title
        case authorName = "author_name"
    }

    var id: String { key }
}
