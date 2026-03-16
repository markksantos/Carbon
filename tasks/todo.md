# Carbon — macOS Menu Bar Energy Tracker

## Phase 1: Scaffold + Per-App Energy Tracking
- [x] Package.swift + directory structure
- [x] CarbonEngine/Models (ChipInfo, AppEnergySnapshot, SystemEnergySnapshot)
- [x] CarbonEngine/Tracking (MachTimeConverter, ProcessEnumerator, RunningAppResolver, ProcessEnergyTracker)
- [x] CarbonEngine/SystemInfo (SystemInfoProvider)
- [x] CarbonUI/ViewModels (CarbonViewModel)
- [x] CarbonUI/Views (PopoverContentView, AppListView, AppRowView, EnergyBadge, AppIconView)
- [x] CarbonApp (CarbonApp.swift)
- [x] Build + verify

## Phase 2: Carbon Estimation + History
- [x] CarbonEngine/Storage (SQLiteDatabase, EnergyStore)
- [x] CarbonEngine/Carbon (CarbonIntensityTable, CarbonCalculator)
- [x] CarbonEngine/Models (AppCarbonSummary)
- [x] CarbonUI updates (tabs, DailySummaryView, WeeklySummaryView, EnergyChartView)
- [x] ViewModel updates for storage + carbon
- [x] Build + verify

## Phase 3: GPU Tracking + Suggestions
- [x] CarbonEngine/Tracking (GPUTracker, GPUProcessAttributor)
- [x] CarbonEngine/Suggestions (SuggestionEngine, WeeklyReportGenerator)
- [x] Model updates (gpuWatts integration)
- [x] CarbonUI/Views (SuggestionsView, WeeklyReportView, GPUInfoView)
- [x] ViewModel updates for GPU + suggestions
- [x] Build + verify

## Results
- 31 Swift files, ~1,640 non-blank/non-comment LOC
- 12 tests passing (ChipInfo, MachTimeConverter, CarbonCalculator, CarbonIntensityTable, ProcessEnumerator, SuggestionEngine)
- Clean build, zero warnings
- App launches successfully as menu bar accessory
