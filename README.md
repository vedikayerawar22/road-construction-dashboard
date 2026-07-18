# Road Construction Monitoring Dashboard

A Flutter app for government authorities to monitor road construction progress
across districts and compare contractor performance. Built for the Flutter
Developer Assessment (8–10 hr take-home).

## Getting Started

```bash
flutter pub get
flutter run
```

No backend is required — the app reads from `assets/data/mock_data.json`
through `DataService`, which is written to mirror what a REST call would look
like (`Future<List<Project>>` etc.), so swapping in real `dio` calls later is
a one-file change (see `lib/services/data_service.dart`).

## Folder Structure

```
lib/
  core/
    routes/        go_router config + bottom-nav shell
    theme/          Material 3 theme, status colors
  models/           Project, Authority, Notification (fromJson)
  providers/        ProjectProvider (state+filters+sort+search), ThemeProvider
  services/         DataService (local JSON, API-shaped)
  screens/          One folder per screen (1:1 with the spec)
  widgets/          Shared building blocks (cards, progress bars, skeletons)
assets/data/        mock_data.json (8 projects, 3 authorities, 6 notifications)
```

## Screen ↔ Spec Mapping

| # | Spec Screen | File |
|---|---|---|
| 1 | Dashboard | `screens/dashboard/dashboard_screen.dart` |
| 2 | Projects (list/filter/search/sort) | `screens/projects/projects_screen.dart` |
| 3 | Project Details | `screens/project_details/project_details_screen.dart` |
| 4 | Compare Projects | `screens/compare/compare_screen.dart` |
| 5 | Authority Performance | `screens/authority/authority_screen.dart` |
| 6 | Analytics (pie/bar/line) | `screens/analytics/analytics_screen.dart` |
| 7 | Notifications | `screens/notifications/notifications_screen.dart` |

## What's implemented against the rubric

- **State management**: `provider` (`ChangeNotifier`) — `ProjectProvider` owns
  all data, filters, sort, search-debounce, and compare-selection state.
- **Navigation**: `go_router` with a `ShellRoute` for the 5-tab bottom nav
  (Dashboard/Projects/Authorities/Analytics/Notifications) and pushed routes
  for Project Details (`/projects/:id`) and Compare (`/compare`).
- **API/Data handling**: `DataService` returns `Future`s from a bundled JSON
  file, cached in memory, invalidated on pull-to-refresh — structured so a
  real `dio` REST client drops in without touching providers or UI.
- **Charts & progress**: `fl_chart` pie/bar/line charts on Analytics; animated
  `LinearProgressIndicator` everywhere else via `LabeledProgressBar`.
- **Responsiveness**: `LayoutBuilder`/`GridView.count` breakpoints on
  Dashboard; everything else uses `Expanded`/`Wrap` so it doesn't overflow on
  tablet widths.
- **Error handling**: every data-driven screen has loading (skeletons),
  error+retry, and empty states (`widgets/state_views.dart`,
  `widgets/skeleton_box.dart`).
- **Bonus covered**: dark mode toggle, pull-to-refresh, skeleton loading,
  debounced search (350ms), simple entrance/progress animations, **PDF
  export**, and **offline caching**.

### PDF export

`lib/services/pdf_service.dart` builds two report types with the `pdf`
package and hands them to the `printing` package for preview/print/share:

- **Project Details → PDF icon (app bar)**: single-project report with info
  table, stage progress bars, timeline, and materials table.
- **Projects list → PDF icon (app bar)**: summary table PDF of whatever is
  currently filtered/sorted on screen.

Both offer "Preview / Print" (opens the OS print/preview sheet) and
"Share / Save PDF" (OS share sheet — lets the user save to Files/Drive/etc).

### Offline caching

`lib/services/cache_service.dart` wraps `shared_preferences`. On every
successful "fetch," `DataService` persists the raw JSON payload plus a
timestamp. If a subsequent fetch fails, it falls back to that cached payload
and the UI shows an orange "offline — showing cached data" banner on the
Dashboard with a relative "last synced" time.

To **demo this without a real network**: tap the cloud icon in the Dashboard
app bar (next to the dark-mode toggle) — it flips `DataService.simulateOffline`
and reloads, so you can show the fallback path live without touching Wi-Fi.

**Scope note:** these two features use `shared_preferences`, `pdf`, and
`printing`, which are outside the assessment's stated allowed-package list
(`dio/http, flutter_bloc/provider/riverpod, go_router, fl_chart,
cached_network_image, intl`). Mention this explicitly in your submission —
say you extended scope deliberately for the bonus marks and why, rather than
letting a reviewer discover it themselves.

## Known Gaps / Honest Notes

- Charts use static mock series (`monthlyCompletion` per authority) since
  there's no real time-series backend — call this out too.
- No automated tests were added given the time box; if you have spare time,
  a couple of widget tests on `ProjectProvider` filtering logic would be a
  strong signal.
- On some platforms, `printing`'s share/print sheet needs no extra
  permissions, but if you target iOS and hit a sandbox issue saving files,
  check the `printing` package's platform setup notes — this wasn't tested
  on a physical iOS device.

## Design Decisions Worth Mentioning in Your Interview

- Split "data shape" (`models/`) from "how it's fetched" (`services/`) from
  "how it's exposed to widgets" (`providers/`) — classic layering that scales
  if district/authority data later comes from different endpoints.
- `DataService` is deliberately Future-based and cache-invalidating so pull-
  to-refresh and a future real API require zero provider/UI changes.
- Filters, search, and sort all live as provider state (not widget state) so
  they survive tab switches and are trivially testable in isolation.
