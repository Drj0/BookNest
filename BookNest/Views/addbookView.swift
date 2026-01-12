import SwiftData
import SwiftUI

struct addbookview: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var genre: String = "Fantasy"
    @State private var review = ""
    @State private var rating: Int = 0
    
    let genres = ["Action", "Romance", "Comedy", "Fantasy", "Horror", "Thriller", "Science Fiction"]
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.subtleBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeaderView(title: "Book Information", icon: "book.fill")
                            
                            ModernTextField(
                                placeholder: "Book Title",
                                text: $title,
                                icon: "textformat"
                            )
                            .accessibilityLabel("Book Title")
                            .accessibilityHint("Enter the title of the book you want to add")
                            
                            ModernTextField(
                                placeholder: "Author Name",
                                text: $author,
                                icon: "person.fill"
                            )
                            .accessibilityLabel("Author Name")
                            .accessibilityHint("Enter the name of the book's author")
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeaderView(title: "Genre", icon: "tag.fill")
                            
                            GenrePickerView(selectedGenre: $genre, genres: genres)
                                .accessibilityLabel("Book Genre")
                                .accessibilityValue(genre)
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeaderView(title: "Your Review", icon: "star.fill")
                            
                            HStack {
                                Text("Rating")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                ModernRatingView(rating: $rating)
                                    .accessibilityLabel("Book Rating")
                                    .accessibilityValue("\(rating) stars")
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Review (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextEditor(text: $review)
                                    .frame(minHeight: 100)
                                    .padding(12)
                                    .background(Color.subtleBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .accessibilityLabel("Book Review")
                                    .accessibilityHint("Write your thoughts about this book (optional)")
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        Button {
                            let newBook = Book(title: title, author: author, genre: genre, review: review, rating: rating)
                            modelContext.insert(newBook)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Book")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isFormValid
                                    ? LinearGradient.primary
                                    : LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: isFormValid ? Color.primaryGradientStart.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isFormValid)
                        .animation(.easeInOut, value: isFormValid)
                        .accessibilityLabel("Save Book")
                        .accessibilityHint(isFormValid ? "Save the new book to your library" : "Fill in the required fields to save the book")
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityHint("Close the add book form without saving")
                }
            }
        }
    }
}


struct ModernTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color.primaryGradientStart)
                .frame(width: 24)
                .accessibilityHidden(true)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding()
        .background(Color.subtleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Section Header View
struct SectionHeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(LinearGradient.primary)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Genre Picker View
struct GenrePickerView: View {
    @Binding var selectedGenre: String
    let genres: [String]
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 10)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(genres, id: \.self) { genre in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedGenre = genre
                    }
                } label: {
                    Text(genre)
                        .font(.subheadline)
                        .fontWeight(selectedGenre == genre ? .semibold : .regular)
                        .foregroundColor(selectedGenre == genre ? .white : Color.primaryGradientStart)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedGenre == genre
                                ? AnyShapeStyle(LinearGradient.primary)
                                : AnyShapeStyle(Color.primaryGradientStart.opacity(0.1))
                        )
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Modern Rating View
struct ModernRatingView: View {
    @Binding var rating: Int
    let maximumRating = 5
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maximumRating, id: \.self) { star in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        rating = star
                    }
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                        .scaleEffect(star <= rating ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    addbookview()
}
