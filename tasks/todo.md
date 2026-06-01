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

## Phase 4: Production hardening
- [x] Wire week-over-week comparison (EnergyStore.previousWeekTotalWh → WeeklyReport)
- [x] First-launch onboarding (WelcomeView, UserDefaults-gated)
- [x] GitHub Actions CI (build + test + release + .app artifact)
- [x] gitignore build output (dist/, generated AppIcon.icns)
- [x] README: .app bundle build + distribution/notarization docs
- [ ] Tag v1.0 release on GitHub (deferred — requires push, not done by overnight run)

## Results
- 32 Swift files, clean build, zero warnings (Swift 6.3 strict concurrency)
- 18 tests passing in 7 suites (ChipInfo, MachTimeConverter, CarbonCalculator,
  CarbonIntensityTable, ProcessEnumerator, SuggestionEngine, WeeklyReportGenerator)
- App launches successfully as menu bar accessory; SQLite persistence verified
- scripts/build-app.sh produces a working ad-hoc-signed Carbon.app bundle
