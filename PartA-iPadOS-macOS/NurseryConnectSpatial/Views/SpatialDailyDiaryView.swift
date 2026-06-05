//
//  SpatialDailyDiaryView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Full-screen daily diary view for a single child — arrival, activities, sleep, meals,
//               nappy log, wellbeing checks, and departure.
//

import SwiftUI

struct SpatialDailyDiaryView: View {
    let child: NCChild
    @Environment(\.dismiss) private var dismiss

    private var diary: NCDailyDiary { sampleDiary(for: child) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    arrivalCard
                    activityTimeline
                    sleepCard
                    mealsCard
                    nappyCard
                    wellbeingCard
                    departureCard
                }
                .padding(24)
            }
            .navigationTitle("\(child.displayName)'s Diary — Today")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .background(Color.ncBackground.ignoresSafeArea())
        }
    }

    // MARK: - Arrival

    private var arrivalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Arrival", systemImage: "arrow.down.circle.fill", color: Color.ncSecondary)
            HStack(spacing: 16) {
                statPill("Check-in", value: diary.checkInTime.formatted(date: .omitted, time: .shortened), color: Color.ncSecondary)
                statPill("Dropped off by", value: diary.droppedOffBy, color: Color.ncPrimary)
                statPill("Mood", value: diary.arrivalMood.emoji + " " + diary.arrivalMood.label, color: moodColor(diary.arrivalMood))
            }
        }
        .diaryCard(accent: Color.ncSecondary)
    }

    // MARK: - Activity timeline

    private var activityTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Activity log", systemImage: "list.bullet.clipboard.fill", color: Color.ncPrimary)
            ForEach(diary.activities) { entry in
                activityRow(entry)
            }
        }
        .diaryCard(accent: Color.ncPrimary)
    }

    private func activityRow(_ entry: NCDiaryActivityEntry) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 4) {
                Text(entry.time.formatted(date: .omitted, time: .shortened))
                    .font(.ncCaption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(entry.emoji)
                    Text(entry.activityName)
                        .font(.ncCaption.weight(.semibold))
                    Spacer()
                    Text(entry.duration)
                        .font(.ncCaption2)
                        .foregroundStyle(.secondary)
                }
                eyfsAreaBadge(entry.eyfsArea)
                if let obs = entry.observation {
                    Text(obs)
                        .font(.ncCaption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func eyfsAreaBadge(_ area: String) -> some View {
        let color = NurseryTheme.EYFS.color(for: area)
        return Text(area)
            .font(.ncCaption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
    }

    // MARK: - Sleep

    @ViewBuilder
    private var sleepCard: some View {
        if let sleep = diary.sleep {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Sleep log", systemImage: "moon.zzz.fill", color: Color(red: 0.4, green: 0.3, blue: 0.8))
                HStack(spacing: 16) {
                    statPill("Start", value: sleep.startTime.formatted(date: .omitted, time: .shortened), color: Color.ncPrimary)
                    statPill("End", value: sleep.endTime.formatted(date: .omitted, time: .shortened), color: Color.ncPrimary)
                    statPill("Duration", value: sleep.duration, color: Color.ncSecondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)).frame(height: 12)
                        RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.4, green: 0.3, blue: 0.8)).frame(width: geo.size.width * 0.65, height: 12)
                    }
                }
                .frame(height: 12)
            }
            .diaryCard(accent: Color(red: 0.4, green: 0.3, blue: 0.8))
        }
    }

    // MARK: - Meals

    private var mealsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Meal log", systemImage: "fork.knife", color: Color.ncAccentWarm)
            ForEach(diary.meals, id: \.mealName) { meal in
                VStack(alignment: .leading, spacing: 8) {
                    Text(meal.mealName)
                        .font(.ncCaption.weight(.semibold))
                    ForEach(meal.items) { item in
                        HStack {
                            Text(item.name).font(.ncCaption2)
                            Spacer()
                            consumptionBar(item.consumption)
                        }
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill").foregroundStyle(Color.ncPrimary).font(.ncCaption2)
                        Text("\(meal.fluidMl) ml").font(.ncCaption2)
                    }
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .diaryCard(accent: Color.ncAccentWarm)
    }

    private func consumptionBar(_ level: NCConsumptionLevel) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { segment in
                RoundedRectangle(cornerRadius: 2)
                    .fill(segment <= level.rawValue ? consumptionColor(level) : Color.white.opacity(0.15))
                    .frame(width: 12, height: 8)
            }
        }
        .accessibilityLabel(level.label)
    }

    private func consumptionColor(_ level: NCConsumptionLevel) -> Color {
        switch level {
        case .all, .most: return Color.ncSecondary
        case .half: return Color.ncAccentWarm
        case .little, .none: return Color.ncDanger
        }
    }

    // MARK: - Nappy

    private var nappyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Nappy / toilet log", systemImage: "pencil.and.list.clipboard", color: Color.ncPrimary)
            ForEach(diary.nappyLog) { entry in
                HStack {
                    Image(systemName: "clock").font(.ncCaption2).foregroundStyle(.secondary)
                    Text(entry.time.formatted(date: .omitted, time: .shortened)).font(.ncCaption2)
                    Spacer()
                    Text(entry.type).font(.ncCaption2).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .diaryCard(accent: Color.ncPrimary)
    }

    // MARK: - Wellbeing

    private var wellbeingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Wellbeing check", systemImage: "heart.fill", color: Color(red: 0.9, green: 0.3, blue: 0.5))
            HStack(spacing: 16) {
                wellbeingPill("Morning",  mood: diary.morningWellbeing)
                wellbeingPill("Midday",   mood: diary.middayWellbeing)
                wellbeingPill("Departure", mood: diary.departureWellbeing)
            }
        }
        .diaryCard(accent: Color(red: 0.9, green: 0.3, blue: 0.5))
    }

    private func wellbeingPill(_ label: String, mood: NCMoodLevel) -> some View {
        VStack(spacing: 4) {
            Text(mood.emoji).font(.title2)
            Text(label).font(.ncCaption2).foregroundStyle(.secondary)
            Text(mood.label).font(.ncCaption2.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(moodColor(mood).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Departure

    private var departureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Departure", systemImage: "arrow.up.circle.fill", color: Color.ncSecondary)
            HStack(spacing: 16) {
                statPill("Check-out", value: diary.checkOutTime.formatted(date: .omitted, time: .shortened), color: Color.ncSecondary)
                statPill("Collected by", value: diary.collectedBy, color: Color.ncPrimary)
                statPill("Relationship", value: diary.collectorRelationship, color: Color.ncPrimary)
            }
        }
        .diaryCard(accent: Color.ncSecondary)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String, systemImage: String, color: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.ncHeadline)
            .foregroundStyle(color)
    }

    private func statPill(_ label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.ncCaption2).foregroundStyle(.secondary)
            Text(value).font(.ncCaption.weight(.semibold)).foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func moodColor(_ mood: NCMoodLevel) -> Color {
        switch mood {
        case .happy: return Color.ncSecondary
        case .neutral: return Color.ncAccentWarm
        case .upset: return Color.ncDanger
        }
    }

    // MARK: - Sample diary builder

    private func sampleDiary(for child: NCChild) -> NCDailyDiary {
        let now = Date()
        func t(_ h: Int, _ m: Int = 0) -> Date {
            Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }

        return NCDailyDiary(
            child: child,
            date: now,
            checkInTime: t(8, 30),
            droppedOffBy: "Mum",
            arrivalMood: .happy,
            activities: [
                .init(id: UUID(), time: t(9), activityName: "Arts & Crafts", emoji: "🎨",
                      eyfsArea: "Expressive Arts & Design", duration: "40 min",
                      observation: "Painted a picture of their family using bold colour choices."),
                .init(id: UUID(), time: t(10), activityName: "Story Time", emoji: "📚",
                      eyfsArea: "Communication & Language", duration: "25 min",
                      observation: "Listened attentively and answered questions about the story."),
                .init(id: UUID(), time: t(11), activityName: "Outdoor Play", emoji: "🌳",
                      eyfsArea: "Physical Development", duration: "45 min", observation: nil),
                .init(id: UUID(), time: t(14), activityName: "Educational Puzzle", emoji: "🧩",
                      eyfsArea: "Mathematics", duration: "30 min",
                      observation: "Counted pieces and sorted by shape independently."),
                .init(id: UUID(), time: t(15), activityName: "Music & Movement", emoji: "🎵",
                      eyfsArea: "Expressive Arts & Design", duration: "20 min", observation: nil),
            ],
            sleep: NCSleepEntry(startTime: t(12, 15), endTime: t(13, 30)),
            meals: [
                NCMealLogEntry(mealName: "Breakfast (08:30)", items: [
                    NCFoodItem(name: "Porridge with banana", consumption: .all),
                    NCFoodItem(name: "Orange juice", consumption: .most),
                ], fluidMl: 150),
                NCMealLogEntry(mealName: "AM Snack (10:00)", items: [
                    NCFoodItem(name: "Apple slices", consumption: .most),
                ], fluidMl: 120),
                NCMealLogEntry(mealName: "Lunch (12:00)", items: [
                    NCFoodItem(name: "Beef bolognese with pasta", consumption: .most),
                    NCFoodItem(name: "Garlic bread", consumption: .half),
                    NCFoodItem(name: "Fruit salad", consumption: .all),
                ], fluidMl: 200),
                NCMealLogEntry(mealName: "PM Snack (15:00)", items: [
                    NCFoodItem(name: "Cheese & crackers", consumption: .all),
                ], fluidMl: 100),
            ],
            nappyLog: [
                NCNappyEntry(time: t(9, 15), type: "Wet"),
                NCNappyEntry(time: t(11, 45), type: "Wet & dirty"),
                NCNappyEntry(time: t(14, 30), type: "Wet"),
            ],
            morningWellbeing: .happy,
            middayWellbeing: .happy,
            departureWellbeing: .neutral,
            checkOutTime: t(15, 45),
            collectedBy: "Dad",
            collectorRelationship: "Father"
        )
    }
}

// MARK: - Card style modifier

private struct DiaryCardModifier: ViewModifier {
    let accent: Color

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent)
                    .frame(width: 4)
                    .padding(.vertical, 12)
                    .padding(.leading, -16)
            }
            .clipped()
    }
}

private extension View {
    func diaryCard(accent: Color) -> some View {
        modifier(DiaryCardModifier(accent: accent))
    }
}
