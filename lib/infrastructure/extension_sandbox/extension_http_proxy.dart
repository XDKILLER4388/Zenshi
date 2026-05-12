import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/errors/failures.dart';

/// Intercepts HTTP requests from extension isolates and enforces domain whitelist.
///
/// All network calls made by an extension must pass through this proxy.
/// Requests to hosts not declared in [allowedDomains] are blocked and an
/// [ExtensionFailure] is thrown before any network I/O occurs.
class ExtensionHttpProxy {
  final List<String> allowedDomains;

  const ExtensionHttpProxy({required this.allowedDomains});

  /// Makes an HTTP GET request if the URL's host is in [allowedDomains].
  ///
  /// Throws [ExtensionFailure] if the domain is not whitelisted or the URL
  /// is malformed. Throws [ExtensionFailure] wrapping a [SocketException] on
  /// network-level errors.
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    _validateUrl(url);
    try {
      return await http.get(Uri.parse(url), headers: headers);
    } on SocketException catch (e) {
      throw ExtensionFailure(
        message: 'Network error: ${e.message}',
        cause: e,
      );
    }
  }

  /// Makes an HTTP POST request if the URL's host is in [allowedDomains].
  ///
  /// Throws [ExtensionFailure] if the domain is not whitelisted or the URL
  /// is malformed. Throws [ExtensionFailure] wrapping a [SocketException] on
  /// network-level errors.
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _validateUrl(url);
    try {
      return await http.post(Uri.parse(url), headers: headers, body: body);
    } on SocketException catch (e) {
      throw ExtensionFailure(
        message: 'Network error: ${e.message}',
        cause: e,
      );
    }
  }

  /// Checks if a given URL's host is whitelisted.
  ///
  /// Returns `false` for malformed URLs.
  bool isDomainAllowed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host;
    return allowedDomains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _validateUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw ExtensionFailure(message: 'Invalid URL: $url');
    }
    final host = uri.host;
    final isAllowed = allowedDomains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
    if (!isAllowed) {
      throw ExtensionFailure(
        message: 'Domain "$host" is not in the extension\'s allowed domains '
            'list. Allowed: ${allowedDomains.join(", ")}',
      );
    }
  }
}
