//
//  AppCoordinator.swift
//  gRPC_Wallet_Demo
//
//  Owns navigation. Screens never navigate themselves — they report intent
//  ("user tapped transaction history") and the coordinator decides what
//  that means for the route. This is what keeps a screen reusable and
//  testable in isolation: it doesn't know what other screens exist.
//

import SwiftUI

enum Route: Hashable {
    case transactionHistory
}

@MainActor
@Observable
final class AppCoordinator {
    var path = NavigationPath()

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func showTransactionHistory() {
        path.append(Route.transactionHistory)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case .transactionHistory:
            Text("Transaction history — placeholder screen")
        }
    }
}
