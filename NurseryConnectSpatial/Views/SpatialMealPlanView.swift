//
//  SpatialMealPlanView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Weekly meal plan with allergen flags, nutritional compliance, and allergy cross-reference.
//

import SwiftUI

struct SpatialMealPlanView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var dataStore: SpatialDataStore

    @State private var plan: NCWeeklyMealPlan = .samplePlan
    @State private var weekOffset = 0
    @State private var showAllergyRef = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                weekPicker
                mealGrid
                complianceSummary
                allergyReferenceSection
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            LinearGradient(
                colors: [Color.ncBackground, Color.ncGlowBlue.opacity(0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meal Plan")
                    .font(.ncLargeTitle)
                Text("Little Stars Nursery & Daycare · Spring/Summer menu")
                    .font(.ncBody)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Done") { dismissWindow(id: SpatialWindowID.mealPlan) }
                .buttonStyle(.bordered)
        }
    }

    // MARK: - Week picker

    private var weekPicker: some View {
        HStack(spacing: 16) {
            Button { weekOffset -= 1 } label: {
                Image(systemName: "chevron.left").font(.body.weight(.semibold))
            }
            .buttonStyle(.bordered)
            Text(plan.weekLabel)
                .font(.ncHeadline)
            Button { weekOffset += 1 } label: {
                Image(systemName: "chevron.right").font(.body.weight(.semibold))
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Meal grid

    private var mealGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(plan.days) { day in
                    dayColumn(day)
                }
            }
        }
    }

    private func dayColumn(_ day: NCDayMeals) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.day)
                .font(.ncHeadline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)
            mealCell(day.breakfast,  label: "Breakfast")
            mealCell(day.amSnack,    label: "AM Snack")
            mealCell(day.lunch,      label: "Lunch", highlight: true)
            mealCell(day.pmSnack,    label: "PM Snack")
        }
        .padding(14)
        .frame(width: 200, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func mealCell(_ meal: NCMealEntry, label: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.ncCaption2.weight(.heavy))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(meal.name)
                .font(.ncCaption.weight(highlight ? .semibold : .regular))
                .fixedSize(horizontal: false, vertical: true)

            if !meal.allergens.isEmpty {
                FlexAllergenRow(allergens: meal.allergens)
            }

            HStack(spacing: 4) {
                switch meal.nutritionalPass {
                case .pass:
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.ncSecondary)
                    Text("Compliant").foregroundStyle(Color.ncSecondary)
                case .borderline:
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.ncAccentWarm)
                    Text("Check").foregroundStyle(Color.ncAccentWarm)
                case .fail:
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.ncDanger)
                    Text("Non-compliant").foregroundStyle(Color.ncDanger)
                }
            }
            .font(.ncCaption2)
        }
        .padding(10)
        .background(
            highlight
                ? Color.ncPrimary.opacity(0.08)
                : Color.white.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    // MARK: - Compliance summary

    private var complianceSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutritional compliance — this week")
                .font(.ncHeadline)
            VStack(alignment: .leading, spacing: 8) {
                complianceRow("✅", label: "Oily fish: 1× this week (Wed — Salmon fishcakes)")
                complianceRow("✅", label: "Red meat: 2× this week (Mon, Thu)")
                complianceRow("✅", label: "Fruit & veg: Every meal service")
                complianceRow("⚠️", label: "Processed meat: Check Thursday PM snack", warning: true)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func complianceRow(_ icon: String, label: String, warning: Bool = false) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(warning ? Color.ncAccentWarm : Color.ncSecondary)
                .frame(width: 8, height: 8)
            Text("\(icon) \(label)")
                .font(.ncCaption)
                .foregroundStyle(warning ? Color.ncAccentWarm : .primary)
        }
    }

    // MARK: - Allergy cross-reference

    private var allergyReferenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { showAllergyRef.toggle() }
            } label: {
                HStack {
                    Text("Today's lunch — children's allergy cross-reference")
                        .font(.ncHeadline)
                    Spacer()
                    Image(systemName: showAllergyRef ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                }
            }
            .buttonStyle(.plain)

            if showAllergyRef {
                VStack(spacing: 8) {
                    allergyRefRow("Amy K.", note: "Strawberry-free (no strawberry dessert)", color: .ncDanger)
                    allergyRefRow("Ayaan G.", note: "No egg — confirm binder in fishcakes")
                    allergyRefRow("Jith Y.", note: "Dairy-free milk required", color: .ncAccentWarm)
                    allergyRefRow("Kavi A.", note: "Vegetarian — no pork/meat option; verify no cross-contamination", color: .ncDanger)
                    allergyRefRow("Mina P.", note: "Tree nut-free; check Wed granola not served", color: .ncAccentWarm)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func allergyRefRow(_ name: String, note: String, color: Color = Color.ncPrimary) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "allergens")
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.ncCaption.weight(.semibold))
                Text(note).font(.ncCaption2).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Allergen pill row (wrapping)

private struct FlexAllergenRow: View {
    let allergens: [NCAllergenTag]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40, maximum: 80), spacing: 4)], alignment: .leading, spacing: 4) {
            ForEach(allergens, id: \.self) { tag in
                Text(tag.emoji)
                    .font(.ncCaption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.ncDanger.opacity(0.15), in: Capsule())
                    .accessibilityLabel(tag.shortName)
            }
        }
    }
}
