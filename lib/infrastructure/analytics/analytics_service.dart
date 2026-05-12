/// PostHog analytics service with opt-out support.
/// Sends anonymized events: page views, session duration, genre interactions.
class AnalyticsService {
  bool _optedOut = false;

  void setOptOut(bool optOut) => _optedOut = optOut;

  void trackPageView(String screenName) {
    if (_optedOut) return;
    // TODO: PostHog.capture('page_view', properties: {'screen': screenName})
  }

  void trackGenreInteraction(String genre) {
    if (_optedOut) return;
    // TODO: PostHog.capture('genre_interaction', properties: {'genre': genre})
  }

  void trackSessionStart() {
    if (_optedOut) return;
    // TODO: PostHog.capture('session_start')
  }
}
