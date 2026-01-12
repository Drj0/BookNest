//
//  OnlineSearchView.swift
//  swiftdata
//
//  Created by Antigravity on 09/01/26.
//

import SwiftUI
import SwiftData
import UIKit

struct OnlineSearchView: View {
    @Environment(\.modelContext) var modelContext
    @Query var userBooks: [Book]
    @StateObject private var searchService = BookSearchService()
    @State private var searchQuery = ""
    @State private var addedBooks: Set<String> = []
    @State private var debounceTimer: Timer?
    @State private var showingSuggestions = true
    @State private var selectedSuggestionGenre: String?
    @State private var bookToAdd: OpenLibraryBook?
    @State private var showingAddSheet = false
    
    // Get top genres from user's library sorted by average rating
    var topGenres: [(genre: String, avgRating: Double, count: Int)] {
        var genreData: [String: (totalRating: Int, count: Int)] = [:]
        
        for book in userBooks {
            let genre = book.genre
            if let existing = genreData[genre] {
                genreData[genre] = (existing.totalRating + book.rating, existing.count + 1)
            } else {
                genreData[genre] = (book.rating, 1)
            }
        }
        
        return genreData.map { genre, data in
            let avgRating = data.count > 0 ? Double(data.totalRating) / Double(data.count) : 0
            return (genre: genre, avgRating: avgRating, count: data.count)
        }
        .sorted { $0.avgRating > $1.avgRating }
        .prefix(5)
        .map { $0 }
    }
    
    // Get favorite authors
    var topAuthors: [String] {
        var authorCounts: [String: Int] = [:]
        for book in userBooks {
            authorCounts[book.author, default: 0] += 1
        }
        return authorCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    var body: some View {
        ZStack {
            Color.subtleBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .foregroundStyle(LinearGradient.primary)
                    
                    TextField("Search books online...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            performSearch()
                        }
                        .onChange(of: searchQuery) { oldValue, newValue in
                            if newValue.isEmpty {
                                showingSuggestions = true
                            }
                            debounceSearch()
                        }
                    
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            searchService.searchResults = []
                            searchService.hasSearched = false
                            searchService.cancelSearch()
                            showingSuggestions = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if searchService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if !searchQuery.isEmpty {
                        Button {
                            performSearch()
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(LinearGradient.primary)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding()
                
                // Content
                if searchService.isLoading && searchService.searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Searching Open Library...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Searching")
                    .accessibilityValue("Searching Open Library for books")
                    Spacer()
                } else if let error = searchService.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            performSearch()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(LinearGradient.primary)
                        .clipShape(Capsule())
                        .accessibilityLabel("Try Again")
                        .accessibilityHint("Retry the search")
                    }
                    .accessibilityElement(children: .combine)
                    Spacer()
                } else if searchService.searchResults.isEmpty {
                    if searchService.hasSearched {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            Text("No books found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("No Results")
                        Spacer()
                    } else {
                        // Show personalized suggestions
                        ScrollView {
                            VStack(spacing: 24) {
                                // Header
                                VStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 40))
                                        .foregroundStyle(LinearGradient.primary)
                                        .accessibilityHidden(true)
                                    Text("Discover Books")
                                        .font(.title2.weight(.semibold))
                                    Text("Personalized suggestions based on your library")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top)
                                
                                // Personalized Suggestions based on genres
                                if !topGenres.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "heart.fill")
                                                .foregroundStyle(LinearGradient.primary)
                                            Text("Based on Your Favorites")
                                                .font(.headline)
                                        }
                                        .padding(.horizontal)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(topGenres, id: \.genre) { item in
                                                    GenreSuggestionCard(
                                                        genre: item.genre,
                                                        avgRating: item.avgRating,
                                                        bookCount: item.count,
                                                        isSelected: selectedSuggestionGenre == item.genre,
                                                        onTap: {
                                                            selectedSuggestionGenre = item.genre
                                                            searchQuery = "best \(item.genre) books"
                                                            performSearch()
                                                            showingSuggestions = false
                                                        }
                                                    )
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                                
                                // Favorite Authors
                                if !topAuthors.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .foregroundStyle(LinearGradient.primary)
                                            Text("More from Your Authors")
                                                .font(.headline)
                                        }
                                        .padding(.horizontal)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(topAuthors, id: \.self) { author in
                                                    Button {
                                                        searchQuery = author
                                                        performSearch()
                                                        showingSuggestions = false
                                                    } label: {
                                                        HStack(spacing: 8) {
                                                            Image(systemName: "person.circle.fill")
                                                                .foregroundStyle(LinearGradient.primary)
                                                            Text(author)
                                                                .font(.subheadline)
                                                                .foregroundColor(.primary)
                                                        }
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 12)
                                                        .background(Color.cardBackground)
                                                        .clipShape(Capsule())
                                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                                
                                // Quick Searches
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(LinearGradient.primary)
                                        Text("Popular Searches")
                                            .font(.headline)
                                    }
                                    .padding(.horizontal)
                                    
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                                        ForEach(["Bestsellers", "New Releases", "Classic Literature", "Award Winners", "Mystery", "Sci-Fi"], id: \.self) { suggestion in
                                            Button {
                                                searchQuery = suggestion
                                                performSearch()
                                                showingSuggestions = false
                                            } label: {
                                                Text(suggestion)
                                                    .font(.caption)
                                                    .foregroundColor(Color.primaryGradientStart)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 10)
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.primaryGradientStart.opacity(0.1))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // Empty library hint
                                if userBooks.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.yellow)
                                        Text("Tip: Add books to your library to get personalized suggestions!")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .background(Color.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    // Results count
                    HStack {
                        Text("\(searchService.searchResults.count) books found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        Button("Clear") {
                            searchQuery = ""
                            searchService.searchResults = []
                            searchService.hasSearched = false
                            showingSuggestions = true
                        }
                        .font(.caption)
                        .foregroundColor(Color.primaryGradientStart)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchService.searchResults) { book in
                                OnlineBookCard(
                                    book: book,
                                    isAdded: addedBooks.contains(book.key),
                                    onAdd: {
                                        bookToAdd = book
                                        showingAddSheet = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationTitle("Discover")
        .onDisappear {
            debounceTimer?.invalidate()
            searchService.cancelSearch()
        }
        .sheet(isPresented: $showingAddSheet) {
            if let book = bookToAdd {
                AddOnlineBookView(
                    book: book,
                    onSave: { review, rating in
                        addBookWithReview(book, review: review, rating: rating)
                        showingAddSheet = false
                    },
                    onCancel: {
                        showingAddSheet = false
                    }
                )
            }
        }
    }
    
    private func debounceSearch() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
            performSearch()
        }
    }
    
    private func performSearch() {
        debounceTimer?.invalidate()
        showingSuggestions = false
        searchService.searchBooks(query: searchQuery)
    }
    
    private func addBookWithReview(_ book: OpenLibraryBook, review: String, rating: Int) {
        let newBook = Book(
            title: book.title,
            author: book.primaryAuthor,
            genre: book.primaryGenre,
            review: review,
            rating: rating,
            coverImageURL: book.coverImageURL,
            publishYear: book.firstPublishYear,
            openLibraryKey: book.key
        )
        modelContext.insert(newBook)
        addedBooks.insert(book.key)
        
        // Download and cache cover image
        if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    await MainActor.run {
                        newBook.coverImageData = data
                    }
                } catch {
                    print("Failed to download cover image: \(error)")
                }
            }
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Add Online Book View (Review & Rating Sheet)
struct AddOnlineBookView: View {
    let book: OpenLibraryBook
    let onSave: (String, Int) -> Void
    let onCancel: () -> Void
    
    @State private var review = ""
    @State private var rating: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.subtleBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Book Preview Card
                        VStack(spacing: 16) {
                            // Cover Image
                            Group {
                                if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(height: 180)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                                        case .failure, .empty:
                                            bookCoverPlaceholder
                                        @unknown default:
                                            bookCoverPlaceholder
                                        }
                                    }
                                } else {
                                    bookCoverPlaceholder
                                }
                            }
                            
                            VStack(spacing: 8) {
                                Text(book.title)
                                    .font(.title3.weight(.bold))
                                    .multilineTextAlignment(.center)
                                
                                Text(book.primaryAuthor)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    if let year = book.firstPublishYear {
                                        Label(String(year), systemImage: "calendar")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(book.primaryGenre)
                                        .font(.caption)
                                        .foregroundColor(Color.primaryGradientStart)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.primaryGradientStart.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        // Rating Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(LinearGradient.primary)
                                Text("Your Rating")
                                    .font(.headline)
                            }
                            
                            HStack {
                                Spacer()
                                HStack(spacing: 12) {
                                    ForEach(1...5, id: \.self) { star in
                                        Button {
                                            withAnimation(.spring(response: 0.3)) {
                                                rating = star
                                            }
                                        } label: {
                                            Image(systemName: star <= rating ? "star.fill" : "star")
                                                .font(.title)
                                                .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                                                .scaleEffect(star <= rating ? 1.1 : 1.0)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        // Review Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "text.quote")
                                    .foregroundStyle(LinearGradient.primary)
                                Text("Your Review")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("Optional")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            TextEditor(text: $review)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Color.subtleBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        // Add Button
                        Button {
                            onSave(review, rating)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Library")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.primaryGradientStart.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                }
            }
        }
    }
    
    private var bookCoverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient.primary.opacity(0.3))
            .frame(width: 120, height: 180)
            .overlay(
                Image(systemName: "book.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.7))
            )
    }
}

// MARK: - Genre Suggestion Card
struct GenreSuggestionCard: View {
    let genre: String
    let avgRating: Double
    let bookCount: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(genre)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color.primaryGradientStart)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .yellow)
                    Text(String(format: "%.1f", avgRating))
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    
                    Text("•")
                        .foregroundColor(isSelected ? .white.opacity(0.5) : .secondary)
                    
                    Text("\(bookCount) book\(bookCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding()
            .frame(width: 160)
            .background(isSelected ? LinearGradient.primary : LinearGradient(colors: [Color.cardBackground, Color.cardBackground], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct OnlineBookCard: View {
    let book: OpenLibraryBook
    let isAdded: Bool
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Book Cover
            Group {
                if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 85)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            bookPlaceholder
                        case .empty:
                            bookPlaceholder
                                .overlay(ProgressView().scaleEffect(0.5))
                        @unknown default:
                            bookPlaceholder
                        }
                    }
                } else {
                    bookPlaceholder
                }
            }
            .frame(width: 60, height: 85)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(book.primaryAuthor)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let year = book.firstPublishYear {
                        Text(String(year))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(book.primaryGenre)
                        .font(.caption)
                        .foregroundColor(Color.primaryGradientStart)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.primaryGradientStart.opacity(0.1))
                        .clipShape(Capsule())
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: onAdd) {
                if isAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(LinearGradient.primary)
                }
            }
            .disabled(isAdded)
            .animation(.spring(response: 0.3), value: isAdded)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    private var bookPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient.primary.opacity(0.3))
            .frame(width: 60, height: 85)
            .overlay(
                Image(systemName: "book.fill")
                    .foregroundColor(.white.opacity(0.7))
            )
    }
}

#Preview {
    NavigationStack {
        OnlineSearchView()
    }
}
