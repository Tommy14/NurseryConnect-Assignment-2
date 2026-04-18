# NurseryConnect

**NurseryConnect** is an iOS app for **early-years keyworkers**: a single-role prototype for logging the day, tracking attendance, and recording incidents in line with nursery workflows. It is built with **SwiftUI** and **Core Data**, with offline-first persistence and a background **sync queue** when the network is available.

---

## Features

| Area | What it does |
|------|----------------|
| **Dashboard** | Keyworker home with tabbed navigation (Children, Incidents), greeting header, and quick access to child profiles and diary actions. |
| **Children** | Searchable child list, profiles, and links into the daily diary and attendance context. |
| **Daily diary** | Timeline of meals, sleep, nappies, activities, and wellbeing; merges with planned session windows; audit-aware entries. |
| **Attendance** | Today-focused attendance cards and check-in style flows aligned with the nursery day. |
| **Incidents** | Structured incident capture (severity, category, body map annotations), workflow timeline, status, and **PDF export** for records. |
| **Sync & connectivity** | `NetworkMonitor` and `SyncQueueService` process queued work when online or on a timer; sync also runs when the app becomes active. |

The MVP assumes a **logged-in keyworker** context (sample identity and nursery name are configured in code—no sign-in UI).

---

## Requirements

- **Xcode** 15 or newer (recommended: latest stable for your OS)
- **iOS 17.0+** deployment target
- **Swift 5**

---

## Getting started

1. Clone or open this repository folder in Finder.
2. Open **`NurseryConnect.xcodeproj`** in Xcode.
3. Select the **NurseryConnect** scheme and a simulator or device (iPhone recommended).
4. Press **Run** (⌘R).

On first launch, the app can **seed sample data** (see `DataSeeder` and `AppConstants.hasSeededSampleDataKey`) so you can explore flows without manual setup.

---

## Project structure (high level)

```
NurseryConnect/
├── App/                 # App entry, launch experience, root scene
├── Core/                # Persistence, sync, helpers, extensions, constants
├── Features/            # Feature modules (Attendance, Children, DailyDiary, Dashboard, IncidentReporting)
├── Resources/           # Assets, Core Data model
├── Shared/              # Reusable UI components and theming
└── Tests/               # Unit and UI tests
```

---

## Testing

- **Unit tests**: `NurseryConnectTests` (e.g. diary merging, attendance buckets, sync queue, incident view logic).
- **UI tests**: `NurseryConnectUITests`.

Run tests from Xcode (**Product → Test**, ⌘U) or via `xcodebuild` with the appropriate scheme.

---

## Configuration notes

- **Bundle identifier**: `com.assignment.NurseryConnect`
- **Branding / demo names**: `AppConstants` (`keyworkerDisplayName`, `nurseryDisplayName`)
- **Navigation chrome**: Optimised for current iOS versions, including Liquid Glass–friendly bar styling on **iOS 26** where applicable.

---

## Author

Developed as part of a **Mobile Application Design and Development (MADD)** coursework submission.

---

## License

This project is provided for **educational and assessment purposes**. Reuse beyond your course is at your own discretion; there is no separate open-source license attached unless one is added by the author.
