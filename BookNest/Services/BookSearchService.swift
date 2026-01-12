//
//  BookSearchService.swift
//  swiftdata
//
//  Created by Antigravity on 09/01/26.
//

import Foundation
import SwiftUI
import Combine

struct OpenLibrarySearchResponse: Codable {
    let numFound: Int
    let docs: [OpenLibraryBook]
}

struct OpenLibraryBook: Codable, Identifiable {
    let key: String
    let title: String
    let authorName: [String]?
    let firstPublishYear: Int?
    let coverId: Int?
    let subject: [String]?
    
    var id: String { key }
    
    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authorName = "author_name"
        case firstPublishYear = "first_publish_year"
        case coverId = "cover_i"
        case subject
    }
    
    var primaryAuthor: String {
        authorName?.first ?? "Unknown Author"
    }
    
    var coverImageURL: String? {
        guard let coverId = coverId else { return nil }
        return "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
    }
    
    var largeCoverImageURL: String? {
        guard let coverId = coverId else { return nil }
        return "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
    }
    
    var primaryGenre: String {
        let commonGenres = ["Fiction", "Fantasy", "Science Fiction", "Romance", "Mystery", "Thriller", "Horror", "Comedy", "Action", "Biography", "History", "Self-Help"]
        if let subjects = subject {
            for genre in commonGenres {
                if subjects.contains(where: { $0.localizedCaseInsensitiveContains(genre) }) {
                    return genre
                }
            }
            if let first = subjects.first, first.count < 20 {
                return first
            }
        }
        return "General"
    }
}

class BookSearchService: ObservableObject {
    @Published var searchResults: [OpenLibraryBook] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    private var currentTask: URLSessionDataTask?
    
    func searchBooks(query: String) {
        currentTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        
        if trimmedQuery.isEmpty {
            searchResults = []
            hasSearched = false
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        hasSearched = true
        
        guard let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openlibrary.org/search.json?q=\(encodedQuery)&limit=25") else {
            errorMessage = "Invalid search query"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error as? URLError, error.code == .cancelled {
                    return
                }
                
                if error != nil {
                    self.errorMessage = "Network error occurred"
                    self.isLoading = false
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    self.errorMessage = "Server returned error"
                    self.isLoading = false
                    return
                }
                
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(OpenLibrarySearchResponse.self, from: data)
                        self.searchResults = result.docs
                        self.isLoading = false
                    } catch {
                        self.errorMessage = "Failed to parse results"
                        self.isLoading = false
                    }
                } else {
                    self.errorMessage = "No data received"
                    self.isLoading = false
                }
            }
        }
        
        currentTask?.resume()
    }
    
    func cancelSearch() {
        currentTask?.cancel()
        isLoading = false
    }
}
