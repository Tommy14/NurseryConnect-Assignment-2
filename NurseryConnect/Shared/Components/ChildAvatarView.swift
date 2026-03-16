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
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Renders initials for a child with a soft colour derived from their stable id.
struct ChildAvatarView: View {
    let firstName: String
    let lastName: String
    let childId: UUID

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
        Text(initials)
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.primary.opacity(0.85))
            .frame(width: 48, height: 48)
            .background(background)
            .clipShape(Circle())
            .accessibilityLabel("Avatar for \(firstName) \(lastName)")
    }
}

#Preview {
    ChildAvatarView(firstName: "Emma", lastName: "Wilson", childId: UUID())
}
