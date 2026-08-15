//
//  ContentView.swift
//  gRPC_Wallet_Demo
//
//  Created by Kanat on 10.08.2026.
//

import SwiftUI

struct ContentView: View {
    let coordinator: AppCoordinator
    let viewModel: BalanceViewModel
    let screenshotDetector: ScreenshotDetector

    var body: some View {
        NavigationStack(path: Binding(
            get: { coordinator.path },
            set: { coordinator.path = $0 }
        )) {
            VStack(spacing: 20) {
                // Only the sensitive text sits inside the secure layer.
                // The trick is designed for static display content, not
                // interactive controls — buttons stay in normal SwiftUI.
                SecureContainerView {
                    Text(viewModel.balanceText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                .frame(height: 60)

                if screenshotDetector.screenshotTakenCount > 0 {
                    Text("⚠️ Screenshot detected \(screenshotDetector.screenshotTakenCount)x")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button("Fetch balance") {
                    Task { await viewModel.fetchBalance() }
                }
                .disabled(viewModel.isLoading)

                Button("Transaction history") {
                    coordinator.showTransactionHistory()
                }
            }
            .padding()
            .navigationDestination(for: Route.self) { route in
                coordinator.destination(for: route)
            }
        }
    }
}

#Preview {
    let container = AppContainer()
    ContentView(
        coordinator: container.makeCoordinator(),
        viewModel: container.makeBalanceViewModel(),
        screenshotDetector: ScreenshotDetector()
    )
}
