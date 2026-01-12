//
//  fetch.swift
//  swiftdata
//
//  Created by Dheeraj on 03/01/26.
//

import Foundation

//struct SearchResult: indetifibiable, codable {
//    let numFound: Int
//    
//    let docs: [BookDoc]
//}

class OpenLibraryService {
    func searchBooks(query: String) async throws -> SearchResult {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://openlibrary.org/search.json?q=\(encoded)")!

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(SearchResult.self, from: data)
        return result
    }
}
