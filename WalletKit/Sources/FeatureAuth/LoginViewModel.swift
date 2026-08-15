//
//  LoginViewModel.swift
//  FeatureAuth
//
//  A Feature module is the ONLY layer allowed to depend on more than one
//  Core module at once — it's where Core capabilities get composed into
//  a real user-facing flow. CoreSecurity and CoreUI still know nothing
//  about each other, and nothing about this file.
//

import CoreSecurity
import Foundation
import WalletNetworking

@MainActor
@Observable
public final class LoginViewModel {
    public private(set) var isLoggedIn = false
    public private(set) var statusText = "Not logged in"

    private let secureStore: SecureStoring
    private let walletService: WalletServicing
    private let tokenKey = "auth_token"

    public init(secureStore: SecureStoring, walletService: WalletServicing) {
        self.secureStore = secureStore
        self.walletService = walletService
    }

    public func checkExistingSession() {
        if let existing = try? secureStore.read(forKey: tokenKey), existing != nil {
            isLoggedIn = true
            statusText = "Session restored from Keychain"
        }
    }

    public func login() {
        do {
            // Real login would call an auth RPC; here we simulate the token
            // arriving from the server and prove it survives in Keychain.
            let fakeToken = Data("demo-session-token".utf8)
            try secureStore.save(fakeToken, forKey: tokenKey)
            isLoggedIn = true
            statusText = "Logged in — token stored in Keychain"
        } catch {
            statusText = "Login failed: \(error)"
        }
    }

    public func logout() {
        try? secureStore.delete(forKey: tokenKey)
        isLoggedIn = false
        statusText = "Logged out"
    }
}
