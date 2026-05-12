# Design Document: Zenshi Manga Reader

## Overview

Zenshi is a cross-platform manga, manhua, and manhwa reader built with an offline-first architecture. The primary target is Android, with future expansion to iOS, Windows, macOS, and Linux via Flutter's single-codebase model.

**Core design philosophy:**
- Offline-first: the app is fully functional without a network connection; the network is an enhancement, not a prerequisite.
- Extension-driven content: all manga sources are provided by independently installable, sandboxed extensions modeled after Tachiyomi/Mihon.
- Performance-first UI: 60 fps scrolling, sub-1.5 s chapter open, AMOLED-optimized rendering.
- Privacy by default: local-only Guest Mode, encrypted credential storage, sandboxed extensions.

**Technology decisions:**

| Concern | Choice | Rationale |
|---|---|---|
| UI framework | Flutter (Dart) | Single codebase for Android + future iOS/desktop; mature ecosystem; Skia/Impeller rendering bypasses native widget overhead for consistent 60 fps |
| State management | Riverpod 2.x | Compile-safe providers, excellent async/stream support, testable without BuildContext |
| Local database | Drift (SQLite wrapper) | Type-safe Dart DSL over SQLite; reactive streams; migrations; works on all Flutter targets |
| Image caching | cached_network_image + flutter_cache_manager | Disk + memory LRU cache; configurable max size; background decode |
| Backend BaaS | Supabase | PostgreSQL-backed; REST + Realtime subscriptions; Auth with OAuth; open-source; predictable pricing; horizontal scaling via connection pooling |
| Auth | Supabase Auth + Firebase Auth fallback | Supabase handles email/password + Google OAuth natively; Discord OAuth via custom provider |
| Push notifications | Firebase Cloud Messaging (FCM) | Platform-agnostic push; integrates with Supabase Edge Functions for triggers |
| Extension sandbox | Flutter Platform Channels + Dart Isolates | Extensions run in separate Dart Isolates with restricted capabilities; network calls proxied through a permission-checking layer |
| Analytics | PostHog (self-hostable) | Privacy-respecting; opt-out support; no Google dependency |

---

## Architecture

Zenshi follows a layered clean architecture with four layers: Presentation, Domain, Data, and Infrastructure.

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│  Flutter Widgets + Riverpod Providers (UI state)                │
│  Screens: Home, Search, Details, Reader, Library, Settings …    │
└────────────────────────┬────────────────────────────────────────┘
                         │ calls
┌────────────────────────▼────────────────────────────────────────┐
│                         DOMAIN LAYER                             │
│  Use Cases (pure Dart)                                           │
│  Entities: Manga, Chapter, Page, Extension, User, SyncRecord …  │
│  Repository Interfaces (abstract)                                │
└────────────────────────┬────────────────────────────────────────┘
                         │ implements
┌────────────────────────▼────────────────────────────────────────┐
│                          DATA LAYER                              │
│  Repository Implementations                                      │
│  Local Data Sources (Drift/SQLite)                               │
│  Remote Data Sources (Supabase REST/Realtime, Extension APIs)    │
│  DTOs + Mappers                                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │ uses
┌────────────────────────▼────────────────────────────────────────┐
│                      INFRASTRUCTURE LAYER                        │
│  Extension Sandbox (Dart Isolates)                               │
│  Download Manager (background isolate + WorkManager)            │
│  Image Cache Manager (flutter_cache_manager)                     │
│  Secure Storage (flutter_secure_storage → Android Keystore)     │
│  FCM Push Notifications                                          │
│  Analytics (PostHog)                                             │
└─────────────────────────────────────────────────────────────────┘
```

### Offline-First Data Flow

```
User Action
    │
    ▼
Repository (Domain Interface)
    │
    ├──► Local Source (Drift/SQLite)  ◄── always read first
    │         │
    │         └── return cached data immediately
    │
    └──► Remote Source (Supabase / Extension API)
              │
              └── update local DB on success
                        │
                        └── Riverpod stream notifies UI
```

All writes go to the local DB first and are queued for remote sync. The `SyncQueue` table tracks pending operations; a background worker flushes the queue when connectivity is available.

### Extension Execution Model

```
Main Isolate (Flutter UI)
    │
    │  spawn
    ▼
Extension Isolate (per extension)
    │
    ├── Receives: SearchRequest / ChapterListRequest / PageListRequest
    ├── Executes: Extension Dart code (loaded from .dex / .dart snapshot)
    ├── Network: all HTTP calls routed through ExtensionHttpProxy
    │              └── validates domain against extension manifest whitelist
    └── Returns: serialized response via SendPort
```

Extensions are distributed as compiled Dart kernel snapshots (`.dill` files) signed with the Zenshi extension signing key. The sandbox prevents file system access outside the extension's cache directory and blocks network requests to undeclared domains.

---

## Components and Interfaces

### 1. Extension System

```dart
/// Core interface every extension must implement
abstract class MangaSource {
  String get id;
  String get name;
  String get baseUrl;
  List<String> get allowedDomains;
  SourceLanguage get language;
  bool get supportsLatest;
  bool get isNsfw;

  Future<MangaPage> fetchPopularManga(int page);
  Future<MangaPage> fetchLatestManga(int page);
  Future<MangaPage> searchManga(String query, int page, FilterList filters);
  Future<MangaDetails> fetchMangaDetails(Manga manga);
  Future<List<Chapter>> fetchChapterList(Manga manga);
  Future<List<Page>> fetchPageList(Chapter chapter);
  Future<String> getImageUrl(Page page);
  Future<Response> interceptRequest(Request request); // for CF bypass
}

/// Extension manifest (validated against signing key before install)
class ExtensionManifest {
  final String id;
  final String name;
  final String version;
  final String sourceClass;
  final List<String> allowedDomains;
  final String? mirrorUrl;
  final bool requiresWebView;
  final String signingKeyFingerprint;
}
```

### 2. Repository Interfaces

```dart
abstract class MangaRepository {
  Stream<List<Manga>> watchLibrary();
  Future<MangaDetails> getMangaDetails(String mangaId, String sourceId);
  Future<List<Chapter>> getChapterList(String mangaId, String sourceId);
  Future<void> addToLibrary(Manga manga);
  Future<void> removeFromLibrary(String mangaId);
  Future<List<Manga>> search(SearchQuery query);
}

abstract class ReaderRepository {
  Future<List<Page>> getPages(Chapter chapter);
  Future<void> saveReadingProgress(ReadingProgress progress);
  Stream<ReadingProgress?> watchProgress(String mangaId);
}

abstract class DownloadRepository {
  Stream<List<DownloadTask>> watchDownloadQueue();
  Future<void> enqueueDownload(Chapter chapter, ImageQuality quality);
  Future<void> pauseDownload(String taskId);
  Future<void> resumeDownload(String taskId);
  Future<void> deleteDownload(String taskId);
}

abstract class SyncRepository {
  Future<void> pushChanges(List<SyncRecord> records);
  Future<List<SyncRecord>> pullChanges(DateTime since);
  Stream<SyncStatus> watchSyncStatus();
}

abstract class ExtensionRepository {
  Future<List<ExtensionInfo>> fetchMarketplaceListing();
  Future<void> installExtension(ExtensionManifest manifest);
  Future<void> uninstallExtension(String extensionId);
  Future<void> updateExtension(String extensionId);
  Stream<List<InstalledExtension>> watchInstalledExtensions();
}
```

### 3. Riverpod Provider Structure

```
Providers (Riverpod)
├── authProvider          → AuthState (authenticated / guest / unauthenticated)
├── libraryProvider       → AsyncValue<List<MangaCard>>
├── readingProgressFamily → AsyncValue<ReadingProgress> (keyed by mangaId)
├── chapterListFamily     → AsyncValue<List<Chapter>> (keyed by mangaId+sourceId)
├── readerStateProvider   → ReaderState (current page, zoom, mode)
├── downloadQueueProvider → Stream<List<DownloadTask>>
├── extensionListProvider → AsyncValue<List<InstalledExtension>>
├── syncStatusProvider    → SyncStatus
└── settingsProvider      → AppSettings
```

### 4. Reader Engine

The Reader is a full-screen widget that adapts its scroll/page behavior based on the selected `ReadingMode`:

```dart
enum ReadingMode {
  verticalScroll,       // standard manga scroll
  horizontalLTR,        // left-to-right paging
  horizontalRTL,        // right-to-left paging (default for manga)
  webtoon,              // continuous vertical, no gaps
}

class ReaderState {
  final Chapter chapter;
  final int currentPageIndex;
  final ReadingMode mode;
  final double zoomLevel;          // 1.0 – 5.0
  final bool menuVisible;
  final ReaderTheme theme;
  final bool autoScrollActive;
  final int autoScrollSpeed;       // 1–10
  final bool orientationLocked;
  final ScreenOrientation orientation;
}
```

Page preloading uses a `PagePreloader` that maintains a sliding window: it keeps the current page, 2 pages behind, and 3 pages ahead in memory, evicting pages outside the window to stay within the 250 MB RAM budget.

### 5. Download Manager

The Download Manager runs in a background Dart Isolate and persists its queue to the `download_tasks` SQLite table. On Android it uses `WorkManager` (via `workmanager` Flutter plugin) to survive app backgrounding.

```dart
enum DownloadStatus { queued, downloading, paused, completed, failed }

class DownloadTask {
  final String id;
  final Chapter chapter;
  final ImageQuality quality;
  final DownloadStatus status;
  final int totalPages;
  final int downloadedPages;
  final DateTime createdAt;
  final DateTime? completedAt;
}
```

### 6. Sync Service

The Sync Service uses a CRDT-inspired last-write-wins strategy keyed on `(userId, entityType, entityId, updatedAt)`. Conflicts are resolved by retaining the record with the latest `updatedAt` timestamp; the losing record is written to a `sync_conflicts` table for user review.

```dart
class SyncRecord {
  final String id;
  final String userId;
  final SyncEntityType entityType; // readingProgress | library | settings | collection
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final bool isTombstone; // true = deletion
}
```

### 7. Notification Service

Push notifications are delivered via FCM. Supabase Edge Functions act as the trigger layer — they listen to Postgres `NOTIFY` events (new chapter available, extension degraded) and call the FCM HTTP v1 API.

```dart
enum NotificationCategory {
  newChapter,
  downloadComplete,
  downloadFailed,
  extensionDegraded,
  appUpdate,
}
```

---

## Data Models

### Local Database Schema (Drift/SQLite)

```sql
-- Manga titles (metadata cache)
CREATE TABLE manga (
  id            TEXT PRIMARY KEY,
  source_id     TEXT NOT NULL,
  title         TEXT NOT NULL,
  cover_url     TEXT,
  author        TEXT,
  artist        TEXT,
  description   TEXT,
  status        TEXT,          -- ongoing | completed | hiatus | unknown
  genres        TEXT,          -- JSON array
  average_rating REAL,
  is_nsfw       INTEGER NOT NULL DEFAULT 0,
  in_library    INTEGER NOT NULL DEFAULT 0,
  last_updated  INTEGER,       -- Unix ms
  created_at    INTEGER NOT NULL
);

-- Chapters
CREATE TABLE chapters (
  id            TEXT PRIMARY KEY,
  manga_id      TEXT NOT NULL REFERENCES manga(id),
  source_id     TEXT NOT NULL,
  chapter_number REAL NOT NULL,
  title         TEXT,
  upload_date   INTEGER,
  page_count    INTEGER,
  is_read       INTEGER NOT NULL DEFAULT 0,
  is_downloaded INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL
);

-- Reading progress
CREATE TABLE reading_progress (
  id            TEXT PRIMARY KEY,
  manga_id      TEXT NOT NULL REFERENCES manga(id),
  chapter_id    TEXT NOT NULL REFERENCES chapters(id),
  page_index    INTEGER NOT NULL DEFAULT 0,
  updated_at    INTEGER NOT NULL,
  synced_at     INTEGER
);

-- Library collections
CREATE TABLE collections (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  is_private    INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL
);

CREATE TABLE collection_manga (
  collection_id TEXT NOT NULL REFERENCES collections(id),
  manga_id      TEXT NOT NULL REFERENCES manga(id),
  PRIMARY KEY (collection_id, manga_id)
);

-- User-defined tags
CREATE TABLE tags (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL UNIQUE,
  color         TEXT
);

CREATE TABLE manga_tags (
  manga_id      TEXT NOT NULL REFERENCES manga(id),
  tag_id        TEXT NOT NULL REFERENCES tags(id),
  PRIMARY KEY (manga_id, tag_id)
);

-- Download tasks
CREATE TABLE download_tasks (
  id            TEXT PRIMARY KEY,
  chapter_id    TEXT NOT NULL REFERENCES chapters(id),
  quality       TEXT NOT NULL,  -- original | high | medium | low
  status        TEXT NOT NULL,  -- queued | downloading | paused | completed | failed
  total_pages   INTEGER NOT NULL DEFAULT 0,
  downloaded_pages INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL,
  completed_at  INTEGER
);

-- Installed extensions
CREATE TABLE extensions (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  version       TEXT NOT NULL,
  source_class  TEXT NOT NULL,
  allowed_domains TEXT NOT NULL, -- JSON array
  mirror_url    TEXT,
  is_nsfw       INTEGER NOT NULL DEFAULT 0,
  health_status TEXT NOT NULL DEFAULT 'healthy', -- healthy | degraded | unavailable
  consecutive_failures INTEGER NOT NULL DEFAULT 0,
  installed_at  INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);

-- Sync queue (pending remote operations)
CREATE TABLE sync_queue (
  id            TEXT PRIMARY KEY,
  entity_type   TEXT NOT NULL,
  entity_id     TEXT NOT NULL,
  operation     TEXT NOT NULL,  -- upsert | delete
  payload       TEXT NOT NULL,  -- JSON
  created_at    INTEGER NOT NULL,
  retry_count   INTEGER NOT NULL DEFAULT 0
);

-- Search history
CREATE TABLE search_history (
  id            TEXT PRIMARY KEY,
  query         TEXT NOT NULL,
  source_id     TEXT,           -- NULL = global search
  searched_at   INTEGER NOT NULL
);

-- App settings (single row)
CREATE TABLE app_settings (
  id            INTEGER PRIMARY KEY DEFAULT 1,
  theme         TEXT NOT NULL DEFAULT 'amoled_dark',
  accent_color  TEXT NOT NULL DEFAULT '#7C3AED',
  reading_mode  TEXT NOT NULL DEFAULT 'horizontal_rtl',
  reader_theme  TEXT NOT NULL DEFAULT 'amoled',
  font_style    TEXT NOT NULL DEFAULT 'inter',
  animation_speed TEXT NOT NULL DEFAULT 'normal',
  data_saver    INTEGER NOT NULL DEFAULT 0,
  wifi_only_download INTEGER NOT NULL DEFAULT 0,
  low_ram_mode  INTEGER NOT NULL DEFAULT 0,
  reduced_motion INTEGER NOT NULL DEFAULT 0,
  high_contrast INTEGER NOT NULL DEFAULT 0,
  text_scale    REAL NOT NULL DEFAULT 1.0,
  max_cache_mb  INTEGER NOT NULL DEFAULT 2048,
  analytics_opt_out INTEGER NOT NULL DEFAULT 0,
  notifications_new_chapter INTEGER NOT NULL DEFAULT 1,
  notifications_downloads INTEGER NOT NULL DEFAULT 1,
  notifications_extensions INTEGER NOT NULL DEFAULT 1,
  notifications_app_updates INTEGER NOT NULL DEFAULT 1,
  updated_at    INTEGER NOT NULL
);
```

### Supabase (Remote) Schema

```sql
-- Users (managed by Supabase Auth, extended here)
CREATE TABLE user_profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name  TEXT,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Synced reading progress
CREATE TABLE sync_reading_progress (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES user_profiles(id),
  manga_id      TEXT NOT NULL,
  chapter_id    TEXT NOT NULL,
  page_index    INTEGER NOT NULL,
  updated_at    TIMESTAMPTZ NOT NULL,
  UNIQUE (user_id, manga_id)
);

-- Synced library
CREATE TABLE sync_library (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES user_profiles(id),
  manga_id      TEXT NOT NULL,
  source_id     TEXT NOT NULL,
  added_at      TIMESTAMPTZ NOT NULL,
  is_tombstone  BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at    TIMESTAMPTZ NOT NULL,
  UNIQUE (user_id, manga_id)
);

-- Synced settings (single JSON blob per user)
CREATE TABLE sync_settings (
  user_id       UUID PRIMARY KEY REFERENCES user_profiles(id),
  payload       JSONB NOT NULL,
  updated_at    TIMESTAMPTZ NOT NULL
);

-- Sync conflicts log
CREATE TABLE sync_conflicts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES user_profiles(id),
  entity_type   TEXT NOT NULL,
  entity_id     TEXT NOT NULL,
  winning_payload JSONB NOT NULL,
  losing_payload  JSONB NOT NULL,
  resolved_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Extension repository
CREATE TABLE extension_registry (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  version       TEXT NOT NULL,
  language      TEXT NOT NULL,
  source_type   TEXT NOT NULL,  -- manga | manhua | manhwa
  is_nsfw       BOOLEAN NOT NULL DEFAULT FALSE,
  download_url  TEXT NOT NULL,
  signature     TEXT NOT NULL,  -- base64 Ed25519 signature
  changelog     TEXT,
  published_at  TIMESTAMPTZ NOT NULL
);

-- Anonymized analytics events
CREATE TABLE analytics_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    UUID NOT NULL,  -- random per session, not linked to user
  event_type    TEXT NOT NULL,
  properties    JSONB,
  occurred_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Key Domain Entities (Dart)

```dart
class Manga {
  final String id;
  final String sourceId;
  final String title;
  final String? coverUrl;
  final String? author;
  final String? artist;
  final String? description;
  final MangaStatus status;
  final List<String> genres;
  final double? averageRating;
  final bool isNsfw;
  final bool inLibrary;
}

class Chapter {
  final String id;
  final String mangaId;
  final String sourceId;
  final double chapterNumber;
  final String? title;
  final DateTime? uploadDate;
  final int? pageCount;
  final bool isRead;
  final bool isDownloaded;
}

class Page {
  final int index;
  final String imageUrl;
  final String? localPath; // set when downloaded
}

class ReadingProgress {
  final String mangaId;
  final String chapterId;
  final int pageIndex;
  final DateTime updatedAt;
}

class AppSettings {
  final AppTheme theme;
  final Color accentColor;
  final ReadingMode defaultReadingMode;
  final ReaderTheme readerTheme;
  final AnimationSpeed animationSpeed;
  final bool dataSaverMode;
  final bool wifiOnlyDownload;
  final bool lowRamMode;
  final bool reducedMotion;
  final bool highContrast;
  final double textScale;
  final int maxCacheMb;
  final bool analyticsOptOut;
  final NotificationPreferences notifications;
}
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Reading Progress Round-Trip

*For any* valid `ReadingProgress` record (with arbitrary `mangaId`, `chapterId`, and `pageIndex`), saving it to the local database and then reading it back should produce an equivalent record with all fields identical.

**Validates: Requirements 6.10, 12.4**

---

### Property 2: Search Filter Correctness

*For any* search query with any combination of active filters (genre, status, language, NSFW toggle, rating range), every item in the returned results should satisfy all active filter predicates simultaneously. In particular, when the NSFW toggle is `false` or the user has not confirmed their age, no result should have `isNsfw == true`.

**Validates: Requirements 4.4, 4.5**

---

### Property 3: Download Queue Persistence

*For any* set of `DownloadTask` records enqueued before an app process termination, all tasks with status `queued` or `downloading` should still be present in the queue after the app restarts, with their status preserved or reset to `queued`.

**Validates: Requirements 8.2, 8.4**

---

### Property 4: Cache Eviction Size Invariant

*For any* cache state where total disk usage exceeds the configured maximum, after the eviction policy runs, the total disk usage should be at or below the configured maximum, and no page that is currently open in the Reader should have been evicted.

**Validates: Requirements 7.3, 13.5**

---

### Property 5: Extension Sandbox Isolation

*For any* HTTP request initiated by an extension, the request's host must be a member of that extension's declared `allowedDomains` list — requests to undeclared domains must be blocked and return an error. Additionally, *for any* file path access attempted by an extension, paths outside the extension's designated cache directory must be denied.

**Validates: Requirements 10.6, 15.4, 15.5**

---

### Property 6: Sync Conflict Resolution Determinism

*For any* pair of `SyncRecord` objects for the same `(userId, entityType, entityId)`, the conflict resolution function should always select the record with the greater `updatedAt` timestamp as the winner, regardless of the order in which the two records are presented to the resolver.

**Validates: Requirements 12.3**

---

### Property 7: Library Add/Remove Round-Trip

*For any* `Manga` and any initial Library state, adding the manga to the Library and then removing it should result in the Library not containing that manga, and the Library's count should equal its original count.

**Validates: Requirements 9.1**

---

### Property 8: Settings Serialization Round-Trip

*For any* valid `AppSettings` object with any combination of field values, serializing it to JSON and deserializing it should produce an `AppSettings` object with all fields identical to the original.

**Validates: Requirements 13.10**

---

### Property 9: Chapter Read Status Idempotence

*For any* chapter, calling `markAsRead` one or more times should always result in `isRead == true`; the operation must never toggle the status back to unread regardless of how many times it is called.

**Validates: Requirements 5.3, 5.6**

---

### Property 10: Library Sort Correctness

*For any* Library contents and any selected sort option (Alphabetical A–Z, Alphabetical Z–A, Last Read, Latest Update, Most Viewed, User Rating), the returned list should be ordered such that for every adjacent pair of items, the ordering predicate for the selected sort holds between them.

**Validates: Requirements 9.3**

---

### Property 11: Library Filter Correctness

*For any* Library contents and any combination of active filters (Collection, Tag, genre, publication status, read/unread), every item in the filtered result should satisfy all active filter predicates, and no item satisfying all predicates should be absent from the result.

**Validates: Requirements 9.4**

---

### Property 12: Extension Degradation Threshold

*For any* extension, after exactly 5 consecutive fetch failures (with no successes in between), the extension's `healthStatus` should be `degraded`. A single success at any point in the sequence should reset the consecutive failure counter to zero.

**Validates: Requirements 10.7**

---

### Property 13: Reader Zoom Bounds

*For any* pinch gesture input or programmatic zoom change, the resulting zoom level should always be clamped to the range [1.0, 5.0]; no gesture or input should produce a zoom level outside this range.

**Validates: Requirements 6.4**

---

### Property 14: Library Export/Import Round-Trip

*For any* Library state (including Collections, Tags, and manga entries), exporting to JSON and then importing that JSON should produce a Library state equivalent to the original, with all manga, collections, and tags preserved.

**Validates: Requirements 9.8**

---

### Property 15: Offline Change Queue Completeness

*For any* sequence of Library, reading progress, or settings changes made while the device is offline, all changes should be present in the `sync_queue` table, and after connectivity is restored and sync completes, the remote state should reflect all queued changes with none lost.

**Validates: Requirements 12.4**

---

## Error Handling

### Network Errors

| Scenario | Behavior |
|---|---|
| No connectivity on app launch | Serve fully from local cache; show offline banner |
| Image load failure (1st attempt) | Retry automatically after 1 s |
| Image load failure (2nd attempt) | Show broken-image placeholder + manual retry button |
| Extension fetch failure | Increment `consecutive_failures`; after 5, mark extension as degraded and notify user |
| Extension domain blocked | Return `ExtensionNetworkException`; surface in UI as "Source unavailable" |
| Sync push failure | Retain in `sync_queue`; retry with exponential backoff (1 s, 2 s, 4 s, max 5 min) |
| Token refresh failure | Maintain local session; queue sync; show subtle "Offline" indicator |

### Extension Errors

| Scenario | Behavior |
|---|---|
| Extension isolate crash | Catch `IsolateSpawnException`; mark extension as degraded; log crash report |
| Invalid manifest signature | Reject installation; show "Untrusted extension" error |
| Extension version mismatch | Prompt user to update; disable extension until updated |
| Cloudflare challenge required | Spawn WebView challenge solver; retry original request on success |

### Storage Errors

| Scenario | Behavior |
|---|---|
| Storage < 200 MB | Pause all downloads; show persistent notification |
| Cache write failure | Log error; continue without caching (graceful degradation) |
| DB migration failure | Show error dialog; offer to reset local data (with warning) |

### Authentication Errors

| Scenario | Behavior |
|---|---|
| Invalid credentials | Show generic "Email or password incorrect" (no field-specific hint) |
| Rate limit exceeded (10 failed attempts/hour) | Lock account temporarily; show countdown timer |
| OAuth provider unavailable | Show provider-specific error; offer alternative sign-in methods |
| Account deletion in progress | Show confirmation; prevent new sign-ins for that account |

---

## Testing Strategy

### Unit Tests

Unit tests cover pure domain logic and data transformation:

- `SearchFilterValidator`: verify NSFW toggle, genre filter, status filter combinations
- `SyncConflictResolver`: verify last-write-wins logic with various timestamp orderings
- `CacheEvictionPolicy`: verify LRU eviction respects size limits and open-page exclusion
- `ExtensionManifestValidator`: verify signature validation accepts valid and rejects tampered manifests
- `ReadingProgressMapper`: verify DTO ↔ domain entity mapping preserves all fields
- `ChapterSorter`: verify ascending/descending sort by chapter number and upload date
- `DownloadQueueManager`: verify enqueue, pause, resume, delete state transitions

### Property-Based Tests

Property-based tests use the [dart_test](https://pub.dev/packages/test) package with [glados](https://pub.dev/packages/glados) for generator-based input (Dart-native, no external dependencies).

Each property test runs a minimum of **100 iterations**.

Tag format: `// Feature: zenshi-reader, Property {N}: {property_text}`

| Property | Generator Inputs | What Varies | Assertion |
|---|---|---|---|
| P1: Reading Progress Round-Trip | Random `mangaId`, `chapterId`, `pageIndex` (0–9999) | All field values | `save(p); load(mangaId) == p` |
| P2: Search Filter Correctness | Random manga lists with mixed metadata, random filter combinations | NSFW flags, genres, statuses, filter combos | All results satisfy all active filter predicates |
| P3: Download Queue Persistence | Random sets of 1–20 tasks in various states | Task count, statuses | All queued/downloading tasks survive restart |
| P4: Cache Eviction Size Invariant | Random cache states near/over limit, random open pages | Cache size, open page set | Post-eviction size ≤ max; open pages not evicted |
| P5: Extension Sandbox Isolation | Random extension manifests, random URLs and file paths | Domain names, paths, file paths | Undeclared domains blocked; out-of-sandbox paths denied |
| P6: Sync Conflict Determinism | Random pairs of `SyncRecord` with varying timestamps | Timestamp ordering, presentation order | Winner always has max `updatedAt` regardless of input order |
| P7: Library Add/Remove Round-Trip | Random manga objects, random initial library states | Manga metadata, library size | `add(m); remove(m); contains(m) == false; size == original` |
| P8: Settings Serialization Round-Trip | Random `AppSettings` with all field combinations | All settings fields | `deserialize(serialize(s)) == s` |
| P9: Read Status Idempotence | Random chapters, random call counts (1–10) | Number of `markAsRead` calls | `isRead == true` after any number of calls ≥ 1 |
| P10: Library Sort Correctness | Random library contents (1–100 items), all sort options | Item metadata, sort option | Adjacent pairs satisfy sort predicate for selected option |
| P11: Library Filter Correctness | Random library contents, random filter combinations | Item metadata, filter combos | All results match all predicates; no matching item absent |
| P12: Extension Degradation Threshold | Random sequences of success/failure events | Sequence length, success/failure pattern | Degraded iff 5+ consecutive failures; success resets counter |
| P13: Reader Zoom Bounds | Random pinch delta values (positive and negative, large and small) | Delta magnitude and direction | Resulting zoom always in [1.0, 5.0] |
| P14: Library Export/Import Round-Trip | Random library states with collections, tags, manga | Library size, metadata variety | `import(export(lib)) == lib` |
| P15: Offline Queue Completeness | Random change sequences made offline | Change type, count, order | All changes in sync_queue; all applied after reconnect |

### Integration Tests

Integration tests run against a local Supabase instance (Docker) and a mock extension server:

- Auth flow: sign-up → sign-in → token refresh → sign-out
- Sync round-trip: write progress on device A → sync → read on device B
- Extension install/uninstall: install from mock registry → verify sandbox → uninstall
- Download flow: enqueue → download → verify local file → delete
- Notification delivery: trigger chapter update → verify FCM payload structure

### Widget / UI Tests

- Reader tap zone navigation (left/center/right thirds)
- Skeleton loader → content transition timing
- AMOLED theme: verify `Colors.black` background on all reader UI elements
- Accessibility: verify all tap targets ≥ 48×48 dp; verify content descriptions present
- Reduced motion: verify no `AnimationController` runs when mode is active

### Performance Tests

- Cold start benchmark: measure time to interactive Home page on emulated mid-range device
- Reader scroll: measure frame rate during fast scroll through 50-page chapter
- Memory: measure heap usage during active reading session (target: ≤ 250 MB)
