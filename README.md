# DayMark 📊

A native iOS app for tracking anything you care about — for any person or pet in your household. Built with SwiftUI and SwiftData.

## Why DayMark?

Sometimes you need to track things over time but don't want to use a spreadsheet or a bloated app with features you'll never touch. DayMark lets you create exactly the trackers you need, for whoever you need them for, and visualize trends at a glance.

**Examples of things you can track:**
- Your irritability on a scale of 1–5
- Whether your dog had an accident indoors (yes/no)
- Glasses of water per day (count)
- A child's homework completion (yes/no)
- Hours of sleep (count)
- Pain level after a procedure (scale of 0–10)

## Features

### 📋 Flexible Tracking
- **Scale** — Rate something on any custom range (e.g., mood 1–5, pain 0–10)
- **Yes / No** — Binary events (e.g., did the dog poop inside? did I exercise?)
- **Count** — Log a number with optional units (e.g., 8 glasses, 45 minutes)

### 👥 Multiple Profiles
- Track different things for different people or pets
- Each profile gets their own emoji icon and color
- Dashboard shows all profiles with latest tracker values at a glance

### 📈 Charts & Stats
- Visualize data over **daily**, **weekly**, **monthly**, or **custom date ranges**
- **Scale trackers** show line charts with data points
- **Yes/No trackers** show colored bar charts (green for yes, red for no) with yes/no/total summary
- **Count trackers** show bar charts with gradient fills
- Stats panel shows **average**, **min**, **max**, and **count** for scale and count trackers

### 📦 Backup & Restore
- **Export as JSON** — Human-readable backup file, re-importable later
- **Export as HTML** — Beautiful dark-themed report viewable in any browser
- **Import from JSON** — Restore from a previous backup (non-destructive, adds alongside existing data)
- Access via the ⚙️ gear icon on the dashboard

### 🔒 Archive / Unarchive
- Pause tracking for anything you've stopped monitoring
- Archived trackers are hidden from the dashboard but data is preserved
- Unarchive at any time to resume

### ✏️ Fully Editable
- Add, edit, and delete profiles, trackers, and individual entries
- Tap any entry to edit its value, date, or note
- Swipe-to-delete on entry history

### 💾 Local Data Storage
- All data is stored on-device using SwiftData
- No accounts, no cloud, no data leaves your phone

## Screenshots

*Coming soon — app is in active development.*

## Tech Stack

- **SwiftUI** — Declarative UI framework
- **SwiftData** — Apple's native persistence framework
- **Swift Charts** — Native charting framework
- **Xcode 26+** / **iOS 17+**

## Getting Started (Fork & Run Locally)

### Prerequisites

- A Mac with **Xcode 26** or later installed (free from the Mac App Store)
- An **Apple ID** (free tier works for simulator testing)
- Optional: An **Apple Developer account** ($99/year) for TestFlight or device deployment

### Steps

1. **Fork this repository** on GitHub

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/DayMark.git
   cd DayMark
   ```

3. **Open in Xcode**
   ```bash
   open DayMark.xcodeproj
   ```

4. **Select a simulator** — In Xcode's top toolbar, choose an iPhone simulator (e.g., iPhone 17 Pro)

5. **Run** — Press ▶️ (Cmd+R) to build and launch in the simulator

No dependencies to install, no package managers, no API keys.

### Running on a Physical iPhone

1. Plug your iPhone into your Mac via USB
2. Enable **Developer Mode** on your iPhone: Settings → Privacy & Security → Developer Mode → ON (restart required)
3. In Xcode: select your iPhone as the run destination
4. Go to **Xcode → Settings → Accounts** and sign in with your Apple ID
5. Select the DayMark target → **Signing & Capabilities** → set Team to your Apple ID
6. Press ▶️ to build and install
7. On first launch, your iPhone may say "Untrusted Developer" — go to **Settings → General → VPN & Device Management** and trust your developer profile

> **Note:** With a free Apple ID, the app expires after 7 days and needs to be re-deployed from Xcode. An Apple Developer account ($99/year) removes this limitation.

### Running Tests

The project includes a standalone test suite covering tracker types, chart period filtering, statistics, JSON encoding/decoding, archiving, color parsing, and date grouping:

```bash
cd DayMark
swift run_tests.swift
```

All 75 tests should pass.

## Project Structure

```
DayMark/
├── DayMarkApp.swift               # App entry point with SwiftData container
├── Models/
│   ├── Profile.swift              # Person/pet model
│   ├── Tracker.swift              # Tracker model (scale, yes/no, count)
│   └── Entry.swift                # Individual data entry
├── Utilities/
│   ├── DataManager.swift          # JSON/HTML export, JSON import
│   └── ColorExtensions.swift      # Color helpers + jewel tone palette
├── Views/
│   ├── DashboardView.swift        # Main dashboard with profile cards
│   ├── ProfileDetailView.swift    # Profile detail with tracker list
│   ├── TrackerDetailView.swift    # Charts, stats, and entry history
│   ├── AddProfileView.swift       # Add a person or pet
│   ├── EditProfileView.swift      # Edit profile details
│   ├── AddTrackerView.swift       # Create a new tracker
│   ├── EditTrackerView.swift      # Edit tracker settings
│   ├── LogEntryView.swift         # Log a new data point
│   ├── EditEntryView.swift        # Edit an existing entry
│   ├── DataSettingsView.swift     # Export/import settings
│   └── Components/
│       └── ProfileCard.swift      # Dashboard card component
└── Assets.xcassets/               # App icon and colors
```

## License

This project is provided as-is for personal use. Feel free to fork and adapt for your own needs.
