//
//  swiftdataApp.swift
//  swiftdata
//
//  Created by Dheeraj on 30/12/25.
//

import SwiftData
import SwiftUI

@main
struct swiftdataApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Book.self, Profile.self])
    }
}

