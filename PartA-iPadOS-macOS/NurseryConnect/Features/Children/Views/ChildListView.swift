//
//  ChildListView.swift
//  NurseryConnect
//
//  Feature: Children
//  Role: Keyworker
//  Created: 9 April 2026
//  Description: Simple roster of assigned children linking into profile detail.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 090426     Tommy1914   Created the file with navigation into `ChildProfileView`.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Secondary list-based entry point to child profiles (mirrors dashboard data).
struct ChildListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)],
        predicate: NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName),
        animation: .default
    )
    private var children: FetchedResults<Child>

    @State private var searchText = ""

    private var filteredChildren: [Child] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return Array(children) }
        return children.filter {
            ($0.firstName ?? "").localizedCaseInsensitiveContains(query)
            || ($0.lastName ?? "").localizedCaseInsensitiveContains(query)
            || ($0.roomName ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List(filteredChildren, id: \.objectID) { child in
            if let id = child.id {
                NavigationLink {
                    ChildProfileView(childId: id, context: context)
                } label: {
                    HStack(spacing: 12) {
                        ChildAvatarView(firstName: child.firstName ?? "", lastName: child.lastName ?? "", childId: id)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(child.fullDisplayName)
                                .font(.headline)
                            Text(child.roomName ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search children")
        .navigationTitle("Children")
        .overlay {
            if filteredChildren.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChildListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
