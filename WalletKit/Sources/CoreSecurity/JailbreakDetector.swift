//
//  JailbreakDetector.swift
//  CoreSecurity
//
//  No single check here is reliable on its own — a skilled attacker can
//  defeat any one of them. The point is combining several different KINDS
//  of checks (filesystem, sandbox, URL scheme) so that defeating all of
//  them costs real effort. This raises the price of an attack; it does
//  not make one impossible.
//
//  Honest limitation: none of this is meaningful on the iOS Simulator —
//  the simulator is never "jailbroken" in the sense these checks look
//  for, so this can only be verified by code review, not by a live test,
//  unless run on a real jailbroken device.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum JailbreakDetector {

    /// True if any of the independent checks below find evidence of a jailbreak.
    public static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        // Never meaningful on the simulator — see file header.
        return false
        #else
        return hasJailbreakFiles() || canWriteOutsideSandbox() || canOpenCydiaURL()
        #endif
    }

    // MARK: - Check 1: filesystem

    /// Files that only exist on a jailbroken device — the jailbreak's own
    /// package manager and tooling leave these behind.
    static func hasJailbreakFiles() -> Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",              // package manager on newer jailbreaks
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/bin/bash",                              // a stock iOS device has no shell binary at all
            "/private/var/lib/apt",
        ]

        let fileManager = FileManager.default
        for path in suspiciousPaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }

    // MARK: - Check 2: sandbox integrity

    /// A stock iOS app cannot write outside its own sandbox. On a
    /// jailbroken device the sandbox is often weakened or disabled.
    static func canWriteOutsideSandbox() -> Bool {
        let testPath = "/private/jailbreak_test_\(UUID().uuidString).txt"
        let testString = "jailbreak test"

        do {
            try testString.write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // the write succeeded — it shouldn't have been able to
        } catch {
            return false // normal, expected outcome on a real, unmodified device
        }
    }

    // MARK: - Check 3: forbidden URL scheme

    /// Cydia registers its own URL scheme. Being ABLE to open it at all
    /// means a jailbreak package manager is installed.
    @MainActor
    static func canOpenCydiaURL() -> Bool {
        #if canImport(UIKit)
        guard let url = URL(string: "cydia://package/com.example.package") else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
        #else
        return false
        #endif
    }
}
