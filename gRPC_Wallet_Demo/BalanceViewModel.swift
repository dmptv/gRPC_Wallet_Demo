//
//  BalanceViewModel.swift
//  gRPC_Wallet_Demo
//
//  MVVM: the view describes what's on screen, the ViewModel holds state
//  and talks to the service. Depends on the WalletServicing PROTOCOL, not
//  on GRPCWalletService directly — a test can inject a fake that returns
//  a fixed value without any network call.
//

import Foundation
import WalletNetworking

@MainActor
@Observable
final class BalanceViewModel {
    private(set) var balanceText = "Not fetched yet"
    private(set) var isLoading = false

    private let walletService: WalletServicing

    init(walletService: WalletServicing) {
        self.walletService = walletService
    }

    func fetchBalance() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let balance = try await walletService.getBalance(accountID: "acc-123")
            balanceText = "\(balance.amountMinor) \(balance.currency) (minor units)"
        } catch {
            balanceText = "Error: \(error)"
        }
    }
}
