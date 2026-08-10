//
//  gRPC_Wallet_DemoApp.swift
//  gRPC_Wallet_Demo
//
//  Created by Kanat on 10.08.2026.
//

import SwiftUI
import SwiftData

@main
struct gRPC_Wallet_DemoApp: App {
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
