//
//  KeychainStore.swift
//  CoreSecurity
//
//  Owns nothing about features or UI — a Core module never imports
//  a Feature module. It only knows how to store and retrieve secrets.
//

import Foundation
import Security

public protocol SecureStoring: Sendable {
    func save(_ data: Data, forKey key: String) throws
    func read(forKey key: String) throws -> Data?
    func delete(forKey key: String) throws
}

public enum KeychainError: Error {
    case unhandled(OSStatus)
}

public struct KeychainStore: SecureStoring {
    public init() {}

    public func save(_ data: Data, forKey key: String) throws {
        // Overwrite semantics: delete any existing item first.
        try delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // WhenUnlocked, this device only — see the earlier "для дамы"
            // walkthrough: no iCloud sync, no background reads.
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    public func read(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
        return result as? Data
    }

    public func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }
}
