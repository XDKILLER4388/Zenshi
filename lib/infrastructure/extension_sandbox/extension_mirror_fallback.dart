import 'package:http/http.dart' as http;
import '../../core/errors/failures.dart';
import 'extension_manifest.dart';
import 'extension_http_proxy.dart';

/// Handles mirror fallback when the primary extension domain is unreachable.
///
/// If the primary request fails and the extension's [ExtensionManifest]
/// declares a [ExtensionManifest.mirrorUrl], the request is retried with the
/// mirror host substituted for the primary host. If both fail, an
/// [ExtensionFailure] is thrown.
class ExtensionMirrorFallback {
  final ExtensionManifest manifest;
  final ExtensionHttpProxy proxy;

  const ExtensionMirrorFallback({
    required this.manifest,
    required this.proxy,
  });

  /// Attempts [primaryUrl] first; if it fails and a mirror is configured,
  /// retries with the mirror URL substituted for the primary domain.
  ///
  /// Throws [ExtensionFailure] if both the primary and mirror requests fail,
  /// or if no mirror is configured and the primary request fails.
  Future<http.Response> fetchWithFallback(String primaryUrl) async {
    try {
      return await proxy.get(primaryUrl);
    } catch (e) {
      final mirrorUrl = manifest.mirrorUrl;
      if (mirrorUrl == null) rethrow;

      // Substitute the mirror host for the primary host.
      final primaryUri = Uri.parse(primaryUrl);
      final mirrorUri = Uri.parse(mirrorUrl);
      final fallbackUrl = primaryUrl.replaceFirst(
        primaryUri.host,
        mirrorUri.host,
      );

      try {
        return await proxy.get(fallbackUrl);
      } catch (mirrorError) {
        throw ExtensionFailure(
          message:
              'Both primary and mirror URLs failed for extension ${manifest.id}',
          extensionId: manifest.id,
          cause: mirrorError,
        );
      }
    }
  }
}
