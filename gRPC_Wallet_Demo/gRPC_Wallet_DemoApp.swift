//
//  gRPC_Wallet_DemoApp.swift
//  gRPC_Wallet_Demo
//
//  Created by Kanat on 10.08.2026.
//

import SwiftUI

@main
struct gRPC_Wallet_DemoApp: App {
    // The one composition root — the only place that builds real objects.
    // Everything downstream receives dependencies through init.
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(
                coordinator: container.makeCoordinator(),
                viewModel: container.makeBalanceViewModel(),
                screenshotDetector: ScreenshotDetector()
            )
        }
    }
}
