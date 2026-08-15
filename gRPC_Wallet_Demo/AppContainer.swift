//
//  AppContainer.swift
//  gRPC_Wallet_Demo
//
//  Manual DI — one place that builds real dependencies and wires them
//  together. No framework: every dependency is a protocol, every object
//  receives what it needs through init. Missing a dependency is a compile
//  error here, not a runtime crash later.
//

import Foundation
import WalletNetworking

@MainActor
final class AppContainer {
    let walletService: WalletServicing

    init(walletService: WalletServicing = GRPCWalletService()) {
        self.walletService = walletService
    }

    func makeCoordinator() -> AppCoordinator {
        AppCoordinator(container: self)
    }

    func makeBalanceViewModel() -> BalanceViewModel {
        BalanceViewModel(walletService: walletService)
    }
}
