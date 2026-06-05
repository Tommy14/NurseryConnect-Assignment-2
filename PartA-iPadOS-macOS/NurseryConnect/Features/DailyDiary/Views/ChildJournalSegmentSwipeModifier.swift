//
//  ChildJournalSegmentSwipeModifier.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Horizontal swipe on the journal column to change Journal / Milestones / Charts.
//

import SwiftUI

/// - Description: Swipe left or right on the content column to move between journal segments.
struct ChildJournalSegmentSwipeModifier: ViewModifier {
    @Binding var selection: ChildJournalSegment

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 48)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    guard abs(horizontal) > abs(vertical) * 1.25 else { return }

                    if horizontal < -48, let next = selection.next {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            selection = next
                        }
                    } else if horizontal > 48, let previous = selection.previous {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            selection = previous
                        }
                    }
                }
        )
    }
}

extension View {
    /// - Description: Enables segment switching via horizontal swipe on iPad journal content.
    func childJournalSegmentSwipe(selection: Binding<ChildJournalSegment>) -> some View {
        modifier(ChildJournalSegmentSwipeModifier(selection: selection))
    }
}
