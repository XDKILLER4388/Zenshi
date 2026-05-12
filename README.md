# Zenshi 禅師

A premium, cross-platform manga, manhua, and manhwa reader app built with Flutter.

> **Ad-free · Offline-first · AMOLED dark · Modular extensions**

---

## Features

- 🌑 **AMOLED dark theme** with neon purple/blue/cyan accents
- 📚 **Offline-first** — reads from local cache, syncs when online
- 🧩 **Modular extension system** — install sources independently (Tachiyomi-style)
- 📖 **4 reading modes** — Vertical, Horizontal LTR/RTL, Webtoon
- 🔍 **Advanced search** with genre, status, language, rating, and NSFW filters
- 📥 **Download manager** — bulk downloads, WiFi-only mode, quality selection
- 🔄 **Cloud sync** — reading progress, library, and settings across devices
- 🔒 **Private library** — biometric/PIN protected
- 🎨 **Fully customizable** — themes, accent colors, fonts, animation speed

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.32 / Dart 3.8 |
| State | Riverpod 2.x |
| Local DB | Drift (SQLite) |
| Backend | Supabase |
| Push | Firebase Cloud Messaging |
| Auth | Supabase Auth (email, Google, Discord) |
| Extensions | Dart Isolates (sandboxed) |

## Project Structure

```
lib/
├── core/           # Theme, routing, constants, errors
├── domain/         # Entities, repository interfaces, use cases
├── data/           # Drift tables, DAOs, repository implementations
├── infrastructure/ # Extension sandbox, download manager, cache, sync
└── presentation/   # Riverpod providers, screens, widgets
```

## Getting Started

### Prerequisites

- Flutter 3.32+ (`flutter --version`)
- Android Studio + Android SDK
- A [Supabase](https://supabase.com) project
- A [Firebase](https://firebase.google.com) project (for FCM)

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/XDKILLER4388/zenshi.git
   cd zenshi
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Add Firebase config:
   - Download `google-services.json` from Firebase Console
   - Place it in `android/app/`

4. Configure Supabase:
   - Create a project at [supabase.com](https://supabase.com)
   - Add your URL and anon key to `lib/main.dart`

5. Run:
   ```bash
   flutter run
   ```

## Screens

| Screen | Description |
|---|---|
| Splash | Animated logo, routes to onboarding or home |
| Onboarding | 4-page feature introduction |
| Auth | Email/password, Google, Discord, Guest mode |
| Discover | 8 curated sections, genre chips, random FAB |
| Search | Global/source search, advanced filters, NSFW gate |
| Manga Details | Cover, metadata, chapter list, add to library |
| Reader | 4 modes, pinch zoom, tap zones, themes, auto-scroll |
| Library | Grid view, sort/filter, collections, tags, private mode |
| Downloads | Queue manager, progress tracking, WiFi-only |
| Extensions | Marketplace, health monitoring, source prioritization |
| Notifications | New chapters, downloads, extension alerts |
| Settings | Full customization — theme, reader, cache, accessibility |

## License

MIT
