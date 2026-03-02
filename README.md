# bestPriceFinderWatch

A watchOS app that tells you the cheapest time to run a dishwasher or washing machine, based on live EPEX spot electricity prices via [enever.nl](https://enever.nl).

Pick a cycle profile, and the app shows you the cheapest start time overall and within the daytime window (10:00–16:00).

## Requirements

- Xcode 16 or later (project uses `PBXFileSystemSynchronizedRootGroup`, an Xcode 16 feature)
- Apple Watch (or the watchOS Simulator) running watchOS 11 or later
- An [enever.nl](https://enever.nl) API token — free registration required

## Setup

### 1. Clone the repo

```bash
git clone <repo-url>
cd bestPriceFinderWatch/bestPriceFinderWatch
```

### 2. Add your API token

Copy the example secrets file and fill in your token:

```bash
cp ../docs/Secrets.swift.example "bestPriceFinderWatch Watch App/Secrets.swift"
```

Open `bestPriceFinderWatch Watch App/Secrets.swift` and replace `YOUR_ENEVER_TOKEN_HERE` with your enever.nl API token:

```swift
enum Secrets {
    static let eneverAPIToken = "your-actual-token-here"
}
```

`Secrets.swift` is git-ignored — never commit your real token.

### 3. Open in Xcode

```bash
open bestPriceFinderWatch.xcodeproj
```

### 4. Build and run

Select the **"bestPriceFinderWatch Watch App"** scheme and an Apple Watch simulator (e.g. Apple Watch Series 11 (46mm)), then press **Run** (⌘R).

To build from the command line:

```bash
xcodebuild build \
  -scheme "bestPriceFinderWatch Watch App" \
  -project bestPriceFinderWatch.xcodeproj \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)" \
  -configuration Debug
```

## Running Tests

```bash
xcodebuild test \
  -scheme "bestPriceFinderWatch Watch App" \
  -project bestPriceFinderWatch.xcodeproj \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)" \
  -parallel-testing-enabled NO
```

> `-parallel-testing-enabled NO` is required — the `@MainActor`-isolated test suite is flaky with the default parallel runner.

## How It Works

The app fetches 15-minute EPEX spot price slots from enever.nl for today (and tomorrow if it's after 14:00). For each possible start time it computes:

```
cost = Σ kWh[i] × pricePerKWh[slot + i]
```

where `kWh[i]` is the measured energy draw of the appliance in each 15-minute interval of the cycle. It then reports:

- **Daytime**: cheapest start between 10:00 and 15:59
- **Overall**: cheapest start across all future slots up to 09:00 the next morning

## Cycle Profiles

| Profile | Appliance | Intervals |
|---|---|---|
| Dishwasher — Eco | Dishwasher | 9 × 15 min |
| Dishwasher — Hot | Dishwasher | 10 × 15 min |
| Washing — Kreukvrij | Washing machine | 9 × 15 min |
| Washing — Heet | Washing machine | 10 × 15 min |
| Washing — Fijn | Washing machine | 5 × 15 min |
| Washing — Donker | Washing machine | 8 × 15 min |

Energy profiles are based on real measured power draw per 15-minute slot.

## Project Structure

```
bestPriceFinderWatch Watch App/
├── bestPriceFinderWatchApp.swift   # @main entry point
├── ContentView.swift               # Cycle picker (NavigationStack + List)
├── Models.swift                    # CycleProfile, PriceSlot, CycleResult
├── PriceService.swift              # API fetch + cost computation
├── ResultView.swift                # Results screen
└── Secrets.swift                   # API token (git-ignored, you create this)

docs/
└── Secrets.swift.example           # Template for Secrets.swift
```
