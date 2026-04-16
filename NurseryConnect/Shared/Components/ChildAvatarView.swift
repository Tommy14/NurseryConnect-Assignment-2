//
//  ChildAvatarView.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 30 March 2026
//  Description: Circular initials avatar with a stable pastel background per child.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 300326     Tommy1914   Created the file with deterministic colour hashing.
// 100426     Tommy1914   Optional gradient ring for dashboard list rows.
// 100426     Tommy1914   Configurable diameter for denser list layouts.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Renders initials for a child with a soft colour derived from their stable id.
struct ChildAvatarView: View {
    let firstName: String
    let lastName: String
    let childId: UUID
    /// - Description: When `true`, draws a subtle brand gradient ring (used on dashboard cards).
    var showsAccentRing: Bool = false
    /// - Description: Avatar diameter in points (default matches prior 48pt tiles).
    var dimension: CGFloat = 48

    private var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    private var background: Color {
        let hash = abs(childId.uuidString.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.35, brightness: 0.92)
    }

    var body: some View {
        let fontSize = max(12, dimension * 0.33)
        Text(initials)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.primary.opacity(0.85))
            .frame(width: dimension, height: dimension)
            .background(background)
            .clipShape(Circle())
            .overlay {
                if showsAccentRing {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.ncPrimary.opacity(0.75), Color.cyan.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: dimension + 5, height: dimension + 5)
                }
            }
            .accessibilityLabel("Avatar for \(firstName) \(lastName)")
    }
}

#Preview {
    ChildAvatarView(firstName: "Emma", lastName: "Wilson", childId: UUID())
}
