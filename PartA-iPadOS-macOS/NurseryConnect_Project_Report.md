# NurseryConnect — Project Report
**Student:** Thamindu Vimansha  
**Module:** Mobile Application Design & Development (MADD) — Assignment 2  
**Platform:** iOS 17+ (iPad & iPhone) · visionOS 1+  
**Date:** June 2026

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture & Technical Foundation](#2-architecture--technical-foundation)
3. [Features Added After 22nd April 2026](#3-features-added-after-22nd-april-2026)
4. [Features Enhanced After 22nd April 2026](#4-features-enhanced-after-22nd-april-2026)
5. [Technologies & Frameworks Used](#5-technologies--frameworks-used)
6. [Advanced Libraries](#6-advanced-libraries)
7. [iPadOS Native Features](#7-ipados-native-features)
8. [visionOS Spatial Application](#8-visionos-spatial-application)
9. [Core Data Model](#9-core-data-model)
10. [Regulatory Compliance](#10-regulatory-compliance)
11. [Testing](#11-testing)
12. [Design Write-Up & Implementation Decisions](#12-design-write-up--implementation-decisions)
13. [AI-Driven UI Design Process](#13-ai-driven-ui-design-process)
14. [Challenges Faced](#14-challenges-faced)
15. [Learning Reflection](#15-learning-reflection)

---

## 1. Project Overview

NurseryConnect is a professional-grade childcare management application built for **Little Stars Nursery & Daycare**. It serves the daily workflows of keyworkers — the staff members directly responsible for a child's welfare, learning, and safety — and extends into spatial computing through a companion visionOS app.

The application covers four core domains:

| Domain | Description |
|---|---|
| **Daily Diary** | EYFS-aligned observation logging (meals, sleep, nappies, activities, wellbeing, milestones) |
| **Attendance** | Real-time check-in/out, authorised collector validation, staff-to-child ratio monitoring |
| **Incident Reporting** | Structured safeguarding workflow with severity classification, body-map annotations, and parent notification tracking |
| **Secure Messaging** | GDPR-scoped parent–keyworker messaging with end-of-day summaries and broadcast support |

### Target Users
- **Keyworkers** — primary role; uses the full iOS and visionOS app
- **Setting Managers** — oversight dashboard (visionOS and iPad overview)
- **Parents** — messaging thread participants (represented as message senders; not a separate app role)

### Deployment Targets
- **iOS / iPadOS:** 17.0+ (with progressive enhancement for iOS 26 Liquid Glass)
- **visionOS:** 1.0+ (volumetric RealityKit on device; 2D fallback on simulator)

---

## 2. Architecture & Technical Foundation

### Pattern: MVVM with Coordinators

```
NurseryConnectApp
  └── AdaptiveRootView            ← size-class router
        ├── KeyworkerDashboardView (compact / iPhone)
        └── KeyworkerIPadShellView (regular / iPad)
              └── KeyworkerIPadCoordinator (shared state)
```

Every feature follows **Model → ViewModel → View**:
- **Models** — Core Data NSManagedObject subclasses (`Child`, `DiaryEntry`, `AttendanceRecord`, `Incident`, `Message`, `MessageThread`)
- **ViewModels** — `@MainActor` `ObservableObject` classes that own business logic and expose `@Published` state
- **Views** — SwiftUI views that read from ViewModels via `@StateObject` / `@ObservedObject`

### Offline-First Sync
All write operations are immediately persisted to Core Data. A `SyncQueueService` runs every 90 seconds, on network reconnect, and on app foreground to push pending items to the backend. Each syncable entity carries:
- `syncState` — `synced` / `pending` / `failed`
- `syncEnqueuedAt`, `syncAttemptCount`, `lastSyncError`

### GDPR Scope Guards
Every data access is gated through scope helpers:
- `KeyworkerGDPRScope.childBelongsToKeyworker(childID:in:)` — confirms the logged-in keyworker is assigned to a child before allowing profile or analytics access
- `MessagingGDPRScope.assignedChildIDs(in:)` — returns only thread child IDs belonging to the keyworker

---

## 3. Features Added After 22nd April 2026

The following are entirely **new** modules and views introduced after the 22nd April baseline commit, representing the bulk of the sprint two work.

### 3.1 Analytics Dashboard (iPad + iPhone)

**Files:** `ChildAnalyticsDashboardView`, `MoodTrendChart`, `WeeklyActivityDistributionChart`, `ChildMonthlyAttendanceChart`, `MessageActivityChart`, `AnalyticsDataService`, `ChartDataModels`

A full analytics layer was built on top of Swift Charts. Each chart is a self-contained SwiftUI view with its own `@FetchRequest`, driven by `AnalyticsDataService` — a pure `enum` of static helper functions that transform Core Data rows into chart-ready value types.

| Chart | Type | Data Source | Key Feature |
|---|---|---|---|
| Mood Trend | Line + RuleMark | Wellbeing diary entries, last 7 days | Red dashed welfare threshold at score 2 (EYFS) |
| Weekly Activity | Bar chart | All diary entries, current week | Tap bar highlights matching journal entries |
| Monthly Attendance | Calendar dot grid | Attendance records, full current month | Green = present, Red = absent, faded = future |
| Message Activity | Compact sparkline | Parent messages, last 7 days | Embedded in journal summary card |

The analytics dashboard is GDPR-gated: if the child is not assigned to the logged-in keyworker, a `ContentUnavailableView` "Not available" state is shown instead of data.

### 3.2 Secure Messaging System

**Files:** `MessagingViewModel`, `ThreadDetailView`, `MessageInboxView`, `EndOfDaySummarySheet`, `MessagingGDPRScope`, `MessageType`, `MessageSenderRole`, `MessageInitiatorRole`, `MessageFormatting`, `MessageThreadRow`, `MessageInboxSection`

A complete messaging feature was built from Core Data entities through ViewModel to UI:

- **Inbox:** Three-tier grouping (Unread → Today → Earlier) with last-message preview, unread dot indicator, and archive swipe action
- **Thread Detail:** Chat bubble layout with automatic scroll to latest message; marks inbound messages read on open
- **Reply restrictions:** `canReply(to:)` — parent-initiated and setting-manager threads allow keyworker replies; broadcast threads display a "replies disabled" banner
- **End-of-Day Summary:** Keyworkers can compose a narrative summary of the child's day; enforces a rate limit (one per child per day, only after 3 PM) to prevent spam
- **Broadcast threads:** Setting Manager can send to all keyworkers; rendered with distinct styling and locked reply bar

### 3.3 iPad Split-View Shell

**Files:** `KeyworkerIPadShellView`, `KeyworkerIPadBottomDock`, `KeyworkerIPadCoordinator`, `AdaptiveRootView`, `ChildrenSidebarView`, `ChildSidebarRowView`

A purpose-built iPad shell using `NavigationSplitView`:

- **Sidebar (240–320 pt):** Searchable, sortable children list with compact `ChildSidebarRowView` cards showing attendance status, diary completion dot, and no-photography warning
- **Content column:** Switches between Incidents inbox and Messages inbox depending on bottom dock selection
- **Detail panel (400 pt):** Shows selected message thread or child profile
- **Minimised rail (62 pt):** When sidebar is collapsed, a narrow rail of child avatars remains visible for quick switching
- **Adaptive root:** `AdaptiveRootView` reads `horizontalSizeClass` and routes to the iPad shell on `.regular` and the standard dashboard on `.compact`

### 3.4 Child Journal View (iPad)

**Files:** `ChildJournalView`, `ChildJournalSegmentBar`, `ChildJournalSegmentSwipeModifier`, `ChildJournalSegment`, `ChildDetailPanelView`

When a child is selected in the sidebar, the trailing panel shows a journal workspace with two segments — **Daily Diary** and **Charts** — switchable by a capsule segment bar or horizontal swipe gesture. This gives keyworkers immediate access to both observational logs and analytics for the selected child without leaving the split-view layout.

### 3.5 Dashboard Quick Check-In Sheet

**Files:** `DashboardQuickCheckInSheet`

A compact sheet (`.medium` / `.large` detents) for rapidly checking a child in from the attendance card without navigating away from the dashboard. Collects dropper-off name, mood level, and freeform notes.

### 3.6 Milestone Entries View

**Files:** `MilestoneEntriesView`

A dedicated gallery-style view for milestone diary entries, surfacing the captured photo, blurred face count, and EYFS development note. Tapping opens the full entry detail.

### 3.7 visionOS Spatial App (Entirely New)

**Files:** All files in `NurseryConnectSpatial/` — 27 Swift files

An entirely new visionOS target was built alongside the iOS app. See [Section 8](#8-visionos-spatial-application) for full detail.

### 3.8 Keyworker Commands (Keyboard Shortcuts)

**File:** `KeyworkerCommands.swift`

A `Commands`-based keyboard shortcut system for iPad + external keyboard:

| Shortcut | Action |
|---|---|
| `⌘ N` | New Diary Entry |
| `⌘ I` | New Incident |
| `⌘ M` | Jump to Messages |
| `Esc` | Dismiss Sheet |

### 3.9 Journal Analytics Summary Card

**File:** `JournalAnalyticsSummaryCard`

A compact summary card embedded at the top of the journal segment, showing today's mood average, diary entry count, and a message activity sparkline — a single glance tells the keyworker if the child's day is going well before diving into the timeline.

---

## 4. Features Enhanced After 22nd April 2026

### 4.1 Incident Reporting — Redesigned

- **IncidentListView:** Rebuilt with urgency banners (parent notification alerts), compliance tile, segmented scope filter, pull-to-refresh, 60-second polling, and a `safeAreaInset` FAB positioned bottom-right with keyboard shortcut
- **IncidentComposerOverlay:** Full-screen on iPhone, side overlay on iPad — shares state via `KeyworkerIPadCoordinator`
- **IncidentDetailView:** iPad uses inline sheet overlay; iPhone uses `fullScreenCover`
- **BodyMapView:** Layout refactored for better annotation placement

### 4.2 EmptyStateView — Rewritten

Replaced the custom branded empty state with `ContentUnavailableView` (iOS 17), following Apple HIG. Optional CTA button added using `.borderedProminent` style.

### 4.3 Daily Diary — Presentation & Highlighting

- `DailyDiaryListView`: Added external add-sheet binding for iPad coordinator control
- `DiaryTimelineView`: Highlighting support for chart-driven filtering (tapping a bar in the activity chart highlights matching diary entries)
- `MilestoneEntriesView`: Dedicated gallery for milestone photos

### 4.4 ChildSidebarRowView — Polish & Accessibility

- Added `.hoverEffect(.highlight)` for pointer/trackpad interaction
- Introduced `compactDisplayName` (First + Last Initial) for space efficiency
- Diary status pill shows `exclamationmark.circle.fill` icon for no-log warning
- Full `accessibilityLabel` combining attendance, diary, and photography warning

### 4.5 Dashboard — Absent Section Collapsibility

The "Absent today" section of the keyworker dashboard now collapses independently, reducing visual noise on busy days when many children are absent.

### 4.6 Monthly Attendance — From Bar Chart to Calendar Grid

The original Swift Charts `BarMark` attendance chart was replaced with a hand-crafted `LazyVGrid` calendar dot-grid. This shows the **entire month** (all 28–31 days), with weekday headers placed inside the same grid for perfect column alignment. Green dots (present), red dots (absent), faded future days, and a today ring are the visual language.

### 4.7 FaceBlurEditorView — Refactored Selection Logic

The face selection UX was refactored to use `VNDetectFaceRectanglesRequest` more reliably, handle EXIF orientation, and cap input images at 1600 pt to reduce memory pressure.

### 4.8 AppTheme — Dynamic Type Compliance

Font functions updated from `.system(.title2, design: .rounded)` (does not scale) to `.title2.weight(.semibold)` (semantic, scales with Dynamic Type). All HIG button styles converted to `.borderedProminent` / `.bordered`.

---

## 5. Technologies & Frameworks Used

| Framework | Category | Usage |
|---|---|---|
| **SwiftUI** | UI | Primary UI framework throughout |
| **Core Data** | Persistence | All data storage; GDPR-scoped fetch predicates |
| **Swift Charts** | Visualisation | Mood trend, activity bar, message sparkline charts |
| **RealityKit** | 3D Rendering | Volumetric 3D mood bar chart in visionOS |
| **Vision** | ML / CV | Face detection in milestone photos |
| **Core Image** | Image Processing | Gaussian blur + pixelate for face blurring |
| **MapKit** | Maps | Route visualisation in visionOS Transport Tracker |
| **Combine** | Reactive | Network monitoring, ViewModel publishers |
| **Network** | Connectivity | `NWPathMonitor` for online/offline detection |
| **UserNotifications** | Alerts | Diary mood reminders for keyworkers |
| **UIKit** | Native UI | Navigation bar appearance, `UIColor` conversions |
| **Foundation** | Core | Date/calendar utilities, JSON encoding |
| **CoreGraphics** | 2D Graphics | Drawing body map annotations |

---

## 6. Advanced Libraries

### Swift Charts *(Document & Rendering category)*

Swift Charts is the approved advanced library used across three analytics charts.

**Integration depth:**

```swift
// MoodTrendChart.swift — Welfare threshold rule line
RuleMark(y: .value("Threshold", 2))
    .foregroundStyle(Color.red.opacity(0.7))
    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
    .annotation(position: .trailing) {
        Text("Review").font(.caption2).foregroundStyle(.red)
    }

// WeeklyActivityDistributionChart.swift — Tappable bar marks
BarMark(
    x: .value("Type", dataPoint.label),
    y: .value("Count", dataPoint.count)
)
.foregroundStyle(dataPoint.color)
.annotation(position: .top) { Text("\(dataPoint.count)").font(.caption2) }
```

**Why Swift Charts over a third-party library:** Native framework, zero dependency overhead, full accessibility support (VoiceOver reads each data point automatically), and seamless Dark Mode / Dynamic Type participation.

**Justification:** The analytics dashboard directly supports EYFS welfare monitoring. The welfare threshold rule line at mood score 2 creates a data-driven trigger for keyworker intervention — this is a real-world regulatory use case, not a cosmetic chart.

### RealityKit *(visionOS spatial — Document & Rendering)*

Used in `MoodChartVolumeView.swift` to render a fully volumetric 3D bar chart inside a visionOS `volumetricWindowStyle` window:

```swift
// Each mood bar as a RealityKit ModelEntity
let mesh = MeshResource.generateBox(
    size: SIMD3<Float>(barWidth, barHeight, barWidth),
    cornerRadius: 0.004
)
let material = SimpleMaterial(color: barColor, isMetallic: false)
let barEntity = ModelEntity(mesh: mesh, materials: [material])
barEntity.position = SIMD3<Float>(xOffset, floorY + barHeight / 2, 0)
root.addChild(barEntity)
```

The chart supports drag-to-rotate, welfare threshold plane, and day labels as overlaid SwiftUI text.

---

## 7. iPadOS Native Features

### 7.1 NavigationSplitView (Primary iPadOS Feature)

`KeyworkerIPadShellView` builds the entire iPad experience around `NavigationSplitView` with constrained column widths:

```swift
NavigationSplitView(columnVisibility: $splitColumnVisibility) {
    ChildrenSidebarView(...)
        .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
} detail: {
    KeyworkerIPadDetailContent(...)
}
```

This is purely an iPadOS feature — iPhones route to the standard single-column `KeyworkerDashboardView` via `AdaptiveRootView`.

### 7.2 Horizontal Size Class Adaptive Layout

```swift
@Environment(\.horizontalSizeClass) private var horizontalSizeClass

// AdaptiveRootView.swift
if horizontalSizeClass == .regular {
    KeyworkerIPadShellView(coordinator: coordinator)
} else {
    KeyworkerDashboardView(coordinator: coordinator)
}
```

Size-class checks appear in 4+ files, driving layout differences for incident composer presentation, analytics card height, and incident list sheet styles.

### 7.3 Keyboard Shortcuts (External Keyboard Support)

```swift
// KeyworkerCommands.swift
CommandMenu("Keyworker") {
    Button("New Diary Entry") { ... }.keyboardShortcut("n")
    Button("New Incident")   { ... }.keyboardShortcut("i")
    Button("Messages")       { ... }.keyboardShortcut("m")
}
```

These appear in the system menu bar on iPadOS when an external keyboard is connected — a standard iPadOS pro-user expectation.

### 7.4 Hover Effect (Pointer / Trackpad)

```swift
// ChildSidebarRowView.swift
.hoverEffect(.highlight)
```

Applied to every child row in the sidebar. On Magic Keyboard Trackpad or external mouse, rows visually respond on hover — a feature unavailable on iPhone.

### 7.5 Presentation Detents (Sheet Sizing)

Sheets on iPad use `.presentationDetents([.medium, .large])` with `.presentationDragIndicator(.visible)` and `.presentationCornerRadius(20)`, giving users the expected drag-to-resize behaviour on a large screen.

---

## 8. visionOS Spatial Application

The visionOS target (`NurseryConnectSpatial`) is a standalone companion that re-imagines the keyworker's environment as a spatial workspace. It uses an **in-memory Core Data stack** seeded with realistic demo data so it can be demonstrated without a live backend.

### 8.1 Window Architecture

| Window | Style | Size | Purpose |
|---|---|---|---|
| Hub | `.windowStyle(.plain)` | 1000×700 | Home — stats + workspace grid |
| Keyworker Dashboard | `.windowStyle(.plain)` | 980×720 | Message + incident inbox |
| Attendance | `.windowStyle(.plain)` | 1040×760 | Check-in/out + ratio monitor |
| Transport Tracker | `.windowStyle(.plain)` | 1060×720 | Live route + boarding manifest |
| Meal Plan | `.windowStyle(.plain)` | 1100×720 | Daily meal scheduling |
| Messaging | `.windowStyle(.plain)` | 980×700 | Secure parent messaging |
| Mood Chart | `.windowStyle(.volumetric)` | 0.48m×0.58m×0.42m | 3D bar chart (RealityKit) |

### 8.2 Hub View

The entry point greets the keyworker with a time-of-day greeting, nursery stats (enrolled, on-site, incidents, messages), and a 3×N grid of workspace tiles. Each tile opens its associated window via `openWindow(id:)`.

### 8.3 Spatial Attendance View

The most fully featured spatial screen. It adapts to the spatial environment:
- **Child grid:** `LazyVGrid` with 200–260 pt adaptive columns; each card shows initials avatar, name, room, and attendance badge
- **Check-in / check-out sheets:** `.sheet(item:)` pattern to avoid race conditions between `selectedRecord` and boolean flags
- **Ratios panel:** Real-time 1:3 / 1:4 / 1:8 EYFS ratio compliance display coloured green (compliant) or red (breach)
- **Material backgrounds:** `.ultraThinMaterial` for the glass effect on visionOS device (falls back to card surface on simulator)

### 8.4 3D Mood Chart (RealityKit)

The most technically complex feature. In a volumetric window:

```
#if arch(simulator)
    MoodChartBarStripView(...)  // 2D perspective transform
#else
    RealityViewContainer(...)  // Full 3D RealityKit bars
#endif
```

On device, 7 `ModelEntity` bars are placed along the X axis. A flat `ModelEntity` plane at Y=−0.04 acts as the welfare threshold marker. The user can drag to rotate the chart. Bar heights are normalised to a `maxBarHeight` of 0.11 m.

### 8.5 Transport Tracker

Simulates a nursery minibus route:
- **Status bar:** Bus icon, boarding progress ("X of Y children boarded"), ETA
- **Map panel:** MapKit with van position annotation (animated every 3 seconds), nursery pin, and stop pins
- **Manifest panel:** Ordered list of children with ✅ / ⬜ boarding status
- Implemented with `Timer.publish(every: 3)` driving `@State var vanCoordinate` and boarding index

---

## 9. Core Data Model

The model (`NurseryConnect.xcdatamodeld`) has 7 entities:

### Child
Key attributes: `id` (UUID), `firstName`, `lastName`, `preferredName`, `dateOfBirth`, `roomName`, `sessionWeekdays` (comma-separated weekday integers), `keyworkerName`, `photoConsent`, `medicalNotes`, `allergies`, `dietaryRequirements`, `authorisedCollectors` (JSON).  
Relationships: `attendanceRecords`, `diaryEntries`, `incidents` (all cascade delete).

### AttendanceRecord
`id`, `dayStart`, `checkInAt`, `checkOutAt`, `markedAbsent`, `droppedOffBy`, `collectedBy`.

### DiaryEntry
`id`, `timestamp`, `entryType` (activity / sleep / meal / nappy / wellbeing / milestone), type-specific attributes, `moodRating` (Int16, 1–5 for wellbeing), `milestonePhotoData` (binary, external storage), `milestonePhotoBlurredFaceCount`, `hasCorrections`, `isSubmittedToManager`, `originalSnapshotJSON`, sync fields.  
Relationship: `corrections` (cascade) → `DiaryEntryCorrection`.

### DiaryEntryCorrection
`id`, `correctedAt`, `fieldName`, `oldValue`, `newValue`, `reason`.

### Incident
`id`, `timestamp`, `category`, `severity`, `status`, `incidentDescription`, `immediateActionTaken`, `location`, `witnesses`, `bodyMapAnnotations` (binary), `isParentNotified`, `parentNotificationTimestamp`, `managerCountersigned`, `riddorRequired`, sync fields.

### Message
`id`, `threadID`, `sentAt`, `body`, `senderRole`, `senderDisplayName`, `messageType`, `isRead`.

### MessageThread
`id`, `childID`, `createdAt`, `initiatorRole`, `subject`, `isArchived`.

---

## 10. Regulatory Compliance

### 10.1 GDPR (General Data Protection Regulation)

**Data minimisation:** Only attributes required for childcare operations are stored. Optional fields (medical notes, dietary requirements) are nil when not applicable.

**Access scoping:** `KeyworkerGDPRScope` enforces that a keyworker can only access diary entries, attendance records, incidents, and messages for children assigned to them. This check gates both UI rendering and Core Data fetch predicates.

**Audit trail:** Every diary entry correction creates a `DiaryEntryCorrection` record capturing the field name, old value, new value, and reason. Original snapshots are stored as JSON in `originalSnapshotJSON` so the sequence of changes is fully reconstructable.

**Photo privacy:** The `FaceBlurEditorView` uses Apple's Vision framework to detect faces in milestone photos. The keyworker selects the child's face to preserve; all other faces are blurred using Core Image before the image data is stored. The blurred face count is stored in `milestonePhotoBlurredFaceCount` as a compliance record.

**Data deletion:** All child-related entities use cascade delete rules so removing a child record removes all associated diary entries, attendance records, and incidents.

### 10.2 EYFS (Early Years Foundation Stage)

**Welfare monitoring:** The mood trend chart renders a red dashed rule at score 2. When the 7-day average drops below 2, a "welfare review recommended" banner is surfaced in the journal summary card and the visionOS mood chart overlay. This implements the EYFS welfare review trigger in a data-driven, non-intrusive way.

**Safeguarding (Keeping Children Safe in Education):** The incident reporting module captures all fields required by statutory guidance: category, severity, location, witnesses, immediate action, parent notification timestamp, manager countersignature, and RIDDOR flag. The "Pending parent notification" banner at the top of the incident list is directly tied to `isParentNotified = false` in the database.

**Ratio compliance:** The visionOS Attendance view displays live 1:3 (under 2s), 1:4 (2-year-olds), and 1:8 (3–5 years) ratios with colour-coded compliance status — a visual safeguard against statutory ratio breaches.

**Authorised collectors:** The `authorisedCollectors` JSON field stores approved pickup persons. The check-out sheet in both iOS and visionOS warns the keyworker if the stated collector is not in the authorised list, implementing a safeguarding gate for child collection.

### 10.3 ICO (Information Commissioner's Office) Guidance

The app never stores biometric identifiers. Face detection is used solely for blurring (privacy protection), and the original unblurred photo is never persisted. All personal data is scoped by assignment relationship, consistent with the ICO's principle of purpose limitation.

---

## 11. Testing

The test suite comprises **13 test files** with focused unit tests and integration smoke tests.

### Test Coverage by Feature

| Test File | Coverage Area | Key Assertions |
|---|---|---|
| `MessagingViewModelTests` | Reply logic, rate limiting | Parent threads allow replies; broadcasts blocked; end-of-day summary blocked before 3 PM and on second send same day |
| `AttendanceViewModelTests` | Bucket calculation | Session matching, on-site vs awaiting vs absent classification |
| `DailyDiaryViewModelTests` | Entry CRUD, corrections | Entry creation sets correct type; corrections create audit record |
| `IncidentViewModelTests` | Filtering, status workflow | Filter by status; severity transitions; parent notification flag |
| `DayTimelineMergerTests` | Timeline construction | Diary entries merge correctly with planned session windows |
| `SyncQueueServiceTests` | Offline queue | Pending items queued; retry with exponential backoff; marked synced on success |
| `KeyworkerMoodReminderSchedulerTests` | Notification scheduling | Reminder fires only if mood entry missing; does not duplicate |
| `MilestonePhotoPrivacyTests` | Face blurring | Blurred image differs from original; blurredFaceCount > 0 when faces detected |
| `ChildSessionScheduleTests` | Session parsing | Weekday string "2,3,4,5,6" parses to Mon–Fri correctly |
| `AuthorisedCollectorsParsingTests` | Collector identity | JSON round-trips; unknown collector flagged as warning |
| `KeyworkerAttendanceBucketTests` | Attendance aggregation | Present/absent counts match records; bucket boundaries correct |
| `DiaryEntryAuditTests` | Audit trail | Correction fields populated; originalSnapshotJSON preserved |
| `NurseryConnectUITests` | Integration | Launch, navigation, and critical path smoke tests |

### Test Infrastructure
Tests use an **in-memory `NSPersistentContainer`** (not a file-backed store) to ensure isolation and speed. Each test method creates fresh entities and tears down the context. ViewModels are initialised with this in-memory context to test the full MVVM stack without a live database.

---

## 12. Design Write-Up & Implementation Decisions

### 12.1 Choosing SwiftUI Throughout

SwiftUI was chosen over UIKit for all new features. The primary reasons:

1. **Declarative state management** — `@FetchRequest` properties update charts automatically when Core Data changes without manual `NSFetchedResultsController` delegates
2. **Size-class adaptation** — `@Environment(\.horizontalSizeClass)` makes the iPad/iPhone split trivially expressible in a single `if/else` in `AdaptiveRootView`
3. **visionOS compatibility** — The same SwiftUI views render in both iOS and visionOS (with `#if os(visionOS)` guards for platform-specific materials)
4. **Animation** — `withAnimation(.spring(response:dampingFraction:))` and `.animation(_:value:)` give professional-grade transitions with minimal code

### 12.2 iPad Shell Design: NavigationSplitView vs Custom Layout

Early prototypes used a `ZStack` with manual geometry to simulate a split view. This was abandoned in favour of `NavigationSplitView` because:
- System handles sidebar show/hide animation and gesture recognition
- `columnVisibility` state (`$splitColumnVisibility`) integrates with the system sidebar toggle button automatically
- The column width API (`.navigationSplitViewColumnWidth(min:ideal:max:)`) prevents over-narrow or over-wide columns on different iPad sizes

The trade-off was reduced layout control, but the system behaviour (swipe-from-edge, keyboard Ctrl+Shift+S) is what users expect.

### 12.3 Analytics: Custom Calendar Grid vs Swift Charts for Attendance

The monthly attendance was initially built with Swift Charts `BarMark`. This was replaced with a hand-crafted `LazyVGrid` calendar dot-grid for three reasons:

1. **Semantic clarity** — A calendar grid maps directly to how humans think about monthly attendance; bars are appropriate for counts but not for "which specific days"
2. **Alignment precision** — Swift Charts cannot guarantee pixel-aligned weekday headers above bars; the `LazyVGrid` approach puts headers inside the same grid, ensuring perfect column alignment
3. **Full-month visibility** — The grid shows all 28–31 days including future ones (faded), giving the keyworker a complete picture of the month at a glance

### 12.4 Messaging: Sheet(item:) over Bool + Object Pairs

Early attendance check-in sheets used the pattern `@State var selectedRecord: NCAttendanceRecord?` plus `@State var showsCheckInSheet: Bool`. This caused a race condition in visionOS where the sheet presented before `selectedRecord` was set, resulting in empty sheets.

The fix was `.sheet(item:)` which binds directly to the optional record:
```swift
.sheet(item: $checkInRecord) { rec in
    CheckInSheet(record: binding(for: rec), onDone: { checkInRecord = nil })
}
```
This pattern is now used throughout both targets. It is both safer (no race) and more expressive (the optional itself is the gate).

### 12.5 Face Blur: Vision + Core Image Pipeline

The face blur pipeline was designed in layers:

1. **Pre-processing** — Scale image to ≤ 1600 pt and normalise EXIF orientation before Vision analysis (prevents orientation-mismatched bounding boxes)
2. **Detection** — `VNDetectFaceRectanglesRequest` returns normalised `[VNFaceObservation]` in Vision coordinates (origin bottom-left, Y up)
3. **Coordinate transform** — Convert Vision rects to UIKit coordinates (flip Y) and scale to image size
4. **Blurring** — `CIGaussianBlur(radius: 22)` + `CIPixellate` applied to each non-selected face using a mask; original image composited through mask
5. **Output** — JPEG at 0.85 quality; face count stored as `Int16` in Core Data

The separation into `FaceBlurProcessor` (logic) and `FaceBlurEditorView` (UI) follows single-responsibility and makes unit testing of the blur pipeline straightforward.

### 12.6 GDPR Scope as a Gate, Not a Filter

An early design filtered child data in the ViewModel after fetching all children. This was replaced with predicate-level GDPR scoping:

```swift
// KeyworkerGDPRScope.swift
static func childBelongsToKeyworker(childID: UUID, in context: NSManagedObjectContext) throws -> Bool {
    let request: NSFetchRequest<Child> = Child.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@ AND keyworkerName == %@",
                                    childID as CVarArg, AppConstants.keyworkerDisplayName)
    return try context.count(for: request) > 0
}
```

This means unauthorised child data never enters the ViewModel at all — a much stronger guarantee than post-fetch filtering, which could accidentally expose data through bugs.

### 12.7 visionOS: Simulator vs Device Code Paths

RealityKit's volumetric features are unavailable in the visionOS simulator. The `#if arch(simulator)` guard was used to provide a 2D equivalent (`MoodChartBarStripView` with a `perspective(1000)` transform) while keeping the full `RealityView` implementation for the device. This allows the app to be built, run, and demoed in the simulator without the code failing to compile.

### 12.8 iOS 26 Liquid Glass Progressive Enhancement

The app targets iOS 17.0 but enhances on iOS 26 using availability checks:

```swift
// NCLiquidGlassChrome.swift
if #available(iOS 26.0, *) {
    content.glassEffect(in: RoundedRectangle(cornerRadius: radius, style: .continuous))
         .tint(tint)
} else {
    content.background(Color.ncCardSurface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
}
```

Navigation bar scroll effects similarly use `#available(iOS 26.0, *)` guards. Older devices see a clean, professional appearance without Liquid Glass materials.

---

## 13. AI-Driven UI Design Process

Claude (Anthropic's AI assistant) was used as a collaborative design and development partner throughout the sprint-two build. The process was iterative:

### Phase 1 — Architecture Decisions
High-level questions were posed to Claude about iPad layout patterns (NavigationSplitView vs custom geometry), messaging data modelling (Core Data entities vs a remote API), and GDPR compliance patterns for a childcare context. Claude provided reasoning, trade-offs, and code sketches; the student evaluated and decided.

### Phase 2 — Feature Implementation
For each new feature, a brief was provided to Claude describing the goal, the data model, and the target view. Claude generated initial SwiftUI implementations. These were reviewed, tested in the simulator, and iterated based on visual output. Example:
- The `ChildSidebarRowView` went through three iterations (status badge alignment, compact name format, diary warning pill design) before the final version was accepted
- The monthly attendance chart was first generated as a Swift Charts bar chart, then collaboratively redesigned as a `LazyVGrid` calendar when bar-chart limitations became apparent

### Phase 3 — HIG Audit
A full Apple Human Interface Guidelines audit was conducted by prompting Claude in the role of a senior iOS engineer. This produced a prioritised list of 10 changes (button styles, Dynamic Type, empty states, sheet detents, hover effects, single accent colour, pull-to-refresh, searchable, keyboard shortcuts, presentation modifiers). All 10 were implemented.

### Phase 4 — Bug Fixing
Screenshots of visual bugs (misaligned labels, overlapping views, empty sheets) were shared with Claude as context. Claude diagnosed the root cause and provided targeted fixes. This was significantly faster than manual debugging for layout issues.

### Reflection on AI Assistance
AI assistance accelerated the implementation phase but required constant critical review. Several AI-generated code patterns were rejected or modified:
- A recursive `ButtonStyle.makeBody` that called `.buttonStyle()` internally (invalid in SwiftUI; had to make styles opacity-only pass-throughs)
- An attempt to initialise `KeyworkerChildSummary(from: child)` using an initialiser that did not exist
- The `summaryPill(label:count:color:Any)` pattern with an `Any`-typed colour parameter, which caused cascading type inference failures

The AI excels at generating boilerplate and suggesting patterns; the developer's job is to understand the output and catch its mistakes.

---

## 14. Challenges Faced

### 14.1 SwiftUI Type Inference with Generic Closures

The most time-consuming compiler error was `ChildMonthlyAttendanceChart`. After replacing the bar chart with a dot grid, the `summaryPill` function accepted `Any` for its colour parameter. This caused Swift's type checker to fail to infer the `Group` branch types, producing spurious "cannot convert to TableColumn" errors — completely misleading error messages. The fix was giving `summaryPill` a typed `Color` parameter and moving the `ContentUnavailableView` into a separate computed property.

**Lesson:** Swift's type inference errors are often not about the line the error points to. Simplifying the closure structure or adding explicit types resolves them.

### 14.2 visionOS RealityKit on Simulator

RealityKit volumetric windows cannot be tested on the visionOS simulator. Early builds failed to compile because `MeshResource.generateBox` is not available on the simulator architecture. The `#if arch(simulator)` guard resolved this but required maintaining two separate code paths (3D and 2D) for the mood chart.

### 14.3 Sheet Race Condition in visionOS

The attendance check-in sheets in `SpatialAttendanceView` initially showed empty content. The cause was a race between setting `selectedRecord` and flipping the `showsSheet` boolean — SwiftUI presented the sheet before the state settled. Replacing both state variables with `.sheet(item: $checkInRecord)` — where the optional item is the gate — eliminated the race entirely.

### 14.4 iPad Split-View Column Alignment

The minimised sidebar rail (62 pt avatars when sidebar is collapsed) required careful coordination between the sidebar column width, the `splitColumnVisibility` state, and custom `Environment` values (`usesFloatingTabBarShell`, `keyworkerSidebarHidden`). Getting the reveal/hide animation smooth took multiple iterations.

### 14.5 GDPR Predicate Construction

Writing NSPredicate format strings for cross-entity relationships (e.g., filtering diary entries by child ID through a relationship) is error-prone. A typo in a key path causes a silent runtime crash. The fix was centralising all predicates in `AnalyticsDataService` and writing targeted unit tests for each predicate.

### 14.6 Dynamic Type and Custom Fonts

The original codebase used `.system(.title2, design: .rounded)` throughout. This does not participate in Dynamic Type — text does not scale with the user's accessibility font size setting. Migrating to `.title2.weight(.semibold)` (semantic font style) resolved the accessibility failure but required visual review of every screen because semantic styles have slightly different baseline metrics.

---

## 15. Learning Reflection

### Resources Consulted

The following Apple resources directly influenced implementation decisions:

---

**1. WWDC23 — "Explore SwiftUI animation" (Session 10156)**

This session introduced the `animation(_:value:)` modifier semantics and the difference between implicit and explicit animations. It directly informed the use of `.animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.filter)` on the incident list picker — without the `value:` parameter, the animation triggers on any state change, not just the filter change, causing unrelated views to animate unexpectedly.

The session also clarified how `withAnimation` interacts with `@FetchRequest` updates — Core Data changes animate through SwiftUI's update cycle if the `FetchRequest` is initialised with `animation: .default`, which is why all `@FetchRequest` properties in the chart views include this parameter.

---

**2. WWDC24 — "Elevate your tab and sidebar experience in iPadOS" (Session 10147)**

This was the primary reference for the iPad split-view architecture. The session demonstrated `NavigationSplitView` column visibility management, sidebar collapse to a rail, and the importance of `columnVisibility` binding for programmatic control. The minimised 62 pt avatar rail in `KeyworkerIPadShellView` was directly inspired by the "compact sidebar" pattern shown in this session.

The session also discussed the `toolbar(.hidden, for: .navigationBar)` modifier and how to use custom toolbar placements for iPad — applied in `ChildrenSidebarView` for the profile button and sidebar toggle placement.

---

**3. WWDC23 — "What's new in Swift Charts" (Session 10037)**

This session introduced `RuleMark` for reference lines, which is the mechanism behind the welfare threshold line in `MoodTrendChart`. Before watching this session, the threshold was implemented as a `Rectangle` overlay on a `ZStack`, which did not participate in the chart's coordinate system and drifted on different screen sizes. `RuleMark(y: .value("Threshold", 2))` places the line precisely at score 2 in data coordinates, guaranteed to align correctly regardless of chart height.

The session also covered `chartOverlay` for custom interaction handling, which informed the tap gesture implementation in `WeeklyActivityDistributionChart` — tapping a bar reads the bar's data value from the chart's proxy to drive the journal highlight filter.

---

**4. WWDC23 — "Meet Core Data and CloudKit" / Develop in Swift — Persistence (Apple Developer Tutorials)**

The offline-first sync design was informed by Apple's recommended pattern for CloudKit-backed Core Data: write locally first, sync asynchronously. The `SyncQueueService` with `syncState` flags on each entity follows this model. The tutorial's discussion of `NSPersistentCloudKitContainer` also clarified why test targets should use `NSPersistentContainer` with an in-memory store — CloudKit sync interferes with test isolation.

---

**5. Apple Lab — visionOS Design Principles (Spatial Design for visionOS, Apple Developer Documentation)**

The visionOS spatial design principles — particularly "apps should feel like they belong in the space" and "windows should have a clear hierarchy" — shaped the hub-and-spoke window architecture. Rather than trying to put the entire iOS app into one large panel, the visionOS app was designed as multiple focused windows opened from a central hub. This mirrors how apps like Freeform and Mindfulness work in visionOS, with one primary window and subordinate floating panels.

The guidance on `windowStyle(.volumetric)` and the coordinate system for `RealityView` (Y-up, centre-origin) was essential for placing the mood chart bars at the correct height and positioning the welfare threshold plane below the chart centreline.

---

### Personal Reflection

This assignment demonstrated that mobile development in 2026 is less about raw coding and more about **knowing which system capabilities to use and when**. The most impactful moments were:

- Discovering that `.sheet(item:)` eliminates an entire class of presentation race conditions — a pattern I now reach for first
- Learning that Swift's type inference errors are often about something three lines above the error marker
- Understanding that GDPR compliance is not a checkbox at the end of a project; it shapes data model design from day one (scoped predicates, cascade deletes, audit fields)
- Realising that AI-assisted development requires the developer to maintain a higher critical standard, not a lower one — the AI generates plausible-looking code fast, but plausible is not the same as correct

The visionOS extension pushed beyond comfortable SwiftUI territory into RealityKit and spatial coordinate systems. Working in three dimensions — where Y is up, distances are in metres, and depth is a real layout dimension — requires a different mental model than screen-based UI. The 3D mood chart, despite being the most technically complex feature, also became the most memorable demonstration of what spatial computing can offer: a data visualisation that you can walk around.

---

*Report generated: June 2026*  
*NurseryConnect v2.1 — iOS 17.0+ / visionOS 1.0+*
