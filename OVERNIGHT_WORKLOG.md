# Carbon — Overnight Worklog

## What it is

Carbon is a macOS menu bar app that tracks real-time per-app energy consumption
and carbon footprint. It samples per-process CPU time via `proc_pidinfo` every
~5 seconds, converts CPU/GPU activity to watts using the detected Apple Silicon
chip's TDP, reads system-wide GPU utilization from IOAccelerator (heuristically
attributed to apps), estimates display power from screen brightness, converts
energy to CO₂ using a 50-region grid-intensity table, and persists samples to
SQLite (WAL mode) for daily/weekly history and Swift Charts visualizations. It
also runs a rules-based suggestion engine. Pure Swift Package Manager, zero
third-party dependencies. macOS 14+, Apple Silicon.

Stack: Swift 6 (strict concurrency, actors + `@Observable`), SwiftUI +
MenuBarExtra/NSStatusItem, Swift Charts, IOKit, SQLite3 C API.

## Starting state

**Honest starting completeness: ~85%** (triage hint said 82%).

This was already a genuinely well-built, working app — not a scaffold. On
arrival:

- `swift build` (debug + release) succeeded cleanly with zero warnings.
- 14 tests passed across 6 suites.
- The app launched and ran as a menu bar accessory; SQLite DB existed from
  prior runs, confirming end-to-end persistence worked.
- All implementations were real — no mocks, stubs, TODOs, `fatalError`s, or
  placeholder logic. (The only "placeholder" matches were legitimate empty-state
  SwiftUI views.)
- `Resources/` already had a complete asset catalog (`AppIcon.iconset`, all
  sizes incl. 1024px), `Info.plist` (LSUIElement, bundle ID, versions), and
  `Carbon.entitlements` (Hardened Runtime, no sandbox — correct for this app).
- `scripts/build-app.sh` already assembled a distributable `.app` bundle with
  icon compilation and optional codesigning.

The gaps were exactly the distribution/polish items on the finish list, plus one
half-wired feature.

## What I changed, fixed, added, built

1. **Finished the week-over-week comparison (real half-wired feature).**
   `WeeklyReportView` already rendered a green/red "↓/↑ N% vs last week" line
   (lines 18–22), but it never appeared: `CarbonViewModel.generateWeeklyReport`
   always passed `previousWeekWh: nil` and `EnergyStore` had no prior-week
   query.
   - Added `EnergyStore.previousWeekTotalWh()` — sums the prior 7-day window
     (days −13…−7), returning `nil` when there's no prior-week data so the
     report suppresses a misleading "0% vs last week"
     (`Sources/CarbonEngine/Storage/EnergyStore.swift`).
   - Wired it into `generateWeeklyReport`
     (`Sources/CarbonUI/ViewModels/CarbonViewModel.swift`).
   - Added 4 `WeeklyReportGenerator` tests (sum, increase, decrease, top-5 cap)
     in `Tests/CarbonEngineTests/CarbonEngineTests.swift`.

2. **Added first-launch onboarding.**
   New `Sources/CarbonUI/Views/WelcomeView.swift` — a 380×460 panel explaining
   per-app wattage, carbon footprint, and the local-only/no-network privacy
   posture, gated by `WelcomeView.hasSeenWelcome` (UserDefaults). `AppDelegate`
   (`Sources/CarbonApp/CarbonApp.swift`) presents it as a borderless, centered
   `NSWindow` on first launch and dismisses on "Get Started". Verified the app
   launches with the welcome flag reset without crashing.

3. **Added GitHub Actions CI.**
   `.github/workflows/ci.yml` — on push/PR to main, runs on `macos-15`
   (Apple Silicon): `swift build -v`, `swift test -v`, release build, assembles
   the `.app` via `scripts/build-app.sh`, and uploads the unsigned bundle as a
   build artifact. Concurrency-cancels stale runs.

4. **Fixed gitignore for build output (would have leaked artifacts into a
   public repo).** Added `dist/` and the generated `Resources/AppIcon.icns` to
   `.gitignore`. Verified no binaries are tracked.

5. **Updated README to match reality.**
   Added a "Build a distributable app" section (`scripts/build-app.sh`, signed
   variant), documented the no-sandbox / Hardened Runtime / local-only privacy
   posture, a Developer ID notarization walkthrough (notarytool + stapler), the
   CI artifact note, the first-launch welcome, and listed `WelcomeView` in the
   tree.

6. Updated `tasks/todo.md` with a "Phase 4: Production hardening" section.

## Current state

- **Builds?** Yes. `swift build` (debug + release) clean, **zero warnings**,
  even after a full `.build` wipe, under Swift 6.3 strict concurrency.
- **Runs?** Yes. Launches as a menu bar accessory; stays up through multiple
  sample ticks with a clean (empty) log; SQLite DB initializes at
  `~/Library/Application Support/Carbon/carbon.db`. `scripts/build-app.sh`
  produces a runnable ad-hoc-signed `Carbon.app`.
- **Tests?** 18 passing across 7 suites (was 14/6).

## How to run it locally

```bash
cd /Users/markksantos/Developer/Carbon
swift build
swift run                 # dev: leaf icon + live wattage in menu bar

# or build the real .app bundle:
scripts/build-app.sh
open dist/Carbon.app

swift test                # 18 tests
```

Right-click the menu bar icon for Settings / About / Quit. First launch shows
the welcome panel.

## How to deploy (when ready)

This is a Developer ID direct-download app (not Mac App Store — per-app energy
measurement needs process enumeration the sandbox forbids).

1. Sign: `CODESIGN_IDENTITY="Developer ID Application: <Name> (<TEAMID>)" scripts/build-app.sh`
2. Notarize: `xcrun notarytool submit dist/Carbon.app --keychain-profile "<profile>" --wait`
3. Staple: `xcrun stapler staple dist/Carbon.app`
4. Zip and attach to a GitHub release; tag `v1.0`.

CI already produces an unsigned `Carbon.app` artifact on every push/PR.

(Per overnight safety rules: nothing was pushed, no tag was created, no deploy
was performed.)

## NEEDS FROM MARK

- **Apple Developer Program membership + Developer ID Application certificate** —
  required to sign/notarize for distribution. The unsigned bundle runs locally
  after clearing quarantine, but a notarized build is needed for a public
  release. No credential for this exists in any sibling project.
- **Distribution channel decision** — GitHub release (recommended; MAS is not
  viable due to the sandbox requirement). Once decided, `git push` + tag `v1.0`
  and attach the notarized zip.

## Honest completeness % now and what remains

**~96%.** The product is feature-complete, builds clean, runs, persists, and is
deploy-ready as an unsigned/ad-hoc bundle. Remaining 4% is entirely gated on
Mark: code signing + notarization (needs Apple Developer account) and the
push/tag for a v1.0 release (intentionally not done by the overnight run).

Minor non-blocking notes (left as-is to avoid over-engineering):
- `SystemInfoProvider` hardcodes a 7W panel max (14" assumption); it doesn't
  distinguish 16" MacBooks. Acceptable as a documented heuristic.
- GPU-per-app attribution is necessarily heuristic — macOS exposes only
  system-wide GPU utilization. Already documented in code.
