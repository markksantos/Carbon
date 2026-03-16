<div align="center">

# 🍃 Carbon

**Real-time energy consumption and carbon footprint tracking for macOS, right in your menu bar.**

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-MenuBarExtra-007AFF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![macOS](https://img.shields.io/badge/macOS-14.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge)](LICENSE)

[Features](#features) · [Getting Started](#getting-started) · [Tech Stack](#tech-stack)

</div>

---

## Features

- **Per-App Energy Tracking** — Samples CPU time deltas every 5 seconds via `proc_pidinfo` and estimates watts using chip TDP
- **Apple Silicon Aware** — Auto-detects M1/M2/M3/M4 chip family (including Pro, Max, Ultra) for accurate TDP-based calculations
- **Bundle ID Coalescing** — Groups helper processes under their parent app for clean, accurate per-app reporting
- **GPU Utilization** — Reads system-wide GPU load from IOAccelerator and heuristically attributes watts to active apps
- **Carbon Footprint** — Converts energy to CO₂ using a 50-region intensity table with automatic locale detection
- **Daily & Weekly History** — Persists energy samples to SQLite and surfaces per-app Wh and CO₂ totals
- **Swift Charts** — Weekly bar charts visualizing daily energy consumption over 7 days
- **Smart Suggestions** — Rules-based tips for background hogs, tab-heavy browsers, GPU waste, and display brightness
- **Display Power Estimation** — Reads screen brightness via IOKit and estimates display watts
- **Zero Dependencies** — Pure SPM, no external packages — IOKit, SQLite3 C API, and system frameworks only

## Getting Started

### Prerequisites

- macOS 14.0 or later
- Xcode 16+ with Swift 6.0
- Apple Silicon Mac (M1/M2/M3/M4)

### Installation

```bash
git clone https://github.com/markksantos/Carbon.git
cd Carbon
swift build
swift run
```

### Permissions

Carbon reads process info via `proc_pidinfo` which works without special entitlements in debug builds. A leaf icon and live wattage will appear in your menu bar — click it to see the full breakdown.

## Tech Stack

| Component | Technology |
|---|---|
| Language | Swift 6.0 (strict concurrency) |
| UI Framework | SwiftUI + MenuBarExtra |
| Charts | Swift Charts |
| Concurrency | Actors + @Observable |
| CPU Sampling | `proc_pidinfo` / `proc_listallpids` (Darwin) |
| GPU Sampling | IOKit IOAccelerator |
| Display Brightness | `IODisplayGetFloatParameter` |
| Chip Detection | `sysctlbyname` |
| Storage | SQLite3 C API (WAL mode) |
| Package Manager | Swift Package Manager |

## Project Structure

```
Carbon/
├── Package.swift
├── Sources/
│   ├── CarbonApp/
│   │   └── CarbonApp.swift
│   ├── CarbonEngine/
│   │   ├── Carbon/
│   │   │   ├── CarbonCalculator.swift
│   │   │   └── CarbonIntensityTable.swift
│   │   ├── Models/
│   │   │   ├── AppCarbonSummary.swift
│   │   │   ├── AppEnergySnapshot.swift
│   │   │   ├── ChipInfo.swift
│   │   │   └── SystemEnergySnapshot.swift
│   │   ├── Storage/
│   │   │   ├── EnergyStore.swift
│   │   │   └── SQLiteDatabase.swift
│   │   ├── Suggestions/
│   │   │   ├── SuggestionEngine.swift
│   │   │   └── WeeklyReportGenerator.swift
│   │   ├── SystemInfo/
│   │   │   └── SystemInfoProvider.swift
│   │   └── Tracking/
│   │       ├── GPUProcessAttributor.swift
│   │       ├── GPUTracker.swift
│   │       ├── MachTimeConverter.swift
│   │       ├── ProcessEnergyTracker.swift
│   │       ├── ProcessEnumerator.swift
│   │       └── RunningAppResolver.swift
│   └── CarbonUI/
│       ├── ViewModels/
│       │   └── CarbonViewModel.swift
│       └── Views/
│           ├── AppIconView.swift
│           ├── AppListView.swift
│           ├── AppRowView.swift
│           ├── DailySummaryView.swift
│           ├── EnergyBadge.swift
│           ├── EnergyChartView.swift
│           ├── GPUInfoView.swift
│           ├── PopoverContentView.swift
│           ├── SuggestionsView.swift
│           ├── WeeklyReportView.swift
│           └── WeeklySummaryView.swift
└── Tests/
    └── CarbonEngineTests/
        └── CarbonEngineTests.swift
```

## License

MIT License © 2026 Mark Santos

---

<div align="center">

Built with ❤️ by [NoSleepLab](https://nosleeplab.com)

</div>
