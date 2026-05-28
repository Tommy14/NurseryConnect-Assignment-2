//
//  NCPanelHeader.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Title bar for iPad trailing panels (profile, thread detail).
//

import SwiftUI

/// - Description: Centred panel title for fixed-width trailing columns.
struct NCPanelHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.clear)
    }
}
