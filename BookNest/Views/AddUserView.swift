import Foundation
import SwiftData
import SwiftUI


struct AddUserView: View {
    //@Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    
    
    @State private var name = ""
    @State private var profilediscription = ""
    @State private var gender = ""
    @State private var email = ""
    @State private var review = ""

    
    var body : some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter name", text: $name)
                }
                
            }
        }
    }
}

#Preview {
        AddUserView()
    }

