//
//  DayTimelineMerger.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 18 April 2026
//  Description: Merges the shared nursery schedule with diary rows; entries nest under planned sessions by timestamp.
//

import CoreData
import Foundation

/// - Description: One row in the merged diary + schedule timeline.
enum MergedDiaryTimelineRow: Identifiable {
    /// - Description: Planned window with logs whose timestamps fall inside the segment (half-open `[start,end)`).
    case plannedSession(NurseryScheduleSegment, nestedEntries: [DiaryEntry])
    case sleep(DiaryEntry)
    /// - Description: Non-sleep entry not contained in any segment for this day (e.g. mis-timed log).
    case orphanDiary(DiaryEntry)

    var id: String {
        switch self {
        case .plannedSession(let seg, _):
            return "planned-\(seg.block.id)-\(seg.start.timeIntervalSince1970)"
        case .sleep(let entry):
            return "sleep-\(entry.objectID.uriRepresentation().absoluteString)"
        case .orphanDiary(let entry):
            return "orphan-\(entry.objectID.uriRepresentation().absoluteString)"
        }
    }

    /// - Description: Start time used for ordering and “past” collapse.
    var intervalStart: Date {
        switch self {
        case .plannedSession(let seg, _):
            return seg.start
        case .sleep(let entry), .orphanDiary(let entry):
            return entry.timestamp ?? .distantPast
        }
    }

    /// - Description: End time for “past” detection.
    var intervalEnd: Date {
        switch self {
        case .plannedSession(let seg, _):
            return seg.end
        case .sleep(let entry):
            let start = entry.timestamp ?? .distantPast
            return start.addingTimeInterval(TimeInterval(max(0, entry.duration)) * 60)
        case .orphanDiary(let entry):
            return DayTimelineMerger.diaryEntryEnd(entry)
        }
    }
}

enum DayTimelineMerger {
    /// - Description: Nursery timetable segments for `referenceDay` (meals + activity pieces with sleep intervals removed). Matches the merged timeline.
    static func plannedSegmentsForDay(
        entries: [DiaryEntry],
        referenceDay: Date,
        calendar: Calendar = .current
    ) -> [NurseryScheduleSegment] {
        let sleepEntries = entries.filter { DiaryEntryType.fromPersistence($0.entryType ?? "") == .sleep }
        let sleepIntervals = sleepEntries.compactMap { entry -> (Date, Date)? in
            guard let start = entry.timestamp else { return nil }
            let end = start.addingTimeInterval(TimeInterval(max(1, entry.duration)) * 60)
            return (start, end)
        }
        var segments: [NurseryScheduleSegment] = []
        for block in NurseryDaySchedule.defaultBlocks {
            let blockStart = NurseryDaySchedule.startDate(for: block, on: referenceDay, calendar: calendar)
            let blockEnd = NurseryDaySchedule.endDate(for: block, on: referenceDay, calendar: calendar)
            switch block.kind {
            case .meal:
                segments.append(NurseryScheduleSegment(block: block, start: blockStart, end: blockEnd))
            case .activity:
                let pieces = subtractIntervals(
                    from: blockStart..<blockEnd,
                    removing: sleepIntervals
                )
                for range in pieces {
                    segments.append(NurseryScheduleSegment(block: block, start: range.lowerBound, end: range.upperBound))
                }
            }
        }
        return segments
    }

    /// - Description: True when every planned segment has at least one non-sleep log with timestamp in `[start, end)` (dashboard “complete” day).
    static func allPlannedSessionsHaveAtLeastOneLog(
        entries: [DiaryEntry],
        referenceDay: Date,
        calendar: Calendar = .current
    ) -> Bool {
        let segments = plannedSegmentsForDay(entries: entries, referenceDay: referenceDay, calendar: calendar)
        if segments.isEmpty { return true }
        let nonSleep = entries.filter { DiaryEntryType.fromPersistence($0.entryType ?? "") != .sleep }
        return segments.allSatisfy { seg in
            nonSleep.contains { entry in
                guard let t = entry.timestamp else { return false }
                return t >= seg.start && t < seg.end
            }
        }
    }

    /// - Description: Builds a chronological merged list: planned sessions with nested logs, sleep rows, and orphan diaries.
    /// - Parameters:
    ///   - entries: Today’s diary rows for the child (any sort; will be re-sorted).
    ///   - referenceDay: Calendar day anchor (usually `Date()` same day).
    ///   - calendar: Calendar for local day boundaries.
    /// - Returns: Rows sorted by `intervalStart`.
    static func mergedRows(
        entries: [DiaryEntry],
        referenceDay: Date,
        calendar: Calendar = .current
    ) -> [MergedDiaryTimelineRow] {
        let sorted = entries.sorted {
            ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast)
        }
        let sleepEntries = sorted.filter { DiaryEntryType.fromPersistence($0.entryType ?? "") == .sleep }
        let nonSleep = sorted.filter { DiaryEntryType.fromPersistence($0.entryType ?? "") != .sleep }

        let segments = plannedSegmentsForDay(entries: sorted, referenceDay: referenceDay, calendar: calendar)

        var nestedBySegmentKey: [String: [DiaryEntry]] = [:]
        var orphans: [DiaryEntry] = []

        for entry in nonSleep {
            guard let ts = entry.timestamp else {
                orphans.append(entry)
                continue
            }
            if let seg = segments.first(where: { ts >= $0.start && ts < $0.end }) {
                let key = segmentKey(seg)
                nestedBySegmentKey[key, default: []].append(entry)
            } else {
                orphans.append(entry)
            }
        }

        for key in nestedBySegmentKey.keys {
            nestedBySegmentKey[key]?.sort {
                ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast)
            }
        }

        var keyedRows: [(Date, MergedDiaryTimelineRow)] = []

        for seg in segments {
            let key = segmentKey(seg)
            let nested = nestedBySegmentKey[key] ?? []
            keyedRows.append((seg.start, .plannedSession(seg, nestedEntries: nested)))
        }

        for entry in sleepEntries {
            guard let ts = entry.timestamp else { continue }
            keyedRows.append((ts, .sleep(entry)))
        }

        for entry in orphans {
            guard let ts = entry.timestamp else { continue }
            keyedRows.append((ts, .orphanDiary(entry)))
        }

        return keyedRows.sorted { lhs, rhs in
            if lhs.0 != rhs.0 {
                return lhs.0 < rhs.0
            }
            return rowTieBreaker(lhs.1) < rowTieBreaker(rhs.1)
        }.map(\.1)
    }

    private static func segmentKey(_ seg: NurseryScheduleSegment) -> String {
        "\(seg.block.id)|\(seg.start.timeIntervalSince1970)"
    }

    /// - Description: Sleep intervals for dashboard “Sleeping” label.
    static func sleepIntervals(from entries: [DiaryEntry]) -> [(start: Date, end: Date)] {
        entries
            .filter { DiaryEntryType.fromPersistence($0.entryType ?? "") == .sleep }
            .compactMap { entry -> (Date, Date)? in
                guard let start = entry.timestamp else { return nil }
                let end = start.addingTimeInterval(TimeInterval(max(1, entry.duration)) * 60)
                return (start, end)
            }
    }

    // MARK: - Private

    private static func rowTieBreaker(_ row: MergedDiaryTimelineRow) -> Int {
        switch row {
        case .sleep: return 0
        case .plannedSession: return 1
        case .orphanDiary: return 2
        }
    }

    /// - Description: `base` minus union of `remove` intervals (half-open `[start,end)` style via Date).
    private static func subtractIntervals(from base: Range<Date>, removing remove: [(Date, Date)]) -> [Range<Date>] {
        var ranges: [Range<Date>] = [base]
        for (rs, re) in remove.sorted(by: { $0.0 < $1.0 }) {
            var next: [Range<Date>] = []
            for r in ranges {
                next.append(contentsOf: subtractOne(from: r, removingStart: rs, removingEnd: re))
            }
            ranges = next
            if ranges.isEmpty { break }
        }
        return ranges
    }

    private static func subtractOne(from range: Range<Date>, removingStart rs: Date, removingEnd re: Date) -> [Range<Date>] {
        if re <= range.lowerBound || rs >= range.upperBound { return [range] }
        var out: [Range<Date>] = []
        if rs > range.lowerBound {
            out.append(range.lowerBound..<min(rs, range.upperBound))
        }
        if re < range.upperBound {
            out.append(max(re, range.lowerBound)..<range.upperBound)
        }
        return out.filter { $0.lowerBound < $0.upperBound }
    }

    static func diaryEntryEnd(_ entry: DiaryEntry) -> Date {
        let start = entry.timestamp ?? .distantPast
        let type = DiaryEntryType.fromPersistence(entry.entryType ?? "")
        switch type {
        case .activity, .sleep:
            let mins = max(0, entry.duration)
            return start.addingTimeInterval(TimeInterval(mins) * 60)
        default:
            return start
        }
    }
}
