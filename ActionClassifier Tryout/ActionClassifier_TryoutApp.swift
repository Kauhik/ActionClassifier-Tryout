//
//  ActionClassifier_TryoutApp.swift
//  ActionClassifier Tryout
//
//  Created by Kaushik Manian on 14/7/25.
//

import SwiftUI
import SwiftData

@main
struct ActionClassifier_TryoutApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
