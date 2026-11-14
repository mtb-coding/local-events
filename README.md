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

On first launch you’ll see a short onboarding screen that explains location access. Allow Location to load nearby events. If permission has not been decided yet, Discover shows **Location needed** with **Enable Location**. If Location is off or denied, the same panel offers **Open Settings.**

> **Signing:** The project uses Automatic signing with bundle id `com.mtbcoding.Nearly`. For a physical device, pick your Team in the Nearly target’s Signing & Capabilities tab. Simulator runs do not require a paid team.

## Discover phases

| Phase | When | UI |
| --- | --- | --- |
| `loading` | First fetch / waiting for GPS | Card-geometry skeletons |
| `populated` | Events on screen | List (+ thin top progress on reload) |
| `empty(radiusMiles)` | Authorized fetch returned none | “Nothing within X mi.” + **Widen radius** |
| `locationNotDetermined` | Auth not prompted yet | “Location needed.” + **Enable Location** → `requestPermission()` |
| `locationDenied` | Denied / restricted | “Location needed.” + **Open Settings.** |
| `locationUnavailable` | Authorized, but no fix after ~10s or a location error | “Couldn't find your location.” + **Retry** |
| `failed` | Hard API fail with empty list | “Couldn't load events.” + **Retry** |

## Polish notes

- **Quiet retry** — Soft API fail with a prior list keeps `.populated` and shows a quiet “Couldn't refresh.” + **Retry** chip (not full-screen failed).
- **Location auth split** — `notDetermined` never routes to Settings; denied/restricted still does.
- **Coordinate reload** — Discover reloads on the first GPS fix, or after a move of about 300 m. Updates stop after a good fix. A locate timeout or error shows **Couldn't find your location.**
- **App icon** — RIPPLE (concentric arcs + center spark; flat coral on calm dark). Single 1024 universal slot in `AppIcon.appiconset`.

## What's new (v1.1)

- Discover phase model (table above) with Designer CTAs
- Reload keeps prior list + thin top progress
- Radius 5 / 10 / 25 / 50 mi into `EventQuery`
- Mapper nits — skip missing/0,0 coords; `stateCode` in address; decode `dates.end`
- Quiet soft-fail retry; locationNotDetermined CTA; lon+lat reload; AppIcon RIPPLE

## v1 features

- **Onboarding** — location permission explanation + CoreLocation request
- **Tabs** — Discover | Saved
- **Discover** — nearby event list, search, category filter, user radius
- **Event detail** — description, when/where, MapKit map with pin, Save / Unsave
- **Saved** — bookmarked events with empty state; swipe to unsave
- **Persistence** — SwiftData stores full event snapshots
- **Mock data** — 18 events near NYC via `EventService` + `MockEventService`

## Project structure

```
Nearly.xcodeproj/
Nearly/
  NearlyApp.swift
  ContentView.swift
  Info.plist
  Assets.xcassets/
  Models/          Event, EventCategory, EventQuery, SavedEvent (SwiftData)
  Services/        EventService, MockEventService, LocationManager, Ticketmaster…
  ViewModels/      DiscoverViewModel, SavedStore
  Views/           Onboarding, MainTab, Discover/, Detail/, Saved/
```

## Try the happy path

1. Complete onboarding and allow Location.
2. **Discover** → browse the list → open an event.
3. Tap **Save Event** → switch to **Saved**.
4. Open the saved event or swipe to unsave.

## Next steps

- Wire a real events API behind `EventService` (Ticketmaster path exists when key is set)
- Add push / calendar reminders for saved events
- Improve map clustering and “open in Maps”
- Add unit tests for distance formatting and filtering

## Requirements

- Xcode 15 or newer
- iOS 17.0+ deployment target
- Swift 5.9+
