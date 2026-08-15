//
//  DesignTokens.swift
//  CoreUI
//
//  Same rule as CoreSecurity: this is a Core module. It knows nothing
//  about FeatureAuth or any other feature. Features import CoreUI,
//  never the other way around.
//

import SwiftUI

public enum AppColor {
    public static let primary = Color.blue
    public static let danger = Color.red
    public static let background = Color(.systemBackground)
}

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppColor.primary.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
