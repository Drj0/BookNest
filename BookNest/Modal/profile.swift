//
//  profile.swift
//  swiftdata
//
//  Created by Dheeraj on 02/01/26.
//

import Foundation
import SwiftData

@Model
class Profile {
    var id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var gender: String
    var profileImageData: Data?
    var readingGoal: Int
    var favoriteGenres: [String]
    var bio: String
    var joinDate: Date

    init(
        id: UUID = UUID(),
        firstName: String = "",
        lastName: String = "",
        email: String = "",
        gender: String = "Not specified",
        profileImageData: Data? = nil,
        readingGoal: Int = 12,
        favoriteGenres: [String] = [],
        bio: String = "",
        joinDate: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.gender = gender
        self.profileImageData = profileImageData
        self.readingGoal = readingGoal
        self.favoriteGenres = favoriteGenres
        self.bio = bio
        self.joinDate = joinDate
    }
    
    var fullName: String {
        if firstName.isEmpty && lastName.isEmpty {
            return "Your Name"
        }
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}
