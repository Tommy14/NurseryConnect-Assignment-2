//
//  ProfileInfoRow.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Labelled profile field row shared by child and keyworker profiles.
//

import SwiftUI

/// - Description: Icon, overline label, and body text on the standard profile card surface.
struct ProfileInfoRow: View {
    let title: String
    let text: String
    let symbol: String
    var prefersSentenceBullets: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ncPrimary, Color.ncGlowBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, alignment: .center)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                ProfileDetailText(text: text, prefersSentenceBullets: prefersSentenceBullets)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncProfileInfoRowStyle()
        .accessibilityElement(children: .combine)
    }
}

/// - Description: Renders plain, bulleted, or sentence-split profile copy.
struct ProfileDetailText: View {
    let text: String
    var prefersSentenceBullets: Bool = false

    var body: some View {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let items = resolvedItems(lines: lines)

        Group {
            if items.isEmpty {
                Text("—")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if items.count == 1 {
                Text(items[0])
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(line)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func resolvedItems(lines: [String]) -> [String] {
        if lines.count > 1 { return lines }
        if prefersSentenceBullets { return sentenceItems(from: lines.first ?? "") }
        return lines
    }

    private func sentenceItems(from text: String) -> [String] {
        let normalised = text.replacingOccurrences(of: "\n", with: " ")
        let rawItems = normalised.components(separatedBy: ". ")
        return rawItems
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { item in
                if item.hasSuffix(".") { return item }
                return "\(item)."
            }
    }
}
