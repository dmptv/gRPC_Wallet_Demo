//
//  SecureContainerView.swift
//  gRPC_Wallet_Demo
//
//  Two separate, honest mechanisms — iOS gives no way to BLOCK a
//  screenshot; the OS never asks the app for permission first.
//
//  1) Screen recording / mirroring (AirPlay, QuickTime capture) CAN be
//     blocked: content placed inside a secure UITextField's layer is
//     rendered as blank by the recording pipeline, while looking normal
//     to the person actually holding the phone. This is the classic
//     "secure view" trick.
//  2) A screenshot CAN be detected — after the fact — via
//     UIApplication.userDidTakeScreenshotNotification, so the app can log
//     it or warn the user. It cannot prevent the image from being saved.
//

import SwiftUI
import UIKit

/// Wraps SwiftUI content in a secure layer that appears blank in screen
/// recordings and screen mirroring, using a UITextField's secure layer
/// as the actual rendering surface.
struct SecureContainerView<Content: View>: UIViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIView {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true

        // The secure layer is the ONLY part of a secure text field that the
        // recording pipeline treats specially. We repurpose it as a plain
        // container and put our real content inside it.
        guard let secureLayer = secureField.layer.sublayers?.first,
              let secureContainer = secureLayer.delegate as? UIView else {
            // Fallback: if Apple changes this private layout internally,
            // don't crash — just show the content unprotected.
            let host = UIHostingController(rootView: content)
            return host.view
        }

        secureContainer.subviews.forEach { $0.removeFromSuperview() }

        let hosting = UIHostingController(rootView: content)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        secureContainer.addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: secureContainer.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: secureContainer.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: secureContainer.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor),
        ])

        secureContainer.isUserInteractionEnabled = true
        return secureContainer
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Detects (but cannot prevent) a screenshot. Use to log the event or
/// warn the user — the image has already been saved by the time this fires.
@MainActor
@Observable
final class ScreenshotDetector {
    private(set) var screenshotTakenCount = 0
    // nonisolated(unsafe): a `deinit` on a @MainActor class isn't itself
    // actor-isolated, so it can't touch actor-isolated storage. The token
    // is just an opaque reference — safe to read/clear off the actor here.
    nonisolated(unsafe) private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.screenshotTakenCount += 1
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
