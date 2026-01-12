//
//  SearchViewModel.swift
//  swiftdata
//
//  Created by Dheeraj on 03/01/26.
//


import Combine
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var books: [BookDoc] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let service = OpenLibraryService()

    func search() async {
        guard !query.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await service.searchBooks(query: query)
            books = result.docs
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
