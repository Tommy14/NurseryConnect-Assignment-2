//
//  EndOfDaySummaryJournalButton.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Journal entry point for sending the end-of-day summary after 3pm.
//

import Combine
import CoreData
import SwiftUI

struct EndOfDaySummaryJournalButton: View {
    let childID: UUID
    let childDisplayName: String

    @Environment(\.managedObjectContext) private var context
    @State private var isSheetPresented = false
    @State private var showButton = false

    var body: some View {
        Group {
            if showButton {
                Button {
                    isSheetPresented = true
                } label: {
                    Label("Send End of Day Summary", systemImage: "paperplane.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.ncPrimary)
                .accessibilityIdentifier(AppConstants.AccessibilityID.sendEndOfDaySummaryButton)
            }
        }
        .task { refreshVisibility() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            refreshVisibility()
        }
        .sheet(isPresented: $isSheetPresented) {
            EndOfDaySummarySheet(
                childID: childID,
                childDisplayName: childDisplayName,
                managedObjectContext: context
            )
        }
    }

    private func refreshVisibility() {
        showButton = EndOfDaySummaryAvailability.shouldShowButton(childID: childID, in: context)
    }
}
