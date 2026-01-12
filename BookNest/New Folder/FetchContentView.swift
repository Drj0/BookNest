//
//  ContentView.swift
//  swiftdata
//
//  Created by Dheeraj on 03/01/26.
//


import SwiftUI

struct fetchContentView: View {
    @StateObject var vm = SearchViewModel()

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search books...", text: $vm.query, onCommit: {
                    Task { await vm.search() }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                if vm.isLoading {
                    ProgressView()
                }

                List(vm.books) { book in
                    VStack(alignment: .leading) {
                        Text(book.title ?? "Unknown Title")
                            .font(.headline)
                        Text(book.authorName?.joined(separator: ", ") ?? "Unknown Author")
                            .font(.subheadline)
                    }
                }

                if let err = vm.errorMessage {
                    Text("Error: \(err)")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Book Search")
        }
    }
}

#Preview{
    fetchContentView()
}
