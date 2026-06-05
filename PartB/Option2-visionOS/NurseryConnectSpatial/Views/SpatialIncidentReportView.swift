//
//  SpatialIncidentReportView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Structured incident report form with body map, severity assessment, and EYFS compliance alerts.
//

import SwiftUI

struct SpatialIncidentReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: SpatialDataStore

    @State private var selectedChildName = "Amy K."
    @State private var location = ""
    @State private var category: NCIncidentCategory = .accidentMinor
    @State private var description = ""
    @State private var actionTaken = ""
    @State private var witnessName = ""
    @State private var firstAidRequired = false
    @State private var firstAiderName = ""
    @State private var parentNotificationRequired = true
    @State private var ofstedNotification = false
    @State private var bodyMapPoints: [CGPoint] = []
    @State private var showsSubmitAlert = false
    @State private var showsSubmittedConfirmation = false

    private let timestamp = Date()

    var body: some View {
        NavigationStack {
            Form {
                childContextSection
                categorySection
                bodyMapSection
                descriptionSection
                severitySection
            }
            .formStyle(.grouped)
            .navigationTitle("New Incident Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: { dismiss() }) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit for Review") { showsSubmitAlert = true }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.ncPrimary)
                        .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Submit incident report?", isPresented: $showsSubmitAlert) {
                Button("Submit", role: .destructive) { showsSubmittedConfirmation = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This incident will be submitted for manager review. Parents must be notified the same day per EYFS requirements.")
            }
            .alert("Report submitted ✅", isPresented: $showsSubmittedConfirmation) {
                Button("Done") { dismiss() }
            } message: {
                Text("Incident logged at \(timestamp.formatted(date: .abbreviated, time: .shortened)). Notify the parent today as required by EYFS statutory guidance.")
            }
        }
    }

    // MARK: - Section 1: Child & Context

    private var childContextSection: some View {
        Section("Child & Context") {
            Picker("Child", selection: $selectedChildName) {
                ForEach(dataStore.children.map(\.fullName), id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Text("Date & time")
                Spacer()
                Text(timestamp.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
                    .font(.ncCaption)
            }
            Text("Recorded automatically")
                .font(.ncCaption2)
                .foregroundStyle(.tertiary)

            TextField("Location (e.g. Outdoor play area)", text: $location)
        }
    }

    // MARK: - Section 2: Category

    private var categorySection: some View {
        Section("Incident category") {
            ForEach(NCIncidentCategory.allCases, id: \.self) { cat in
                Button {
                    category = cat
                } label: {
                    HStack {
                        Image(systemName: cat.symbol)
                            .foregroundStyle(severityColor(for: cat))
                            .frame(width: 24)
                        Text(cat.rawValue)
                            .font(.ncCaption)
                        Spacer()
                        severityBadge(for: cat)
                        if category == cat {
                            Image(systemName: "checkmark").foregroundStyle(Color.ncPrimary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Section 3: Body map

    private var bodyMapSection: some View {
        Section("Body map") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tap locations on the body outline to mark injury points.")
                    .font(.ncCaption2)
                    .foregroundStyle(.secondary)
                bodyMapCanvas
                if !bodyMapPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Marked locations:")
                            .font(.ncCaption2.weight(.semibold))
                        ForEach(bodyMapPoints.indices, id: \.self) { idx in
                            Text("• \(bodyRegionLabel(for: bodyMapPoints[idx]))")
                                .font(.ncCaption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var bodyMapCanvas: some View {
        Canvas { context, size in
            // Draw simplified child body outline
            let cx = size.width / 2
            let headR: CGFloat = 28
            let bodyTop: CGFloat = headR * 2 + 10
            let bodyH: CGFloat = 80
            let shoulderW: CGFloat = 55

            // Head
            context.stroke(
                Path { p in p.addEllipse(in: CGRect(x: cx - headR, y: 8, width: headR * 2, height: headR * 2)) },
                with: .color(.primary.opacity(0.6)), lineWidth: 2
            )
            // Body
            context.stroke(
                Path { p in
                    p.move(to: CGPoint(x: cx - shoulderW, y: bodyTop))
                    p.addLine(to: CGPoint(x: cx + shoulderW, y: bodyTop))
                    p.addLine(to: CGPoint(x: cx + 35, y: bodyTop + bodyH))
                    p.addLine(to: CGPoint(x: cx - 35, y: bodyTop + bodyH))
                    p.closeSubpath()
                },
                with: .color(.primary.opacity(0.6)), lineWidth: 2
            )
            // Arms
            context.stroke(
                Path { p in
                    p.move(to: CGPoint(x: cx - shoulderW, y: bodyTop + 10))
                    p.addLine(to: CGPoint(x: cx - shoulderW - 30, y: bodyTop + bodyH - 10))
                },
                with: .color(.primary.opacity(0.6)), lineWidth: 2
            )
            context.stroke(
                Path { p in
                    p.move(to: CGPoint(x: cx + shoulderW, y: bodyTop + 10))
                    p.addLine(to: CGPoint(x: cx + shoulderW + 30, y: bodyTop + bodyH - 10))
                },
                with: .color(.primary.opacity(0.6)), lineWidth: 2
            )
            // Legs
            context.stroke(
                Path { p in
                    p.move(to: CGPoint(x: cx - 20, y: bodyTop + bodyH))
                    p.addLine(to: CGPoint(x: cx - 25, y: bodyTop + bodyH + 70))
                },
                with: .color(.primary.opacity(0.6)), lineWidth: 2
            )
            context.stroke(
                Path { p in
                    p.move(to: CGPoint(x: cx + 20, y: bodyTop + bodyH))
                    p.addLine(to: CGPoint(x: cx + 25, y: bodyTop + bodyH + 70))
                },
                with: .color(.primary.opacity(0.6)), lineWidth: 2
            )

            // Draw injury points
            for pt in bodyMapPoints {
                context.fill(
                    Path(ellipseIn: CGRect(x: pt.x - 8, y: pt.y - 8, width: 16, height: 16)),
                    with: .color(.red.opacity(0.85))
                )
            }
        }
        .frame(height: 260)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0).onEnded { val in
                withAnimation(.spring(response: 0.25)) {
                    bodyMapPoints.append(val.location)
                }
            }
        )
        .overlay(alignment: .bottomTrailing) {
            if !bodyMapPoints.isEmpty {
                Button("Clear") { bodyMapPoints.removeAll() }
                    .font(.ncCaption2)
                    .padding(8)
            }
        }
    }

    // MARK: - Section 4: Description

    private var descriptionSection: some View {
        Section("Description & Actions") {
            VStack(alignment: .leading) {
                Text("Incident description")
                    .font(.ncCaption2)
                    .foregroundStyle(.secondary)
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .font(.ncCaption)
            }
            VStack(alignment: .leading) {
                Text("Immediate action taken")
                    .font(.ncCaption2)
                    .foregroundStyle(.secondary)
                TextEditor(text: $actionTaken)
                    .frame(minHeight: 60)
                    .font(.ncCaption)
            }
            TextField("Witness name (if applicable)", text: $witnessName)
        }
    }

    // MARK: - Section 5: Severity

    private var severitySection: some View {
        Section("Severity assessment") {
            Toggle("First aid required", isOn: $firstAidRequired)
            if firstAidRequired {
                TextField("First-aider name", text: $firstAiderName)
            }
            HStack {
                Toggle("Parent must be notified same day", isOn: $parentNotificationRequired)
                    .disabled(true)
                Image(systemName: "lock.fill").foregroundStyle(.secondary).font(.ncCaption2)
            }
            Text("EYFS statutory guidance requires same-day parent notification for all reportable incidents.")
                .font(.ncCaption2)
                .foregroundStyle(.secondary)

            Toggle(
                "Requires Ofsted notification",
                isOn: $ofstedNotification
            )
            .disabled(!isSerious)
        }
    }

    // MARK: - Helpers

    private var isSerious: Bool {
        [NCIncidentCategory.accidentFirstAid, .safeguarding, .allergicReaction, .medical].contains(category)
    }

    private func severityColor(for cat: NCIncidentCategory) -> Color {
        switch cat {
        case .accidentMinor: return Color.ncSecondary
        case .accidentFirstAid, .nearMiss: return Color.ncAccentWarm
        case .safeguarding, .allergicReaction, .medical: return Color.ncDanger
        }
    }

    private func severityBadge(for cat: NCIncidentCategory) -> some View {
        let color = severityColor(for: cat)
        let label: String = {
            switch cat {
            case .accidentMinor: return "Low"
            case .nearMiss, .accidentFirstAid: return "Moderate"
            default: return "High"
            }
        }()
        return Text(label)
            .font(.ncCaption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
    }

    private func bodyRegionLabel(for point: CGPoint) -> String {
        switch (point.x, point.y) {
        case (_, ..<64):  return "Head"
        case (_, 64..<170): return point.x < 100 ? "Left arm / torso" : "Right arm / torso"
        default:           return point.x < 100 ? "Left leg" : "Right leg"
        }
    }
}
