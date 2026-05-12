# Implementation Plan: Zenshi Manga Reader

## Overview

Zenshi is a cross-platform manga reader built with Flutter/Dart, Riverpod 2.x state management, Drift/SQLite local database, Supabase backend, FCM push notifications, and a sandboxed Dart Isolate extension system. Implementation proceeds layer by layer: project setup and infrastructure first, then data and domain layers, then all UI screens, then integration and polish.

All tasks are written for Flutter/Dart. Tasks marked with * are optional and can be skipped for a faster MVP. Each task references specific requirements for traceability.

## Tasks
- [ ] 1. Project setup and architecture scaffolding
  - Create Flutter project with Android as primary target
  - Configure pubspec.yaml with all required dependencies: riverpod, drift, supabase_flutter, firebase_messaging, cached_network_image, flutter_cache_manager, flutter_secure_storage, workmanager, go_router, glados (dev)
  - Set up clean architecture directory structure: lib/presentation, lib/domain, lib/data, lib/infrastructure
  - Configure Android manifest permissions: INTERNET, RECEIVE_BOOT_COMPLETED, FOREGROUND_SERVICE, USE_BIOMETRIC, USE_FINGERPRINT
  - Set up go_router for navigation with named routes for all screens
  - Configure Riverpod ProviderScope at app root
  - _Requirements: 1.1, 1.2, 14.1_

- [ ] 2. Local database layer (Drift/SQLite)
  - [ ] 2.1 Define all Drift table classes: MangaTable, ChaptersTable, ReadingProgressTable, CollectionsTable, CollectionMangaTable, TagsTable, MangaTagsTable, DownloadTasksTable, ExtensionsTable, SyncQueueTable, SearchHistoryTable, AppSettingsTable
  - [ ] 2.2 Write Drift database class with all DAOs: MangaDao, ChapterDao, ReadingProgressDao, LibraryDao, DownloadDao, ExtensionDao, SyncQueueDao, SettingsDao
  - [ ] 2.3 Implement database migrations for schema versioning
  - [ ] 2.4 Write DTO mappers between Drift table data classes and domain entities
  - _Requirements: 6.10, 7.1, 8.2, 9.1, 9.2, 10.1, 12.4_

- [ ] 3. Domain layer: entities, repository interfaces, and use cases
  - [ ] 3.1 Define all domain entities as immutable Dart classes: Manga, Chapter, Page, ReadingProgress, AppSettings, DownloadTask, ExtensionInfo, SyncRecord, SearchQuery
  - [ ] 3.2 Define all repository abstract interfaces: MangaRepository, ReaderRepository, DownloadRepository, SyncRepository, ExtensionRepository, AuthRepository, SettingsRepository
  - [ ] 3.3 Implement use cases: GetLibraryUseCase, AddToLibraryUseCase, RemoveFromLibraryUseCase, SearchMangaUseCase, GetChapterListUseCase, GetPagesUseCase, SaveReadingProgressUseCase, GetReadingProgressUseCase
  - [ ] 3.4 Implement use cases: EnqueueDownloadUseCase, GetDownloadQueueUseCase, SyncUseCase, GetSettingsUseCase, UpdateSettingsUseCase, InstallExtensionUseCase, UninstallExtensionUseCase
  - _Requirements: 5.1, 5.2, 6.10, 8.1, 9.1, 9.3, 9.4, 10.2, 10.3, 12.1, 13.1_

- [ ] 4. Secure storage and authentication infrastructure
  - [ ] 4.1 Implement SecureStorageService using flutter_secure_storage backed by Android Keystore; store session tokens and credentials
  - [ ] 4.2 Implement AuthRepository with Supabase Auth: email/password sign-in, Google OAuth, Discord OAuth via custom provider
  - [ ] 4.3 Implement silent token refresh logic: intercept 401 responses, refresh token, retry original request; queue sync on refresh failure
  - [ ] 4.4 Implement Guest Mode session: create local-only session, persist guest flag in secure storage, offer migration prompt on sign-up
  - [ ] 4.5 Implement rate limiting guard: track failed login attempts locally, lock after 10 failures per hour, show countdown timer
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 1.5, 15.1, 15.3, 15.7_

- [ ] 5. Riverpod provider layer
  - [ ] 5.1 Implement authProvider (StateNotifier): manages AuthState (authenticated/guest/unauthenticated), exposes sign-in, sign-out, and guest mode actions
  - [ ] 5.2 Implement settingsProvider (StateNotifier): loads AppSettings from Drift on init, persists changes, exposes typed update methods
  - [ ] 5.3 Implement libraryProvider (AsyncNotifier): watches Drift library stream, exposes add/remove/sort/filter operations
  - [ ] 5.4 Implement readingProgressFamily (AsyncNotifier keyed by mangaId): watches progress stream, exposes save operation
  - [ ] 5.5 Implement chapterListFamily (AsyncNotifier keyed by mangaId+sourceId): fetches from repository with offline-first fallback
  - [ ] 5.6 Implement readerStateProvider (StateNotifier): manages ReaderState (page index, zoom, mode, theme, auto-scroll)
  - [ ] 5.7 Implement downloadQueueProvider (StreamProvider): streams DownloadTask list from Drift
  - [ ] 5.8 Implement extensionListProvider (AsyncNotifier): watches installed extensions stream, exposes install/uninstall/update actions
  - [ ] 5.9 Implement syncStatusProvider (StreamProvider): streams SyncStatus from SyncRepository
  - _Requirements: 3.1, 6.1, 8.3, 9.3, 9.4, 10.1, 12.1, 12.6, 13.1_

- [ ] 6. Extension sandbox infrastructure
  - [ ] 6.1 Implement ExtensionManifest validation: parse manifest JSON, verify Ed25519 signature against Zenshi signing key, reject tampered manifests
  - [ ] 6.2 Implement ExtensionSandbox: spawn per-extension Dart Isolate, set up SendPort/ReceivePort communication, handle IsolateSpawnException
  - [ ] 6.3 Implement ExtensionHttpProxy: intercept all HTTP calls from extension isolate, validate request host against allowedDomains whitelist, block undeclared domains
  - [ ] 6.4 Implement file system sandbox: restrict extension file access to designated cache directory, deny all paths outside sandbox
  - [ ] 6.5 Implement extension health monitor: track consecutive fetch failures per extension, mark as degraded after 5 failures, reset counter on success
  - [ ] 6.6 Implement mirror fallback: on primary domain unreachable, retry with mirrorUrl from manifest
  - [ ] 6.7 Implement Cloudflare challenge solver: spawn WebView for CF challenge, extract cookies, retry original request
  - _Requirements: 10.2, 10.6, 10.7, 10.9, 10.12, 15.4, 15.5, 15.6_

- [ ] 7. Property-based tests: core data and domain
  - [ ]* 7.1 Write property test for reading progress round-trip (Property 1)
    - **Property 1: Reading Progress Round-Trip**
    - **Validates: Requirements 6.10, 12.4**
    - Use glados to generate random mangaId, chapterId, pageIndex (0-9999)
    - Assert save(p); load(mangaId) == p for all generated inputs
  - [ ]* 7.2 Write property test for search filter correctness (Property 2)
    - **Property 2: Search Filter Correctness**
    - **Validates: Requirements 4.4, 4.5**
    - Generate random manga lists with mixed metadata and random filter combinations
    - Assert all results satisfy all active filter predicates; no NSFW results when toggle is false
  - [ ]* 7.3 Write property test for library add/remove round-trip (Property 7)
    - **Property 7: Library Add/Remove Round-Trip**
    - **Validates: Requirements 9.1**
    - Generate random Manga objects and initial library states
    - Assert add(m); remove(m); contains(m) == false; size == original
  - [ ]* 7.4 Write property test for settings serialization round-trip (Property 8)
    - **Property 8: Settings Serialization Round-Trip**
    - **Validates: Requirements 13.10**
    - Generate random AppSettings with all field combinations
    - Assert deserialize(serialize(s)) == s
  - [ ]* 7.5 Write property test for chapter read status idempotence (Property 9)
    - **Property 9: Chapter Read Status Idempotence**
    - **Validates: Requirements 5.3, 5.6**
    - Generate random chapters and call counts (1-10)
    - Assert isRead == true after any number of markAsRead calls >= 1
  - _Requirements: 4.4, 4.5, 5.3, 5.6, 6.10, 9.1, 12.4, 13.10_

- [ ] 8. Property-based tests: library and extension
  - [ ]* 8.1 Write property test for library sort correctness (Property 10)
    - **Property 10: Library Sort Correctness**
    - **Validates: Requirements 9.3**
    - Generate random library contents (1-100 items) and all sort options
    - Assert adjacent pairs satisfy sort predicate for selected option
  - [ ]* 8.2 Write property test for library filter correctness (Property 11)
    - **Property 11: Library Filter Correctness**
    - **Validates: Requirements 9.4**
    - Generate random library contents and random filter combinations
    - Assert all results match all predicates; no matching item absent
  - [ ]* 8.3 Write property test for extension degradation threshold (Property 12)
    - **Property 12: Extension Degradation Threshold**
    - **Validates: Requirements 10.7**
    - Generate random sequences of success/failure events
    - Assert degraded iff 5+ consecutive failures; success resets counter
  - [ ]* 8.4 Write property test for extension sandbox isolation (Property 5)
    - **Property 5: Extension Sandbox Isolation**
    - **Validates: Requirements 10.6, 15.4, 15.5**
    - Generate random extension manifests, URLs, and file paths
    - Assert undeclared domains blocked; out-of-sandbox paths denied
  - [ ]* 8.5 Write property test for reader zoom bounds (Property 13)
    - **Property 13: Reader Zoom Bounds**
    - **Validates: Requirements 6.4**
    - Generate random pinch delta values (positive and negative, large and small)
    - Assert resulting zoom always in [1.0, 5.0]
  - _Requirements: 6.4, 9.3, 9.4, 10.6, 10.7, 15.4, 15.5_

- [ ] 9. Property-based tests: sync, cache, and export
  - [ ]* 9.1 Write property test for sync conflict resolution determinism (Property 6)
    - **Property 6: Sync Conflict Resolution Determinism**
    - **Validates: Requirements 12.3**
    - Generate random pairs of SyncRecord with varying timestamps and presentation order
    - Assert winner always has max updatedAt regardless of input order
  - [ ]* 9.2 Write property test for download queue persistence (Property 3)
    - **Property 3: Download Queue Persistence**
    - **Validates: Requirements 8.2, 8.4**
    - Generate random sets of 1-20 tasks in various states
    - Assert all queued/downloading tasks survive simulated restart
  - [ ]* 9.3 Write property test for cache eviction size invariant (Property 4)
    - **Property 4: Cache Eviction Size Invariant**
    - **Validates: Requirements 7.3, 13.5**
    - Generate random cache states near/over limit with random open pages
    - Assert post-eviction size <= max; open pages not evicted
  - [ ]* 9.4 Write property test for library export/import round-trip (Property 14)
    - **Property 14: Library Export/Import Round-Trip**
    - **Validates: Requirements 9.8**
    - Generate random library states with collections, tags, manga
    - Assert import(export(lib)) == lib
  - [ ]* 9.5 Write property test for offline change queue completeness (Property 15)
    - **Property 15: Offline Change Queue Completeness**
    - **Validates: Requirements 12.4**
    - Generate random change sequences made while offline
    - Assert all changes present in sync_queue; all applied after reconnect
  - _Requirements: 7.3, 8.2, 8.4, 9.8, 12.3, 12.4, 13.5_

- [ ] 10. Checkpoint - Ensure all data layer and property tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Onboarding, splash screen, and authentication screens
  - [ ] 11.1 Implement SplashScreen widget: display app logo, check first-launch flag, navigate to onboarding or home within 2 seconds
  - [ ] 11.2 Implement OnboardingScreen: 4-page PageView introducing Library, Reader, Extensions, and Sync; persist completion flag; include Skip button
  - [ ] 11.3 Implement AuthScreen: email/password form with validation, Google OAuth button, Discord OAuth button, Guest Mode button; show descriptive error messages
  - [ ] 11.4 Implement AccountDeletionFlow: confirmation dialog, 30-day deletion notice, sign-out on confirm
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.6, 2.7_

- [ ] 12. Home screen and content discovery
  - [ ] 12.1 Implement HomeScreen scaffold: bottom navigation bar, app bar with search icon and settings icon
  - [ ] 12.2 Implement home content sections as horizontal scrolling lists: Trending Today, Popular Manga, Recently Updated, Continue Reading, New Releases, Recommended For You, Top Rated, Seasonal Picks
  - [ ] 12.3 Implement SkeletonLoader widgets for each section; show skeletons while loading, transition to content within 3 seconds
  - [ ] 12.4 Implement pull-to-refresh on HomeScreen: refresh all sections, show loading indicator
  - [ ] 12.5 Implement infinite scrolling within each section
  - [ ] 12.6 Implement genre browsing section and random discovery button; random button navigates to a randomly selected manga details page
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

- [ ] 13. Search screen
  - [ ] 13.1 Implement SearchScreen: search field with 300ms debounce for autocomplete, source selector toggle (global vs single source)
  - [ ] 13.2 Implement search filter panel: Genre, Publication Status, Author, Artist, Language, Publication Year, Popularity, Rating, NSFW toggle with age confirmation dialog
  - [ ] 13.3 Implement search history: persist 20 most recent searches locally, display on field focus, populate field on tap
  - [ ] 13.4 Implement trending searches section sourced from backend
  - [ ] 13.5 Implement empty-state message with alternative filter suggestions when search returns zero results
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9_

- [ ] 14. Manga details and chapter list screen
  - [ ] 14.1 Implement MangaDetailsScreen: cover art, title, author, artist, genres, publication status, description, average rating, source attribution
  - [ ] 14.2 Implement chapter list with default descending sort; sort toggle (ascending/descending by chapter number or upload date)
  - [ ] 14.3 Implement read/unread visual distinction in chapter list; mark read chapters with different color/opacity
  - [ ] 14.4 Implement chapter long-press context menu: download, mark as read, mark as unread
  - [ ] 14.5 Implement Start Reading button navigating to first unread chapter
  - [ ] 14.6 Implement In Library indicator and Collections/Tags management from details page
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_

- [ ] 15. Reader engine
  - [ ] 15.1 Implement ReaderScreen: full-screen widget with reading mode support (VerticalScroll, HorizontalLTR, HorizontalRTL, Webtoon)
  - [ ] 15.2 Implement PagePreloader: sliding window keeping current page, 2 behind, 3 ahead; evict pages outside window; run on background isolate
  - [ ] 15.3 Implement pinch-to-zoom (100%-500%) and double-tap zoom toggle (100%/200% at tap location)
  - [ ] 15.4 Implement tap zones: left third = previous page, right third = next page, center = toggle reader menu
  - [ ] 15.5 Implement reader menu overlay: brightness slider (left edge swipe), reading mode selector, theme selector, orientation lock, reading timer
  - [ ] 15.6 Implement chapter-end overlay with next chapter / chapter list options; chapter-start back-swipe overlay with previous chapter option
  - [ ] 15.7 Implement auto-scroll mode with configurable speed (1-10); implement orientation lock (portrait/landscape/system)
  - [ ] 15.8 Implement automatic ReadingProgress save after every page turn
  - [ ] 15.9 Implement reader themes: Default (white), Dark (dark grey), AMOLED (pure black #000000), Sepia (warm beige)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 6.11, 6.12, 6.13, 6.14, 6.15_

- [ ] 16. Image caching and page loading
  - [ ] 16.1 Implement image cache using flutter_cache_manager: cache all fetched pages to disk after first load; serve from cache on subsequent requests
  - [ ] 16.2 Implement LRU cache eviction policy: evict least-recently-accessed content when storage falls below 500 MB; never evict pages currently open in Reader
  - [ ] 16.3 Implement Data Saver Mode: fetch images at reduced quality (<=720px width), disable preloading beyond current page
  - [ ] 16.4 Implement image retry logic: auto-retry after 1s on first failure; show broken-image placeholder and manual retry button after 2nd failure
  - [ ] 16.5 Implement CDN image support with appropriate HTTP cache headers
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

- [ ] 17. Download manager
  - [ ] 17.1 Implement DownloadManager service running in background Dart Isolate with WorkManager integration for Android backgrounding
  - [ ] 17.2 Implement download queue: enqueue individual chapters or bulk-selected chapters; persist queue to download_tasks SQLite table
  - [ ] 17.3 Implement real-time download progress tracking: percentage and estimated time remaining per queued item
  - [ ] 17.4 Implement automatic download resume on network restoration after interruption
  - [ ] 17.5 Implement WiFi-only mode: pause downloads on mobile data, resume on WiFi
  - [ ] 17.6 Implement image quality selection for downloads: Original, High (<=1080px), Medium (<=720px), Low (<=480px)
  - [ ] 17.7 Implement storage monitoring: pause all downloads and notify user when available storage falls below 200 MB
  - [ ] 17.8 Implement DownloadsManagerScreen: list completed/in-progress/queued downloads with pause/resume/delete controls; show total storage consumed; bulk-delete option
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9_

- [ ] 18. Library screen
  - [ ] 18.1 Implement LibraryScreen: grid/list view of manga titles with cover cards; unread chapter badge on titles with new chapters
  - [ ] 18.2 Implement library sort options: Alphabetical A-Z, Alphabetical Z-A, Last Read, Latest Update, Most Viewed, User Rating
  - [ ] 18.3 Implement library filter panel: Collection, Tag, genre, publication status, read/unread status
  - [ ] 18.4 Implement Collections management: create, rename, delete user-defined collections; assign manga to collections
  - [ ] 18.5 Implement Tags management: create, rename, delete user-defined tags with color; assign tags to manga
  - [ ] 18.6 Implement Reading History list: all titles opened in Reader, separate from Library
  - [ ] 18.7 Implement Private Library mode: biometric/PIN authentication gate; hide private titles from main view
  - [ ] 18.8 Implement Library export/import as JSON: export all manga, collections, tags; import and merge
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8_

- [ ] 19. Checkpoint - Ensure all UI screens and reader tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 20. Extension marketplace screen
  - [ ] 20.1 Implement ExtensionMarketplaceScreen: list all available extensions with name, version, source type, language, health status
  - [ ] 20.2 Implement install/uninstall/update extension actions from marketplace; no app restart required
  - [ ] 20.3 Implement extension update check on configurable schedule (default 24h); notify user of available updates
  - [ ] 20.4 Implement source prioritization UI: allow users to rank extensions; higher-priority sources queried first
  - [ ] 20.5 Implement multi-source merging: deduplicate same title found across multiple extensions; present as single entry with selectable sources
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.10, 10.11_

- [ ] 21. Notification system
  - [ ] 21.1 Implement FCM push notification handler: receive and display new chapter, download complete/failed, extension degraded, app update notifications
  - [ ] 21.2 Implement notification tap routing: new-chapter notification navigates to chapter list for relevant title
  - [ ] 21.3 Implement notification preferences screen: per-category toggles (new chapters, downloads, extension health, app updates)
  - [ ] 21.4 Implement Supabase Edge Function triggers: listen to Postgres NOTIFY events and call FCM HTTP v1 API for new chapter and extension degraded events
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_

- [ ] 22. Cloud synchronization
  - [ ] 22.1 Implement SyncRepository with Supabase REST: push ReadingProgress, Library, Collections, Tags, Settings changes within 30 seconds of change
  - [ ] 22.2 Implement sync on sign-in: restore full Library and ReadingProgress within 60 seconds on new device
  - [ ] 22.3 Implement CRDT last-write-wins conflict resolution: retain record with latest updatedAt; write losing record to sync_conflicts table
  - [ ] 22.4 Implement offline queue: all changes written to sync_queue table first; background worker flushes queue with exponential backoff on connectivity restore
  - [ ] 22.5 Implement manual sync trigger from Settings; display last successful sync timestamp in Settings
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6_

- [ ] 23. Settings screen
  - [ ] 23.1 Implement SettingsScreen: theme selection (Light, Dark, AMOLED Dark, System Default), accent color picker (Purple, Blue, Cyan, custom hex)
  - [ ] 23.2 Implement reader settings: font style selection (3+ sans-serif options), animation speed (Off/Slow/Normal/Fast)
  - [ ] 23.3 Implement cache management: view current cache size, clear image cache, set max cache size (256 MB - 10 GB)
  - [ ] 23.4 Implement download preferences: default image quality, WiFi-only mode toggle, background download toggle
  - [ ] 23.5 Implement Data Saver Mode toggle; Low RAM Mode toggle with persistent indicator when active
  - [ ] 23.6 Implement accessibility settings: text size scaling (80%-150%), high-contrast mode toggle, reduced motion mode toggle
  - [ ] 23.7 Implement analytics opt-out toggle; immediately cease analytics events on opt-out and confirm in UI
  - [ ] 23.8 Implement settings export/import as JSON file
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8, 13.9, 13.10, 14.7, 14.8, 16.5, 16.6_

- [ ] 24. Accessibility and performance polish
  - [ ] 24.1 Add Semantics widgets and content descriptions to all interactive UI elements for screen reader support
  - [ ] 24.2 Verify all tap targets are minimum 48x48 dp across all screens; fix any undersized targets
  - [ ] 24.3 Implement high-contrast mode: increase contrast ratio of text and interactive elements to at least 4.5:1 (WCAG AA)
  - [ ] 24.4 Implement reduced motion mode: replace all AnimationController usage with instant cuts when mode is active
  - [ ] 24.5 Implement lazy loading for all list views with configurable off-screen buffer; verify 60 fps scrolling on mid-range device
  - [ ] 24.6 Implement background memory release: release non-essential image memory within 10 seconds when app is backgrounded
  - [ ] 24.7 Implement Low RAM Mode: disable animations, reduce preload buffer to 1 page, limit cache to 256 MB
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8, 17.1, 17.2, 17.3, 17.4, 17.5_

- [ ] 25. Security hardening
  - [ ] 25.1 Verify AES-256 encryption for all locally stored credentials and session tokens via Android Keystore
  - [ ] 25.2 Verify all network requests use HTTPS with TLS 1.2+; add network security config to Android manifest
  - [ ] 25.3 Implement biometric/PIN authentication for Private Library access using local_auth package
  - [ ] 25.4 Verify extension manifest signature validation rejects tampered manifests before installation
  - _Requirements: 15.1, 15.2, 15.7, 15.8_

- [ ] 26. Analytics and backend integration
  - [ ] 26.1 Implement PostHog analytics: send anonymized page views, session duration, genre interactions; respect opt-out flag
  - [ ] 26.2 Implement extension repository API: fetch extension metadata and package files from Supabase extension_registry table
  - [ ] 26.3 Implement Recommendation Engine integration: fetch personalized recommendations from backend; fall back to trending for new users
  - _Requirements: 16.2, 16.3, 16.5, 16.6, 3.3, 3.4_

- [ ] 27. Final checkpoint and integration wiring
  - [ ] 27.1 Wire all Riverpod providers to their repository implementations; verify offline-first data flow end-to-end
  - [ ] 27.2 Wire FCM token registration to Supabase user profile on sign-in; verify push notification delivery
  - [ ] 27.3 Wire extension marketplace to extension sandbox: install, load, and execute extension in isolate
  - [ ] 27.4 Wire sync queue worker to connectivity stream: flush queue on network restore
  - [ ] 27.5 Run full widget test suite: reader tap zones, skeleton loader transitions, AMOLED theme verification, accessibility tap target checks
  - _Requirements: 1.1, 1.2, 2.4, 2.5, 6.2, 10.2, 12.4, 14.1_

- [ ] 28. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with * are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties using glados (100 iterations minimum)
- Unit tests validate specific examples and edge cases
- All property test tasks use tag format: // Feature: zenshi-reader, Property {N}: {property_text}
