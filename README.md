# Nearly

**Discover nearby local events and save your favorites.**

Nearly is a SwiftUI iOS starter app (iOS 17+) that shows a mock feed of local events around New York City, lets you open MapKit-backed details, and persist bookmarks with SwiftData.

Repository: [github.com/mtb-coding/local-events](https://github.com/mtb-coding/local-events)

## Open & run

1. Clone this repo:
   ```bash
   git clone https://github.com/mtb-coding/local-events.git
   cd local-events
   ```
2. Open **`Nearly.xcodeproj`** in Xcode 15+.
3. Select an iOS 17+ Simulator (e.g. iPhone 16).
4. Press **Run** (⌘R).

On first launch you’ll see a short onboarding screen that explains location access. You can allow location or tap **Maybe later** — the Discover feed still works using an NYC default center.

> **Signing:** The project uses Automatic signing with bundle id `com.mtbcoding.Nearly`. For a physical device, pick your Team in the Nearly target’s Signing & Capabilities tab. Simulator runs do not require a paid team.

## What's new (v1.1)

- **Discover states** — loading, empty feed, empty search/filter, and error with retry
- **Radius control** — 5 / 10 / 25 / 50 mi picker (no hardcoded 25 km); category passed into `EventQuery`
- **Mapper nits** — skip missing/0,0 coords; include `stateCode` in address; decode `dates.end` when present

## v1 features

- **Onboarding** — location permission explanation + CoreLocation request
- **Tabs** — Discover | Saved
- **Discover** — nearby event list (title, date/time, venue/neighborhood, distance or “Nearby”, category chip), search, category filter
- **Event detail** — description, when/where, MapKit map with pin, Save / Unsave
- **Saved** — bookmarked events with empty state; swipe to unsave
- **Persistence** — SwiftData stores full event snapshots
- **Mock data** — 18 events near NYC via `EventService` + `MockEventService`
- **Location denied** — feed still loads from NYC center; banner notes that distances need location

## Project structure

```
Nearly.xcodeproj/
Nearly/
  NearlyApp.swift
  ContentView.swift
  Info.plist
  Assets.xcassets/
  Models/          Event, EventCategory, SavedEvent (SwiftData)
  Services/        EventService, MockEventService, LocationManager
  ViewModels/      DiscoverViewModel, SavedStore
  Views/           Onboarding, MainTab, Discover/, Detail/, Saved/
```

## Try the happy path

1. Complete (or skip) onboarding.
2. **Discover** → browse the list → open an event.
3. Tap **Save Event** → switch to **Saved**.
4. Open the saved event or swipe to unsave.

## Next steps

- Wire a real events API behind `EventService`
- Add push / calendar reminders for saved events
- Improve map clustering and “open in Maps”
- Add unit tests for distance formatting and filtering
- Design a custom app icon in `Assets.xcassets/AppIcon.appiconset`

## Requirements

- Xcode 15 or newer
- iOS 17.0+ deployment target
- Swift 5.9+
