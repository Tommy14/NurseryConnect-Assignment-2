//
//  SpatialAttendanceView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Attendance check-in/out grid with ratios panel for visionOS.
//

import SwiftUI

struct SpatialAttendanceView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var dataStore: SpatialDataStore

    @State private var records: [NCAttendanceRecord] = []
    @State private var checkInRecord:  NCAttendanceRecord?
    @State private var checkOutRecord: NCAttendanceRecord?

    private let columns = [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                attendanceGrid
                ratiosPanel
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            LinearGradient(
                colors: [Color.ncBackground, Color.ncGlowBlue.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        .task { records = dataStore.attendance }
        .sheet(item: $checkInRecord) { rec in
            CheckInSheet(record: binding(for: rec), onDone: { checkInRecord = nil })
        }
        .sheet(item: $checkOutRecord) { rec in
            CheckOutSheet(record: binding(for: rec), onDone: { checkOutRecord = nil })
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Attendance")
                    .font(.ncLargeTitle)
                Text("\(onSiteCount) on site · \(awaitingCount) awaiting · \(Date(), style: .date)")
                    .font(.ncBody)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Done") { dismissWindow(id: SpatialWindowID.attendance) }
                .buttonStyle(.bordered)
        }
    }

    // MARK: - Grid

    private var attendanceGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(records.indices, id: \.self) { idx in
                childAttendanceCard(recordBinding: $records[idx])
            }
        }
    }

    private func childAttendanceCard(recordBinding: Binding<NCAttendanceRecord>) -> some View {
        let rec = recordBinding.wrappedValue
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(avatarColor(for: rec.child))
                        .frame(width: 44, height: 44)
                    Text(rec.child.initials)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.child.displayName)
                        .font(.ncHeadline)
                    Text(rec.child.room)
                        .font(.ncCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            statusBadge(for: rec.status)

            if let t = rec.checkInTime {
                Label("In: \(t, style: .time)", systemImage: "arrow.down.circle")
                    .font(.ncCaption)
                    .foregroundStyle(.secondary)
            } else {
                Label("Session: 08:00–15:30", systemImage: "clock")
                    .font(.ncCaption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            if rec.status == .awaitingArrival {
                Button("Check In") {
                    checkInRecord = rec
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.ncSecondary)
                .frame(maxWidth: .infinity)
                .controlSize(.small)
            } else if rec.status == .onSite {
                Button("Check Out") {
                    checkOutRecord = rec
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        #if os(visionOS)
        .hoverEffect(.highlight)
        #endif
    }

    // MARK: - Ratios

    private var ratiosPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Staff-to-child ratios")
                .font(.ncHeadline)
            HStack(spacing: 16) {
                ForEach(ratioGroups) { group in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(group.isCompliant ? Color.ncSecondary : Color.ncDanger)
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.label)
                                .font(.ncCaption.weight(.semibold))
                            Text(group.isCompliant ? group.ratio + " ✅" : group.ratio + " ⚠️ Understaffed")
                                .font(.ncCaption)
                                .foregroundStyle(group.isCompliant ? .secondary : Color.ncDanger)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var onSiteCount: Int { records.filter { $0.status == .onSite }.count }
    private var awaitingCount: Int { records.filter { $0.status == .awaitingArrival }.count }

    private var ratioGroups: [NCStaffRatioGroup] {
        let onSiteUnder2 = records.filter { $0.status == .onSite && $0.child.age < 2 }.count
        let onSite2yr    = records.filter { $0.status == .onSite && $0.child.age == 2 }.count
        let onSite3to5   = records.filter { $0.status == .onSite && $0.child.age >= 3 }.count
        return [
            NCStaffRatioGroup(label: "Under 2s",    ratio: "1:3",  onSiteCount: max(1, onSiteUnder2 / 3), requiredStaff: max(1, onSiteUnder2 / 3)),
            NCStaffRatioGroup(label: "2-year-olds", ratio: "1:4",  onSiteCount: max(1, onSite2yr / 4), requiredStaff: max(1, onSite2yr / 4)),
            NCStaffRatioGroup(label: "3–5 years",   ratio: "1:8",  onSiteCount: 1, requiredStaff: max(1, onSite3to5 / 8)),
        ]
    }

    private func binding(for rec: NCAttendanceRecord) -> Binding<NCAttendanceRecord> {
        guard let idx = records.firstIndex(where: { $0.id == rec.id }) else {
            return .constant(rec)
        }
        return $records[idx]
    }

    private func avatarColor(for child: NCChild) -> Color {
        let palette: [Color] = [.ncPrimary, Color.ncSecondary, .ncAccentWarm, Color(red: 0.55, green: 0.25, blue: 0.90)]
        let idx = abs(child.firstName.hashValue) % palette.count
        return palette[idx]
    }

    @ViewBuilder
    private func statusBadge(for status: NCAttendanceStatus) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case .onSite:          return ("On Site", Color.ncSecondary)
            case .awaitingArrival: return ("Awaiting Arrival", Color.secondary)
            case .checkedOut:      return ("Checked Out", Color.ncPrimary)
            case .absent:          return ("Absent", Color.ncDanger)
            }
        }()
        Text(label)
            .font(.ncCaption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.14), in: Capsule())
    }
}

// MARK: - Check In Sheet

private struct CheckInSheet: View {
    @Binding var record: NCAttendanceRecord
    let onDone: () -> Void

    @State private var droppedBy = ""
    @State private var mood: NCMoodLevel = .happy
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    Text(record.child.fullName)
                        .font(.ncHeadline)
                }
                Section("Drop-off") {
                    TextField("Who dropped off?", text: $droppedBy)
                    moodPicker
                }
                Section("Notes") {
                    TextField("Any notes from parent?", text: $notes, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Check In \(record.child.displayName)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDone)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("✅ Check In") {
                        record.status = .onSite
                        record.checkInTime = Date()
                        record.droppedOffBy = droppedBy
                        record.arrivalMood = mood
                        record.notes = notes
                        onDone()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.ncSecondary)
                }
            }
        }
    }

    private var moodPicker: some View {
        HStack(spacing: 0) {
            ForEach(NCMoodLevel.allCases.reversed(), id: \.self) { level in
                Button {
                    mood = level
                } label: {
                    Text(level.emoji)
                        .font(.title)
                        .padding(8)
                        .background(
                            mood == level
                            ? Color.ncPrimary.opacity(0.2)
                            : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Check Out Sheet

private struct CheckOutSheet: View {
    @Binding var record: NCAttendanceRecord
    let onDone: () -> Void

    @State private var collectorName = ""
    @State private var relationship  = ""
    @State private var showsUnknownCollectorWarning = false

    private let authorisedCollectors = ["Mum", "Dad", "Grandmother", "Grandfather", "Guardian"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    Text(record.child.fullName).font(.ncHeadline)
                }
                Section("Collector") {
                    TextField("Collector name", text: $collectorName)
                    TextField("Relationship to child", text: $relationship)
                }
                if showsUnknownCollectorWarning {
                    Section {
                        Label("⚠️ Unrecognised collector — verify photo ID before releasing child",
                              systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.ncDanger)
                            .font(.ncCaption.weight(.semibold))
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Check Out \(record.child.displayName)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onDone) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("✅ Check Out") {
                        record.status = .checkedOut
                        record.checkOutTime = Date()
                        record.collectedBy = collectorName
                        onDone()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .onChange(of: collectorName) { _, name in
                let known = authorisedCollectors.contains { name.localizedCaseInsensitiveContains($0) }
                showsUnknownCollectorWarning = !name.isEmpty && !known
            }
        }
    }
}
