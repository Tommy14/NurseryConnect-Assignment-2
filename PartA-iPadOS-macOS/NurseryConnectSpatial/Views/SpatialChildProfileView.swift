//
//  SpatialChildProfileView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Detailed child profile with tabs for overview, health/dietary, EYFS development, and consent.
//

import SwiftUI

struct SpatialChildProfileView: View {
    let child: NCChild
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0

    private let eyfsAreas: [NCEYFSArea] = [
        NCEYFSArea(name: "Communication & Language", stage: "Expected",  progress: 0.72),
        NCEYFSArea(name: "Physical Development",     stage: "Exceeding", progress: 0.90),
        NCEYFSArea(name: "PSED",                     stage: "Expected",  progress: 0.65),
        NCEYFSArea(name: "Literacy",                 stage: "Emerging",  progress: 0.45),
        NCEYFSArea(name: "Mathematics",              stage: "Expected",  progress: 0.68),
        NCEYFSArea(name: "Understanding the World",  stage: "Expected",  progress: 0.60),
        NCEYFSArea(name: "Expressive Arts & Design", stage: "Exceeding", progress: 0.88),
    ]

    private let milestones: [NCMilestoneEntry] = [
        NCMilestoneEntry(date: Date().addingTimeInterval(-7 * 86400),
                         area: "Communication & Language",
                         description: "Initiated a role-play conversation with peers unprompted."),
        NCMilestoneEntry(date: Date().addingTimeInterval(-14 * 86400),
                         area: "Physical Development",
                         description: "Demonstrated confident balancing on one leg for 5+ seconds."),
        NCMilestoneEntry(date: Date().addingTimeInterval(-21 * 86400),
                         area: "Mathematics",
                         description: "Counted a set of 8 objects correctly and could identify 'more' and 'fewer'."),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                profileHeader
                Divider()
                tabPicker
                Divider()
                ScrollView {
                    Group {
                        switch selectedTab {
                        case 0: overviewTab
                        case 1: healthTab
                        case 2: eyfsTab
                        case 3: consentTab
                        default: overviewTab
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Child Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(NurseryTheme.primary.opacity(0.2))
                    .frame(width: 64, height: 64)
                Text(child.initials)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(NurseryTheme.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(child.fullName)
                    .font(.ncTitle3)
                if !child.preferredName.isEmpty && child.preferredName != child.firstName {
                    Text("Preferred: \(child.preferredName)")
                        .font(.ncCaption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Text(child.room)
                        .font(.ncCaption.weight(.semibold))
                        .foregroundStyle(Color.ncPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.ncPrimary.opacity(0.12), in: Capsule())
                    attendanceBadge
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Age \(child.age)")
                    .font(.ncCaption.weight(.semibold))
                Text(child.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                    .font(.ncCaption2)
                    .foregroundStyle(.secondary)
                Text("KW: \(child.keyworkerName)")
                    .font(.ncCaption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color.ncBackground)
    }

    private var attendanceBadge: some View {
        let (label, color): (String, Color) = {
            switch child.status {
            case .onSite:          return ("On Site", Color.ncSecondary)
            case .awaitingArrival: return ("Awaiting", .secondary)
            case .checkedOut:      return ("Checked Out", Color.ncPrimary)
            case .absent:          return ("Absent", Color.ncDanger)
            }
        }()
        return Text(label)
            .font(.ncCaption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }

    // MARK: - Tab picker

    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            Text("Overview").tag(0)
            Text("Health").tag(1)
            Text("EYFS").tag(2)
            Text("Consent").tag(3)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Overview tab

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !child.allergies.isEmpty {
                Label("Alert at Mealtimes — allergen(s) on file", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.ncAccentWarm)
                    .font(.ncCaption.weight(.semibold))
                    .padding(12)
                    .background(Color.ncAccentWarm.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            profileInfoCard("Room & Keyworker") {
                infoRow("Room", value: child.room)
                infoRow("Keyworker", value: child.keyworkerName)
            }

            profileInfoCard("Emergency Contact") {
                infoRow("Name", value: "Parent / Guardian")
                infoRow("Relationship", value: "Parent")
                infoRow("Phone", value: "07••• ••• 123")
            }

            if !child.dietaryRestrictions.isEmpty {
                profileInfoCard("Dietary Restrictions") {
                    FlexTagRow(tags: child.dietaryRestrictions, color: Color.ncAccentWarm)
                }
            }
        }
    }

    // MARK: - Health tab

    private var healthTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !child.allergies.isEmpty {
                Label("Alert at Mealtimes", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.ncAccentWarm)
                    .font(.ncCaption.weight(.semibold))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.ncAccentWarm.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if !child.medicalConditions.isEmpty {
                profileInfoCard("Medical Conditions") {
                    ForEach(child.medicalConditions) { condition in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(condition.name).font(.ncCaption.weight(.semibold))
                                Text(condition.note).font(.ncCaption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            conditionSeverityBadge(condition.severity)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !child.allergies.isEmpty {
                profileInfoCard("Allergy Profile") {
                    ForEach(child.allergies) { allergen in
                        HStack(alignment: .top, spacing: 10) {
                            Text(allergen.emoji).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(allergen.name).font(.ncCaption.weight(.semibold))
                                Text(allergen.avoidanceNote).font(.ncCaption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(allergen.severity.emoji + " " + allergen.severity.rawValue)
                                .font(.ncCaption2.weight(.semibold))
                                .foregroundStyle(allergenSeverityColor(allergen.severity))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !child.dietaryRestrictions.isEmpty {
                profileInfoCard("Dietary Restrictions") {
                    FlexTagRow(tags: child.dietaryRestrictions, color: Color.ncSecondary)
                }
            }
        }
    }

    // MARK: - EYFS tab

    private var eyfsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(eyfsAreas) { area in
                    eyfsAreaCard(area)
                }
            }
            profileInfoCard("Recent Milestones") {
                ForEach(milestones) { milestone in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(milestone.area).font(.ncCaption.weight(.semibold))
                            Spacer()
                            Text(milestone.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.ncCaption2).foregroundStyle(.secondary)
                        }
                        Text(milestone.description).font(.ncCaption2).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func eyfsAreaCard(_ area: NCEYFSArea) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .stroke(area.color.opacity(0.25), lineWidth: 6)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: area.progress)
                    .stroke(area.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(area.progress * 100))%")
                    .font(.ncCaption2.weight(.bold))
                    .foregroundStyle(area.color)
            }
            Text(area.name)
                .font(.ncCaption2.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(area.stage)
                .font(.ncCaption2)
                .foregroundStyle(area.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(area.color.opacity(0.15), in: Capsule())
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Consent tab

    private var consentTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !child.photoConsent {
                Text("⛔ NO PHOTOGRAPHY CONSENT")
                    .font(.ncHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.ncDanger, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            profileInfoCard("Consent Status") {
                consentRow("Photography", granted: child.photoConsent)
                consentRow("Social media", granted: child.socialMediaConsent)
                consentRow("GPS tracking", granted: true)
                consentRow("Video recording", granted: child.photoConsent)
                consentRow("Medical treatment", granted: true)
            }

            profileInfoCard("Documents") {
                documentRow("Immunisation records", date: Date().addingTimeInterval(-90 * 86400))
                documentRow("Emergency action plan", date: Date().addingTimeInterval(-30 * 86400))
                if child.medicalConditions.contains(where: { $0.severity == .critical }) {
                    documentRow("Individual healthcare plan", date: Date().addingTimeInterval(-60 * 86400))
                }
            }
        }
    }

    // MARK: - Reusable helpers

    private func profileInfoCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.ncHeadline)
            content()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.ncCaption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.ncCaption.weight(.semibold))
        }
    }

    private func consentRow(_ label: String, granted: Bool) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(granted ? Color.ncSecondary : Color.ncDanger)
            Text(label).font(.ncCaption)
            Spacer()
            Text(granted ? "Granted" : "Withdrawn")
                .font(.ncCaption2)
                .foregroundStyle(granted ? Color.ncSecondary : Color.ncDanger)
        }
        .padding(.vertical, 2)
    }

    private func documentRow(_ name: String, date: Date) -> some View {
        HStack {
            Image(systemName: "doc.fill").foregroundStyle(Color.ncPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.ncCaption)
                Text("Uploaded \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.ncCaption2).foregroundStyle(.secondary)
            }
            Spacer()
            Button("View") {}
                .font(.ncCaption2)
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
    }

    private func conditionSeverityBadge(_ severity: NCConditionSeverity) -> some View {
        let color: Color = {
            switch severity {
            case .routine:   return Color.ncSecondary
            case .important: return Color.ncAccentWarm
            case .critical:  return Color.ncDanger
            }
        }()
        return Text(severity.rawValue)
            .font(.ncCaption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
    }

    private func allergenSeverityColor(_ severity: NCAllergenSeverity) -> Color {
        switch severity {
        case .intolerance: return Color.ncAccentWarm
        case .allergy:     return Color(red: 0.95, green: 0.50, blue: 0.10)
        case .anaphylactic: return Color.ncDanger
        }
    }
}

// MARK: - Flexible tag row

private struct FlexTagRow: View {
    let tags: [String]
    let color: Color

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.ncCaption2.weight(.semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.14), in: Capsule())
            }
        }
    }
}
