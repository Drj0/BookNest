import SwiftData
import SwiftUI
import UIKit

// MARK: - Modern Color Theme
extension Color {
    static let primaryGradientStart = Color(red: 0.5, green: 0.3, blue: 0.9) // Purple
    static let primaryGradientEnd = Color(red: 0.3, green: 0.5, blue: 0.95) // Blue
    static let cardBackground = Color(.systemBackground)
    static let subtleBackground = Color(.systemGray6)
}

// MARK: - Gradient Extension
extension LinearGradient {
    static var primary: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.primaryGradientStart, Color.primaryGradientEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query var books: [Book]
    
    @State private var showingAddScreen = false
    
    var body: some View {
        TabView {
            // Books Tab
            BooksListView(books: books, showingAddScreen: $showingAddScreen)
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
            
            // Search Tab with segmented control for local/online
            SearchTabView(books: books)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            // Discover Tab (Online Search)
            NavigationStack {
                OnlineSearchView()
            }
            .tabItem {
                Label("Discover", systemImage: "globe")
            }
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Color.primaryGradientStart)
    }
}

// MARK: - Search Tab View (Combined Local & Online)
struct SearchTabView: View {
    let books: [Book]
    @State private var searchMode: SearchMode = .library
    
    enum SearchMode: String, CaseIterable {
        case library = "My Library"
        case online = "Online"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Picker
                Picker("Search Mode", selection: $searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on mode
                switch searchMode {
                case .library:
                    SearchView(books: books)
                case .online:
                    OnlineSearchView()
                }
            }
            .navigationTitle("Search")
        }
    }
}

// MARK: - Books List View
struct BooksListView: View {
    let books: [Book]
    @Binding var showingAddScreen: Bool
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.subtleBackground
                    .ignoresSafeArea()
                
                if books.isEmpty {
                    EmptyLibraryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(books, id: \.self) { book in
                                BookCardView(book: book)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("\(book.title) by \(book.author)")
                                    .accessibilityValue("Genre: \(book.genre), Rating: \(book.rating) stars")
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteBook(book)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddScreen.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(LinearGradient.primary)
                                .clipShape(Circle())
                                .shadow(color: Color.primaryGradientStart.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("My Library")
            .sheet(isPresented: $showingAddScreen) {
                addbookview()
            }
        }
    }
    
    private func deleteBook(_ book: Book) {
        modelContext.delete(book)
    }
}

// MARK: - Empty Library View
struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.primary)
            
            Text("Your Library is Empty")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            
            Text("Tap the + button to add your first book\nor discover books online")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct BookCardView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            // Book Cover - Local cached image first, then URL fallback
            bookCoverView
            
            // Book Details
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    // Genre Tag
                    Text(book.genre)
                        .font(.caption)
                        .foregroundColor(Color.primaryGradientStart)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primaryGradientStart.opacity(0.1))
                        .clipShape(Capsule())
                    
                    // Year (if available)
                    if let year = book.publishYear {
                        Text("(\(year))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Star Rating
                    if book.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= book.rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(star <= book.rating ? .yellow : .gray.opacity(0.3))
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var bookCoverView: some View {
        if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 85)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        else if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 85)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if phase.error != nil {
                    bookPlaceholder
                } else {
                    bookPlaceholder
                        .overlay(ProgressView().scaleEffect(0.5))
                }
            }
            .frame(width: 60, height: 85)
        } else {
            bookPlaceholder
        }
    }
    
    private var bookPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient.primary.opacity(0.8))
            .frame(width: 60, height: 85)
            .overlay(
                Image(systemName: "book.fill")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.title2)
            )
    }
}

struct SearchView: View {
    let books: [Book]
    @State private var query: String = ""
    
    var filteredBooks: [Book] {
        if query.isEmpty {
            return books
        }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.author.localizedCaseInsensitiveContains(query) ||
            $0.genre.localizedCaseInsensitiveContains(query)
        }
    }
    
    var body: some View {
        ZStack {
            Color.subtleBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search your library...", text: $query)
                        .textFieldStyle(.plain)
                    
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding()
                
                // Results
                if filteredBooks.isEmpty && !query.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No books found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try searching online to discover new books")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    Spacer()
                } else if books.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No books in your library")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add books manually or discover them online")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredBooks, id: \.self) { book in
                                BookCardView(book: book)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
