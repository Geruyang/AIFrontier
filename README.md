# AI Frontier

AI Frontier is a local-first iOS app for structured AI learning and AI news tracking. English is the default interface language, with Simplified Chinese available in Settings.

## Included in the MVP

- Learning levels describe experience rather than school stages. Each level, course topic, and app page explains its core content and purpose in both languages.
- 600 bilingual learning units: 200 Beginner, 200 Fundamentals, and 200 Advanced
- 1,800 explanation sections covering concepts, applications, and practical boundaries; 720 explicit example blocks and original local diagrams
- 1,980 questions with their complete example context, answer explanations, local progress, and best scores
- 540 new concept-first micro-lessons with independently authored English and Chinese explanations; search by concept or application
- Chapter/paper references in each lesson; see CONTENT_SOURCES.md for the full curriculum and source list
- Significant AI announcements from the past calendar month, fetched directly on device from OpenAI, Google AI, Google DeepMind, and NVIDIA
- Refresh on each launch and return to the foreground, plus pull-to-refresh
- Date validation, tracking-free URL deduplication, local importance ranking, and visible partial/offline failure status
- Current-month news cache and bookmarks; no dated built-in briefs masquerading as live news
- Automatic on-device English-to-Simplified-Chinese translation of fetched news titles and summaries, matching cached translations to exact source text; original English remains available
- Local trend summaries with an explicit evidence boundary
- StoreKit 2 monthly and annual subscriptions with a seven-day introductory trial configuration
- Background refresh requests, privacy manifest, privacy summary, terms, and local data deletion
- No app-owned server, account system, cloud database, cloud model API, or analytics SDK

## Requirements

- Xcode 26 or later
- iOS 18 or later (Apple Translation framework)
- XcodeGen 2.46 or later when regenerating the project

## Open and run

Open `AIFrontier.xcodeproj`, choose the `AIFrontier` scheme, and run on an iPhone or iPad simulator. The shared scheme uses `AIFrontier/Resources/AIFrontier.storekit` for local StoreKit simulation.

## Build and test

```sh
xcodegen generate
xcodebuild -project AIFrontier.xcodeproj -scheme AIFrontier \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' test
xcodebuild -project AIFrontier.xcodeproj -scheme AIFrontier \
  -configuration Release -sdk iphonesimulator build
xcodebuild -project AIFrontier.xcodeproj -scheme AIFrontier \
  -configuration Release -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO
xcodebuild -project AIFrontier.xcodeproj -scheme AIFrontier \
  -configuration Debug -sdk iphonesimulator analyze
```

The complete verification record is in `TEST_REPORT.md`.

Debug builds, including the desktop installer, define `DEVELOPER_ACCESS` and open all content for the owner. Release builds exclude that flag and use verified StoreKit entitlements. Developer access is a build setting, not a simulated purchase, login, or hidden public unlock switch.

The first news translation may ask to download Apple language resources. Translation runs locally afterwards. The native translation engine cannot run on an iOS simulator; simulator tests validate the adapter, cache, fallback, and interface using explicitly isolated fixtures.

Regenerate the bundled curriculum without network access:

```sh
python3 scripts/build-curriculum.py
```

The source records are `scripts/curriculum-core.json`, `scripts/curriculum-expansion.txt`, `scripts/curriculum-chinese.txt`, and `scripts/curriculum-simplifications.json`. All 540 new Chinese explanations were authored directly; development-only exploratory translation models are not used by the curriculum builder or bundled in the app.

To check the current public feeds using the same production fetcher/parser/selection code on this Mac:

```sh
scripts/verify-live-feeds.command
```

## Signed release

The project is configured for automatic signing with Apple Developer team `VA8X63NPCS`. `ExportOptions.plist` exports an App Store Connect package without changing the project build number.

```sh
xcodebuild -project AIFrontier.xcodeproj -scheme AIFrontier \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/AIFrontier.xcarchive -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath /tmp/AIFrontier.xcarchive \
  -exportPath /tmp/AIFrontierExport -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
```

The public signed package is `deliverables/AIFrontier-1.2.1-signed.ipa` (build 4). The owner package is `deliverables/AIFrontier-1.2.1-owner-signed.ipa`, signed for development testing with all content available. The desktop installer builds the same owner configuration. Older packages are retained for reference.

For physical-device testing, double-click `/Users/geruyang/Desktop/安装AIFrontier.command`. It builds the current source using development signing and installs it on your connected device. The App Store Connect IPA above is for distribution, not direct installation.

News significance is selected locally using release, research, safety, policy, and industry terms. These signals do not provide independent verification or complete industry coverage. Publisher feeds are English; the optional Chinese interface translates titles and summaries on device with Apple Translation. Missing dates, future dates, old items, and tutorial headlines are excluded. On failure, the app shows only still-current cached announcements and preserves the last successful-check timestamp.

## App Store setup

Before distribution, create the following auto-renewable subscriptions in one App Store Connect subscription group:

- `com.geruyang.aifrontier.pro.monthly`
- `com.geruyang.aifrontier.pro.annual`

Configure a one-week free introductory offer for both products. Apple determines eligibility and handles payment, renewal, restoration, and subscription management.
