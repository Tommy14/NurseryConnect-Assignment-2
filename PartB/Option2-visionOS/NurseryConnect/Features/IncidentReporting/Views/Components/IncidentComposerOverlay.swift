//
//  IncidentComposerOverlay.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Modal overlay presentation for the multi-step new incident form on iPad.
//

import CoreData
import SwiftUI

/// - Description: Presents `NewIncidentFormView` as a centred system-style sheet over the entire iPad shell.
struct IncidentComposerOverlay: View {
    @ObservedObject var viewModel: IncidentViewModel
    @Binding var isPresented: Bool
    var existingIncident: Incident?

    @Environment(\.managedObjectContext) private var context

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack(alignment: .top) {
                    Color.ncBackground.opacity(0.55)
                    LinearGradient(
                        colors: [
                            Color.ncGlowBlue.opacity(0.14),
                            Color.ncGlowViolet.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 360)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

                NewIncidentFormView(
                    viewModel: viewModel,
                    existingIncident: existingIncident,
                    embedsInOverlay: true,
                    onDismiss: { isPresented = false }
                )
                .environment(\.managedObjectContext, context)
                .frame(width: min(880, geo.size.width - 64))
                .frame(maxHeight: min(860, geo.size.height - 56))
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .shadow(color: Color.black.opacity(0.16), radius: 48, x: 0, y: 24)
                .shadow(color: Color.ncGlowBlue.opacity(0.14), radius: 32, x: 0, y: 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
    }
}
