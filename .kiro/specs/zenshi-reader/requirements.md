# Requirements Document

## Introduction

Zenshi is a premium, cross-platform manga, manhua, and manhwa reader application targeting Android as the primary platform with future scalability to iOS, Windows, macOS, and Linux. The application provides an ad-free, offline-first reading ecosystem with a modular source extension system, polished AMOLED-optimized UI, and cloud synchronization. Zenshi combines the extension flexibility of Tachiyomi, the clean reading experience of Kotatsu, and the elegant modern UI of Doki into a single production-ready platform.

## Glossary

- **App**: The Zenshi application running on the user's device.
- **Reader**: The in-app component responsible for rendering and navigating manga pages.
- **Source**: A content provider (website, API, or aggregator) from which manga content is fetched.
- **Extension**: A sandboxed, independently installable module that implements a Source.
- **Extension_Marketplace**: The in-app page where users browse, install, update, and remove Extensions.
- **Library**: The user's personal collection of saved manga titles.
- **Chapter**: A single numbered installment of a manga title containing one or more pages.
- **Page**: A single image within a Chapter.
- **Download_Manager**: The App component that manages queued, in-progress, and completed Chapter downloads.
- **Sync_Service**: The backend service responsible for synchronizing reading progress, Library, and settings across devices.
- **Recommendation_Engine**: The backend service that generates personalized manga suggestions based on user behavior.
- **Auth_Service**: The component handling user authentication and session management.
- **Cache**: Local storage of previously fetched images and metadata to enable fast re-access and offline reading.
- **AMOLED_Mode**: A display mode using pure black (#000000) backgrounds to minimize power consumption on OLED screens.
- **Webtoon**: A vertically scrolling comic format originating from Korean platforms.
- **Guest_Mode**: An unauthenticated app session with local-only data persistence.
- **Extension_Sandbox**: An isolated execution environment that restricts Extension access to system resources.
- **CDN**: Content Delivery Network used to serve images with low latency.
- **Reading_Progress**: A record of the last read Chapter and Page position for a given title.
- **Collection**: A user-defined named group of manga titles within the Library.
- **Tag**: A user-defined label applied to manga titles for personal organization.
- **Skeleton_Loader**: An animated placeholder UI element displayed while content is loading.
- **Data_Saver_Mode**: An App setting that reduces image quality and disables auto-preloading to minimize data usage.

---

## Requirements

### Requirement 1: Application Launch and Onboarding

**User Story:** As a new user, I want a smooth launch and onboarding experience, so that I can understand the app's features and get started quickly.

#### Acceptance Criteria

1. WHEN the App is launched for the first time, THE App SHALL display a splash screen for no longer than 2 seconds before transitioning to the onboarding flow.
2. WHEN the App is launched on subsequent sessions, THE App SHALL display the splash screen and navigate directly to the Home page within 2 seconds of cold start on mid-range Android devices (≥2GB RAM, Snapdragon 600-series equivalent).
3. THE App SHALL present an onboarding flow of no more than 4 screens that introduces core features: Library, Reader, Extensions, and Sync.
4. WHEN a user completes or skips the onboarding flow, THE App SHALL not display the onboarding flow again on subsequent launches.
5. WHEN a user selects Guest Mode during onboarding, THE Auth_Service SHALL create a local-only session without requiring account credentials.

---

### Requirement 2: User Authentication

**User Story:** As a user, I want to sign in with multiple authentication methods, so that I can access my synced Library and reading progress across devices.

#### Acceptance Criteria

1. THE Auth_Service SHALL support authentication via email and password, Google OAuth, and Discord OAuth.
2. WHEN a user submits valid credentials, THE Auth_Service SHALL authenticate the user and issue a session token within 3 seconds.
3. IF authentication credentials are invalid, THEN THE Auth_Service SHALL display a descriptive error message identifying whether the email or password is incorrect, without revealing which field is wrong for security purposes.
4. WHEN a user's session token expires, THE Auth_Service SHALL silently refresh the token without interrupting the user's current activity.
5. IF the token refresh fails due to network unavailability, THEN THE Auth_Service SHALL maintain the user's local session and queue sync operations until connectivity is restored.
6. WHEN a user requests account deletion, THE Auth_Service SHALL permanently delete all associated cloud data within 30 days and confirm deletion to the user.
7. WHERE Guest Mode is active, THE App SHALL store all Library and Reading_Progress data locally and offer migration to a full account upon sign-up.

---

### Requirement 3: Home Page and Content Discovery

**User Story:** As a reader, I want a rich home page with curated and personalized content sections, so that I can discover new titles and resume reading without friction.

#### Acceptance Criteria

1. THE App SHALL display the following sections on the Home page: Trending Today, Popular Manga, Recently Updated, Continue Reading, New Releases, Recommended For You, Top Rated, and Seasonal Picks.
2. WHEN the Home page is loaded, THE App SHALL display Skeleton_Loaders for each section until content is fetched, with a maximum wait of 3 seconds before showing cached or fallback data.
3. THE Recommendation_Engine SHALL populate the "Recommended For You" section based on the user's reading history, Library genres, and ratings.
4. WHEN a user has no reading history, THE Recommendation_Engine SHALL populate the "Recommended For You" section with globally trending titles.
5. THE App SHALL support infinite scrolling within each Home page section without full-page reloads.
6. WHEN a user pulls down on the Home page, THE App SHALL refresh all sections and display a loading indicator during the refresh.
7. THE App SHALL display a genre browsing section and a random discovery button on the Home page.
8. WHEN a user taps the random discovery button, THE App SHALL navigate to a randomly selected manga details page from available sources.

---

### Requirement 4: Search System

**User Story:** As a reader, I want a powerful search system with advanced filters, so that I can find specific titles or discover content matching my preferences.

#### Acceptance Criteria

1. THE App SHALL provide a global search that queries all installed and active Extensions simultaneously.
2. THE App SHALL provide source-specific search that queries a single user-selected Extension.
3. WHEN a user types in the search field, THE App SHALL display autocomplete suggestions after 300 milliseconds of inactivity.
4. THE App SHALL support the following search filters: Genre, Publication Status (ongoing/completed/hiatus), Author, Artist, Language, Publication Year, Popularity, Rating, and NSFW content toggle.
5. WHEN a user applies the NSFW toggle to show adult content, THE App SHALL require the user to confirm their age is 18 or above before displaying results.
6. THE App SHALL persist search history locally and display the 20 most recent searches when the search field is focused.
7. WHEN a user selects a search history entry, THE App SHALL populate the search field with that entry and execute the search.
8. THE App SHALL display trending searches sourced from aggregated anonymized query data.
9. IF a search returns zero results, THEN THE App SHALL display a descriptive empty-state message and suggest alternative filters or sources.

---

### Requirement 5: Manga Details and Chapter List

**User Story:** As a reader, I want to view comprehensive details about a manga title and its chapter list, so that I can make informed reading decisions and navigate chapters easily.

#### Acceptance Criteria

1. WHEN a user navigates to a manga details page, THE App SHALL display: cover art, title, author, artist, genres, publication status, description, average rating, and source attribution.
2. THE App SHALL display the full chapter list sorted by chapter number in descending order by default.
3. WHEN a chapter has been read, THE App SHALL visually distinguish it from unread chapters in the chapter list.
4. THE App SHALL allow users to sort the chapter list in ascending or descending order by chapter number or upload date.
5. WHEN a user taps a chapter in the chapter list, THE App SHALL open the Reader for that chapter.
6. WHEN a user long-presses a chapter, THE App SHALL display options to download, mark as read, or mark as unread.
7. THE App SHALL display a "Start Reading" button that navigates to the first unread chapter for the title.
8. WHEN a title is already in the user's Library, THE App SHALL display a "In Library" indicator and allow the user to manage Collections and Tags from the details page.

---

### Requirement 6: Reader Engine

**User Story:** As a reader, I want a high-performance, customizable reading experience, so that I can read comfortably across different content formats and personal preferences.

#### Acceptance Criteria

1. THE Reader SHALL support the following reading modes: Vertical Scrolling, Horizontal Paging (left-to-right), Horizontal Paging (right-to-left), and Webtoon Mode (continuous vertical scroll with no page gaps).
2. WHEN a user opens a chapter, THE Reader SHALL display the first page within 1.5 seconds on a stable network connection (≥10 Mbps).
3. THE Reader SHALL preload the next 3 pages ahead of the current page position asynchronously without blocking the UI thread.
4. WHEN a user performs a pinch gesture, THE Reader SHALL zoom the current page between 100% and 500% of its original size.
5. WHEN a user double-taps a page, THE Reader SHALL toggle between 100% zoom and 200% zoom at the tapped location.
6. THE Reader SHALL display a brightness slider overlay accessible via a swipe gesture from the left edge of the screen.
7. THE Reader SHALL support orientation lock in portrait, landscape, and system-default modes, configurable per reading session.
8. WHEN a user reaches the last page of a chapter, THE Reader SHALL display a chapter-end overlay with options to navigate to the next chapter or return to the chapter list.
9. WHEN a user reaches the first page of a chapter and swipes back, THE Reader SHALL display an overlay with an option to navigate to the previous chapter.
10. THE Reader SHALL save Reading_Progress (chapter number and page index) automatically after every page turn.
11. THE Reader SHALL support auto-scroll mode with a user-configurable scroll speed between 1 and 10 (arbitrary units).
12. THE Reader SHALL display a reading timer showing elapsed time for the current session, accessible from the reader menu.
13. THE Reader SHALL support tap zones: tapping the left third of the screen navigates to the previous page, tapping the right third navigates to the next page, and tapping the center toggles the reader menu.
14. WHERE AMOLED_Mode is enabled, THE Reader SHALL use a pure black (#000000) background for all reader UI elements.
15. THE Reader SHALL support the following reader themes: Default (white background), Dark (dark grey background), AMOLED (pure black background), and Sepia (warm beige background).

---

### Requirement 7: Page Loading and Image Caching

**User Story:** As a reader, I want pages to load instantly and be available offline after first read, so that I experience no interruptions during reading.

#### Acceptance Criteria

1. THE App SHALL cache all fetched Page images to local storage after first load.
2. WHEN a cached Page is requested, THE App SHALL serve it from the Cache without making a network request.
3. THE App SHALL implement a Cache eviction policy that removes the least-recently-accessed content when available storage falls below 500 MB.
4. WHEN Data_Saver_Mode is enabled, THE App SHALL fetch images at reduced quality (≤720px width) and disable preloading of pages beyond the current page.
5. THE App SHALL support CDN-served images and apply appropriate HTTP cache headers.
6. WHEN an image fails to load after 2 retry attempts, THE App SHALL display a broken-image placeholder and a manual retry button.
7. THE App SHALL perform all image fetching and decoding on background threads, maintaining a UI frame rate of 60 fps during scrolling.

---

### Requirement 8: Offline Support and Download Manager

**User Story:** As a reader, I want to download chapters for offline reading, so that I can read without an internet connection.

#### Acceptance Criteria

1. THE Download_Manager SHALL allow users to download individual chapters or bulk-select multiple chapters for download.
2. WHEN a download is initiated, THE Download_Manager SHALL add it to a persistent download queue and begin downloading in the background.
3. THE Download_Manager SHALL display real-time download progress (percentage and estimated time remaining) for each queued item.
4. WHEN a download is interrupted by network loss, THE Download_Manager SHALL automatically resume the download when connectivity is restored.
5. THE App SHALL provide a Downloads Manager screen listing all completed, in-progress, and queued downloads with options to pause, resume, or delete each item.
6. WHERE WiFi-only download mode is enabled, THE Download_Manager SHALL pause all active downloads when the device switches to a mobile data connection and resume when WiFi is restored.
7. THE App SHALL allow users to select image quality for downloads: Original, High (≤1080px), Medium (≤720px), or Low (≤480px).
8. THE App SHALL display the total storage consumed by downloads and provide a bulk-delete option for completed downloads.
9. WHEN available device storage falls below 200 MB, THE Download_Manager SHALL pause all downloads and notify the user.

---

### Requirement 9: Library System

**User Story:** As a reader, I want a flexible library system to organize my manga collection, so that I can manage and navigate my titles efficiently.

#### Acceptance Criteria

1. THE App SHALL allow users to add any manga title to the Library from the manga details page.
2. THE Library SHALL support user-defined Collections, Tags, and custom folders for organizing titles.
3. THE App SHALL provide the following Library sort options: Alphabetical (A–Z, Z–A), Last Read, Latest Update, Most Viewed, and User Rating.
4. THE App SHALL provide filter options within the Library by Collection, Tag, genre, publication status, and read/unread status.
5. THE App SHALL maintain a Reading History list of all titles the user has opened in the Reader, separate from the Library.
6. THE App SHALL support a Private Library mode where selected titles are hidden from the main Library view and require biometric or PIN authentication to access.
7. WHEN a title in the Library receives a new chapter from its source, THE App SHALL display an unread chapter badge on the title's cover card.
8. THE App SHALL support import and export of the Library in a documented JSON format for backup and migration purposes.

---

### Requirement 10: Source Extension System

**User Story:** As a power user, I want to install and manage source extensions independently of app updates, so that I can access a wide variety of content providers.

#### Acceptance Criteria

1. THE Extension_Marketplace SHALL list all available Extensions with name, version, source type, language, and health status.
2. WHEN a user installs an Extension, THE App SHALL load it into the Extension_Sandbox without requiring an app restart.
3. WHEN a user uninstalls an Extension, THE App SHALL remove it and all associated cached metadata without requiring an app restart.
4. THE App SHALL check for Extension updates on a configurable schedule (default: every 24 hours) and notify the user of available updates.
5. WHEN an Extension update is available, THE App SHALL allow the user to update it without requiring an app restart.
6. THE Extension_Sandbox SHALL restrict each Extension to a defined permission set: network access to its declared domains only, read/write access to its designated cache directory only, and no access to other Extensions' data.
7. THE App SHALL monitor Extension health by tracking consecutive fetch failures and mark an Extension as "degraded" after 5 consecutive failures.
8. WHEN an Extension is marked as degraded, THE App SHALL notify the user and suggest switching to a mirror or alternative Extension.
9. THE App SHALL support mirror fallback: if a primary Extension domain is unreachable, THE App SHALL automatically retry using a configured mirror URL.
10. THE App SHALL support multi-source merging, where the same title found across multiple Extensions is deduplicated and presented as a single entry with selectable sources.
11. THE App SHALL support source prioritization, allowing users to rank Extensions so that higher-priority sources are queried first.
12. THE App SHALL support Extensions that implement Cloudflare challenge bypass using a WebView-based challenge solver.

---

### Requirement 11: Notification System

**User Story:** As a reader, I want timely notifications about new chapters and app events, so that I never miss an update for titles I follow.

#### Acceptance Criteria

1. THE App SHALL send a push notification when a new chapter is available for a title in the user's Library.
2. THE App SHALL send a notification when a chapter download completes or fails.
3. THE App SHALL send a notification when an Extension is marked as degraded or becomes unavailable.
4. THE App SHALL send a notification when a new app update is available.
5. WHEN a user taps a new-chapter notification, THE App SHALL navigate directly to the chapter list for the relevant title.
6. THE App SHALL allow users to configure notification preferences per category (new chapters, downloads, extension health, app updates) in the Settings panel.
7. WHEN a user disables notifications for a category, THE App SHALL not send notifications of that category until re-enabled.

---

### Requirement 12: Cloud Synchronization

**User Story:** As a multi-device user, I want my Library, reading progress, and settings synchronized across all my devices, so that I can switch devices without losing my place.

#### Acceptance Criteria

1. WHEN a user is authenticated, THE Sync_Service SHALL synchronize Reading_Progress, Library contents, Collections, Tags, and Settings to the cloud within 30 seconds of a change.
2. WHEN a user signs in on a new device, THE Sync_Service SHALL restore the full Library and Reading_Progress within 60 seconds.
3. WHEN a sync conflict occurs (same title modified on two devices), THE Sync_Service SHALL resolve the conflict by retaining the most recently modified version and logging the conflict for user review.
4. THE App SHALL function fully offline and queue all changes locally, then sync when connectivity is restored.
5. THE App SHALL allow users to manually trigger a full sync from the Settings panel.
6. THE App SHALL display the timestamp of the last successful sync in the Settings panel.

---

### Requirement 13: Settings and Customization

**User Story:** As a user, I want comprehensive settings to personalize the app's appearance and behavior, so that the app fits my preferences and device capabilities.

#### Acceptance Criteria

1. THE App SHALL provide theme selection with at minimum: Light, Dark, AMOLED Dark, and System Default options.
2. THE App SHALL provide accent color selection with at minimum: Purple, Blue, Cyan, and custom hex input.
3. THE App SHALL provide font style selection for the reader with at minimum 3 sans-serif typeface options.
4. THE App SHALL provide animation speed control with options: Off, Slow, Normal, and Fast.
5. THE App SHALL provide cache management controls: view current cache size, clear image cache, and set maximum cache size (range: 256 MB to 10 GB).
6. THE App SHALL provide download preference controls: default image quality, WiFi-only mode, and background download toggle.
7. THE App SHALL provide a Data_Saver_Mode toggle that reduces image quality and disables preloading.
8. THE App SHALL provide accessibility options: text size scaling (80%–150%), high-contrast mode, and reduced motion mode.
9. WHEN reduced motion mode is enabled, THE App SHALL replace all animated transitions with instant cuts.
10. THE App SHALL allow users to export and import all settings as a JSON file.

---

### Requirement 14: Performance and Resource Optimization

**User Story:** As a user on a low-end device, I want the app to run smoothly without excessive battery or memory consumption, so that I can enjoy reading on any Android device.

#### Acceptance Criteria

1. THE App SHALL maintain a UI frame rate of 60 fps during list scrolling on devices with ≥2 GB RAM and a Snapdragon 600-series equivalent processor.
2. THE App SHALL consume no more than 250 MB of RAM during active reading on a mid-range device.
3. THE App SHALL implement lazy loading for all list views, rendering only visible items and a configurable buffer of off-screen items.
4. THE App SHALL perform all network requests, image decoding, and database writes on background threads.
5. THE App SHALL reach an interactive Home page state within 3 seconds of cold start on a mid-range device with a cached data set.
6. WHEN the App is backgrounded, THE App SHALL release non-essential image memory within 10 seconds to reduce background memory pressure.
7. THE App SHALL support a Low RAM Mode that disables animations, reduces preload buffer to 1 page, and limits Cache size to 256 MB.
8. WHERE Low RAM Mode is enabled, THE App SHALL display a persistent indicator in the Settings panel confirming the mode is active.

---

### Requirement 15: Security

**User Story:** As a user, I want my data and account to be protected, so that my personal information and reading history remain private and secure.

#### Acceptance Criteria

1. THE App SHALL encrypt all locally stored user credentials and session tokens using AES-256 encryption.
2. THE App SHALL transmit all data between the App and backend services exclusively over HTTPS with TLS 1.2 or higher.
3. THE Auth_Service SHALL implement rate limiting of no more than 10 failed login attempts per account per hour before temporarily locking the account.
4. THE Extension_Sandbox SHALL prevent Extensions from accessing the device file system outside their designated cache directory.
5. THE Extension_Sandbox SHALL prevent Extensions from making network requests to domains not declared in the Extension's manifest.
6. THE App SHALL validate all Extension manifests against a cryptographic signature before installation.
7. THE App SHALL store all sensitive data (tokens, credentials) in the platform's secure keystore (Android Keystore on Android).
8. WHEN a user enables the Private Library, THE App SHALL require biometric authentication or a user-set PIN before displaying private titles.

---

### Requirement 16: Backend Services

**User Story:** As a platform operator, I want a scalable backend that supports user management, sync, recommendations, and extension distribution, so that the platform can grow without architectural rewrites.

#### Acceptance Criteria

1. THE Sync_Service SHALL expose a REST or GraphQL API for reading progress, library, and settings synchronization.
2. THE Recommendation_Engine SHALL generate personalized recommendations based on reading history, genre affinity, and collaborative filtering, updating recommendations at least once every 24 hours per active user.
3. THE App SHALL support an Extension repository hosted on the backend from which the Extension_Marketplace fetches Extension metadata and package files.
4. THE Sync_Service SHALL support horizontal scaling to handle at least 10,000 concurrent sync sessions without degradation.
5. THE App SHALL send anonymized usage analytics (page views, session duration, genre interactions) to the backend, with user opt-out available in Settings.
6. WHEN a user opts out of analytics, THE App SHALL immediately cease sending analytics events and confirm the opt-out in the Settings panel.

---

### Requirement 17: Accessibility

**User Story:** As a user with accessibility needs, I want the app to support assistive technologies and visual adjustments, so that I can use the app comfortably.

#### Acceptance Criteria

1. THE App SHALL provide content descriptions for all interactive UI elements to support screen reader assistive technologies.
2. THE App SHALL support dynamic text size scaling between 80% and 150% of the default size across all non-reader screens.
3. THE App SHALL provide a high-contrast mode that increases the contrast ratio of text and interactive elements to at least 4.5:1 (WCAG AA standard).
4. WHEN reduced motion mode is enabled, THE App SHALL eliminate all non-essential animations and transitions throughout the App.
5. THE App SHALL ensure all tap targets are at minimum 48×48 dp in size across all screens.
