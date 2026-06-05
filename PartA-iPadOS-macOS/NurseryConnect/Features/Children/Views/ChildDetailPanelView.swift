//
//  ChildDetailPanelView.swift
//  NurseryConnect
//
//  Feature: Children
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: iPad detail column full child profile (analytics shown via Charts segment).
//

import CoreData
import SwiftUI

/// - Description: Third column panel showing the full child profile when analytics are not active.
struct ChildDetailPanelView: View {
    let childId: UUID

    @Environment(\.managedObjectContext) private var context

    var body: some View {
        ChildProfileView(childId: childId, context: context)
            .navigationBarTitleDisplayMode(.inline)
    }
}
