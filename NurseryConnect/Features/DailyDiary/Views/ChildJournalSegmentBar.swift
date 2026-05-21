//
//  ChildJournalSegmentBar.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Pinned Journal / Milestones / Charts header for the iPad child workspace.
//

import SwiftUI

/// - Description: Fixed workspace chrome: child title, segment control, and optional sync status.
struct ChildJournalSegmentBar: View {
    @Binding var selection: ChildJournalSegment
    var childDisplayName: String?
    var syncStatusLabel: String?
    var showsSidebarToggle: Bool = false
    var onShowSidebar: (() -> Void)?
    var isProfilePanelCollapsed: Bool = false
    var onToggleProfile: (() -> Void)?

    private let chromeButtonWidth: CGFloat = 44
    private let profileButtonSize: CGFloat = 52

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsTopChromeRow {
                ZStack {
                    if let childDisplayName {
                        Text(childDisplayName)
                            .font(AppTheme.titleRounded())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 0) {
                        leadingChromeControl
                        Spacer(minLength: 0)
                        trailingChromeControls
                    }
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 10) {
                Picker("Content", selection: $selection) {
                    ForEach(ChildJournalSegment.allCases) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)

                if showsProfileToggle {
                    profileToggleButton
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.clear)
    }

    private var showsTopChromeRow: Bool {
        childDisplayName != nil || showsSidebarToggle || syncStatusLabel != nil
    }

    private var showsProfileToggle: Bool {
        onToggleProfile != nil
    }

    @ViewBuilder
    private var leadingChromeControl: some View {
        if showsSidebarToggle {
            Button {
                onShowSidebar?()
            } label: {
                Image(systemName: "sidebar.leading")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.ncPrimary)
                    .frame(width: chromeButtonWidth, height: chromeButtonWidth)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show children list")
        } else {
            Color.clear
                .frame(width: chromeButtonWidth, height: chromeButtonWidth)
        }
    }

    @ViewBuilder
    private var trailingChromeControls: some View {
        if let syncStatusLabel {
            Text(syncStatusLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(minWidth: chromeButtonWidth, alignment: .trailing)
        } else {
            Color.clear
                .frame(width: chromeButtonWidth, height: chromeButtonWidth)
        }
    }

    private var profileToggleButton: some View {
        Button {
            onToggleProfile?()
        } label: {
            Image(
                systemName: isProfilePanelCollapsed
                    ? "person.crop.circle"
                    : "person.crop.circle.fill"
            )
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(Color.ncPrimary)
            .frame(width: profileButtonSize, height: profileButtonSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isProfilePanelCollapsed ? "Show profile" : "Hide profile")
    }
}
