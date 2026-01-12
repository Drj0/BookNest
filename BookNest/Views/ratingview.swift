import Foundation
import SwiftUI

struct ratingView: View {
    @Binding var rating: Int
    
    var label = ""
    var maximumRating = 5
    
    var body: some View {
        HStack(spacing: 8) {
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ForEach(1...maximumRating, id: \.self) { number in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        rating = number
                    }
                } label: {
                    Image(systemName: number <= rating ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundColor(number <= rating ? .yellow : .gray.opacity(0.3))
                        .scaleEffect(number <= rating ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: rating)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(number) star\(number == 1 ? "" : "s")")
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(rating == number ? "Current rating" : "Set rating to \(number) stars")
            }
        }
    }
}

#Preview {
    ratingView(rating: .constant(3))
        .padding()
}
