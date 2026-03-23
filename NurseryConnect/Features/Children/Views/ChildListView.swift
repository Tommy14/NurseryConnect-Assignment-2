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

    var body: some View {
        List(children, id: \.objectID) { child in
            if let id = child.id {
                NavigationLink {
                    ChildProfileView(childId: id, context: context)
                } label: {
                    HStack {
                        ChildAvatarView(firstName: child.firstName ?? "", lastName: child.lastName ?? "", childId: id)
                        VStack(alignment: .leading) {
                            Text("\(child.firstName ?? "") \(child.lastName ?? "")")
                                .font(.headline)
                            Text(child.roomName ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Children")
    }
}

#Preview {
    NavigationStack {
        ChildListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
