//
//  MilestoneEntriesView.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Milestone-only diary list for the iPad journal column segment.
//

import CoreData
import SwiftUI

/// - Description: Displays today's milestone diary entries for the selected child.
struct MilestoneEntriesView: View {
    @ObservedObject var viewModel: DailyDiaryViewModel

    private var milestoneEntries: [DiaryEntry] {
        viewModel.entries.filter {
            DiaryEntryType.fromPersistence($0.entryType ?? "") == .milestone
        }
        .sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
    }

    var body: some View {
        Group {
            if milestoneEntries.isEmpty {
                VStack {
                    Spacer(minLength: 0)
                    ContentUnavailableView {
                        Label("No milestones yet", systemImage: "star.fill")
                    } description: {
                        Text("Milestone observations logged today appear here.")
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(milestoneEntries, id: \.objectID) { entry in
                            NavigationLink {
                                DiaryEntryDetailView(entry: entry, viewModel: viewModel)
                            } label: {
                                ActivityLogCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
            }
        }
        .ncStudioScreenBackdropUnlessChildWorkspace()
    }
}
