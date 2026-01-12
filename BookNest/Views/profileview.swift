import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// MARK: - Profile View
struct ProfileView: View {
    @Environment(\.modelContext) var modelContext
    @Query var profiles: [Profile]
    @Query var books: [Book]
    
    @State private var showingEditSheet = false
    @State private var showFullProfile = false
    
    var currentProfile: Profile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        Color.primaryGradientStart.opacity(0.1),
                        Color.primaryGradientEnd.opacity(0.05),
                        Color.subtleBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header Card
                        ProfileHeaderCard(
                            profile: currentProfile,
                            showFullProfile: $showFullProfile,
                            onEdit: { showingEditSheet = true }
                        )
                        
                        // Stats Section
                        StatsSection(books: books, profile: currentProfile)
                        
                        // Reading Goal Section
                        if let profile = currentProfile {
                            ReadingGoalSection(
                                goal: profile.readingGoal,
                                booksRead: books.count
                            )
                        }
                        
                        // Favorite Genres Section
                        if let profile = currentProfile, !profile.favoriteGenres.isEmpty {
                            FavoriteGenresSection(genres: profile.favoriteGenres)
                        }
                        
                        // Quick Actions
                        QuickActionsSection()
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundStyle(LinearGradient.primary)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditProfileView(profile: currentProfile)
            }
            .onAppear {
                // Create default profile if none exists
                if profiles.isEmpty {
                    let defaultProfile = Profile()
                    modelContext.insert(defaultProfile)
                }
            }
        }
    }
}

struct ProfileHeaderCard: View {
    let profile: Profile?
    @Binding var showFullProfile: Bool
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Image with Gradient Border
            ZStack {
                Circle()
                    .fill(LinearGradient.primary)
                    .frame(width: showFullProfile ? 150 : 100, height: showFullProfile ? 150 : 100)
                
                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: showFullProfile ? 142 : 92, height: showFullProfile ? 142 : 92)
                
                if let profile = profile, let imageData = profile.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: showFullProfile ? 136 : 86, height: showFullProfile ? 136 : 86)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: showFullProfile ? 50 : 35))
                        .foregroundStyle(LinearGradient.primary)
                }
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showFullProfile.toggle()
                }
            }
            .shadow(color: Color.primaryGradientStart.opacity(0.3), radius: 15, x: 0, y: 8)
            
            if let profile = profile {
                VStack(spacing: 8) {
                    Text(profile.fullName)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    
                    if !profile.email.isEmpty {
                        Text(profile.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if !profile.bio.isEmpty && showFullProfile {
                        Text(profile.bio)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Gender Badge
                    HStack(spacing: 12) {
                        Text(profile.gender)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(LinearGradient.primary)
                            .clipShape(Capsule())
                        
                        // Member Since
                        Text("Joined \(profile.joinDate.formatted(.dateTime.month(.abbreviated).year()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                VStack(spacing: 8) {
                    Text("Set Up Your Profile")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button("Get Started", action: onEdit)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(LinearGradient.primary)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
    }
}

// MARK: - Stats Section
struct StatsSection: View {
    let books: [Book]
    let profile: Profile?
    
    var averageRating: Double {
        guard !books.isEmpty else { return 0 }
        let total = books.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(books.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(LinearGradient.primary)
                Text("Reading Stats")
                    .font(.headline)
            }
            
            HStack(spacing: 16) {
                StatCard(value: "\(books.count)", label: "Books Read", icon: "book.fill")
                StatCard(value: "\(books.filter { !$0.review.isEmpty }.count)", label: "Reviews", icon: "text.quote")
                StatCard(value: String(format: "%.1f", averageRating), label: "Avg Rating", icon: "star.fill")
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(LinearGradient.primary)
                .accessibilityHidden(true)
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.subtleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Reading Goal Section
struct ReadingGoalSection: View {
    let goal: Int
    let booksRead: Int
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(booksRead) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .foregroundStyle(LinearGradient.primary)
                Text("Reading Goal")
                    .font(.headline)
                
                Spacer()
                
                Text("\(booksRead)/\(goal) books")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.subtleBackground)
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient.primary)
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 12)
            
            // Motivational Message
            Text(progressMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    var progressMessage: String {
        let percentage = Int(progress * 100)
        switch percentage {
        case 0:
            return "Start your reading journey! 📚"
        case 1..<25:
            return "Great start! Keep reading! 🌱"
        case 25..<50:
            return "You're making progress! 💪"
        case 50..<75:
            return "Halfway there! Amazing! 🔥"
        case 75..<100:
            return "Almost there! You got this! 🚀"
        default:
            return "Goal achieved! Congratulations! 🎉"
        }
    }
}

// MARK: - Favorite Genres Section
struct FavoriteGenresSection: View {
    let genres: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(LinearGradient.primary)
                Text("Favorite Genres")
                    .font(.headline)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .font(.subheadline)
                        .foregroundColor(Color.primaryGradientStart)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.primaryGradientStart.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in containerWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > containerWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(LinearGradient.primary)
                Text("Quick Actions")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                QuickActionRow(icon: "gear", title: "Settings", color: .gray)
                QuickActionRow(icon: "bell.fill", title: "Notifications", color: .orange)
                QuickActionRow(icon: "heart.fill", title: "Favorites", color: .pink)
                QuickActionRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .blue)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Quick Action Row
struct QuickActionRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    let profile: Profile?
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var bio: String = ""
    @State private var gender: String = "Not specified"
    @State private var readingGoal: Int = 12
    @State private var selectedGenres: Set<String> = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    let genders = ["Not specified", "Male", "Female", "Other"]
    let allGenres = ["Fiction", "Fantasy", "Science Fiction", "Romance", "Mystery", "Thriller", "Horror", "Comedy", "Action", "Biography", "History", "Self-Help"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.subtleBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image Section
                        VStack(spacing: 16) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.primary)
                                        .frame(width: 120, height: 120)
                                    
                                    Circle()
                                        .fill(Color.cardBackground)
                                        .frame(width: 112, height: 112)
                                    
                                    if let image = profileImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 106, height: 106)
                                            .clipShape(Circle())
                                    } else {
                                        VStack(spacing: 4) {
                                            Image(systemName: "camera.fill")
                                                .font(.title2)
                                            Text("Add Photo")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(LinearGradient.primary)
                                    }
                                }
                            }
                            .onChange(of: selectedPhotoItem) { _, newValue in
                                Task {
                                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        profileImage = uiImage
                                    }
                                }
                            }
                        }
                        
                        // Personal Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeaderView(title: "Personal Info", icon: "person.fill")
                            
                            ModernTextField(placeholder: "First Name", text: $firstName, icon: "person")
                            ModernTextField(placeholder: "Last Name", text: $lastName, icon: "person")
                            ModernTextField(placeholder: "Email", text: $email, icon: "envelope")
                            
                            // Gender Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Picker("Gender", selection: $gender) {
                                    ForEach(genders, id: \.self) { g in
                                        Text(g).tag(g)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        // Bio Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeaderView(title: "About You", icon: "text.quote")
                            
                            TextEditor(text: $bio)
                                .frame(minHeight: 80)
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
                        
                        // Reading Goal Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeaderView(title: "Reading Goal", icon: "target")
                            
                            HStack {
                                Text("Books per year:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Stepper("\(readingGoal)", value: $readingGoal, in: 1...100)
                                    .labelsHidden()
                                
                                Text("\(readingGoal)")
                                    .font(.headline)
                                    .foregroundStyle(LinearGradient.primary)
                                    .frame(width: 40)
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        // Favorite Genres Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeaderView(title: "Favorite Genres", icon: "heart.fill")
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                                ForEach(allGenres, id: \.self) { genre in
                                    Button {
                                        if selectedGenres.contains(genre) {
                                            selectedGenres.remove(genre)
                                        } else {
                                            selectedGenres.insert(genre)
                                        }
                                    } label: {
                                        Text(genre)
                                            .font(.subheadline)
                                            .fontWeight(selectedGenres.contains(genre) ? .semibold : .regular)
                                            .foregroundColor(selectedGenres.contains(genre) ? .white : Color.primaryGradientStart)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                selectedGenres.contains(genre)
                                                    ? AnyShapeStyle(LinearGradient.primary)
                                                    : AnyShapeStyle(Color.primaryGradientStart.opacity(0.1))
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        // Save Button
                        Button(action: saveProfile) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Profile")
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
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }
    
    private func loadProfile() {
        if let profile = profile {
            firstName = profile.firstName
            lastName = profile.lastName
            email = profile.email
            bio = profile.bio
            gender = profile.gender
            readingGoal = profile.readingGoal
            selectedGenres = Set(profile.favoriteGenres)
            if let imageData = profile.profileImageData {
                profileImage = UIImage(data: imageData)
            }
        }
    }
    
    private func saveProfile() {
        if let existingProfile = profile {
            existingProfile.firstName = firstName
            existingProfile.lastName = lastName
            existingProfile.email = email
            existingProfile.bio = bio
            existingProfile.gender = gender
            existingProfile.readingGoal = readingGoal
            existingProfile.favoriteGenres = Array(selectedGenres)
            existingProfile.profileImageData = profileImage?.jpegData(compressionQuality: 0.8)
        } else {
            let newProfile = Profile(
                firstName: firstName,
                lastName: lastName,
                email: email,
                gender: gender,
                profileImageData: profileImage?.jpegData(compressionQuality: 0.8),
                readingGoal: readingGoal,
                favoriteGenres: Array(selectedGenres),
                bio: bio
            )
            modelContext.insert(newProfile)
        }
        
        dismiss()
    }
}

#Preview {
    ProfileView()
}
