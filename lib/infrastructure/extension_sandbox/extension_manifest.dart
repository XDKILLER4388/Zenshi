import 'dart:convert';
import '../../core/errors/failures.dart';

/// Describes an extension's metadata, permissions, and signing information.
class ExtensionManifest {
  final String id;
  final String name;
  final String version;
  final String sourceClass;
  final List<String> allowedDomains;
  final String? mirrorUrl;
  final bool requiresWebView;
  final bool isNsfw;
  final String signingKeyFingerprint;
  final String language;

  /// One of: manga | manhua | manhwa | webtoon | aggregator
  final String sourceType;

  const ExtensionManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.sourceClass,
    required this.allowedDomains,
    this.mirrorUrl,
    this.requiresWebView = false,
    this.isNsfw = false,
    required this.signingKeyFingerprint,
    required this.language,
    required this.sourceType,
  });

  factory ExtensionManifest.fromJson(Map<String, dynamic> json) {
    return ExtensionManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      sourceClass: json['sourceClass'] as String,
      allowedDomains: (json['allowedDomains'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      mirrorUrl: json['mirrorUrl'] as String?,
      requiresWebView: (json['requiresWebView'] as bool?) ?? false,
      isNsfw: (json['isNsfw'] as bool?) ?? false,
      signingKeyFingerprint: json['signingKeyFingerprint'] as String,
      language: json['language'] as String,
      sourceType: json['sourceType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'sourceClass': sourceClass,
      'allowedDomains': allowedDomains,
      if (mirrorUrl != null) 'mirrorUrl': mirrorUrl,
      'requiresWebView': requiresWebView,
      'isNsfw': isNsfw,
      'signingKeyFingerprint': signingKeyFingerprint,
      'language': language,
      'sourceType': sourceType,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionManifest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          version == other.version &&
          sourceClass == other.sourceClass &&
          mirrorUrl == other.mirrorUrl &&
          requiresWebView == other.requiresWebView &&
          isNsfw == other.isNsfw &&
          signingKeyFingerprint == other.signingKeyFingerprint &&
          language == other.language &&
          sourceType == other.sourceType;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        version,
        sourceClass,
        mirrorUrl,
        requiresWebView,
        isNsfw,
        signingKeyFingerprint,
        language,
        sourceType,
      );

  @override
  String toString() => 'ExtensionManifest(id: $id, name: $name, version: $version)';
}

/// Validates extension manifests before installation.
class ExtensionManifestValidator {
  // The Zenshi extension signing key fingerprint (SHA-256 of public key).
  // In production this would be loaded from a secure config.
  static const String _trustedFingerprint =
      'zenshi-ext-signing-key-v1-placeholder';

  /// Parses and validates an extension manifest JSON string.
  /// Throws [ExtensionFailure] if the manifest is invalid or signature doesn't match.
  static ExtensionManifest validate(String manifestJson) {
    try {
      final map = jsonDecode(manifestJson) as Map<String, dynamic>;
      final manifest = ExtensionManifest.fromJson(map);
      _validateSignature(manifest);
      _validateRequiredFields(manifest);
      return manifest;
    } on ExtensionFailure {
      rethrow;
    } catch (e) {
      throw ExtensionFailure(
        message: 'Invalid extension manifest: ${e.toString()}',
        cause: e,
      );
    }
  }

  static void _validateSignature(ExtensionManifest manifest) {
    // In production: verify Ed25519 signature against trusted public key.
    // For now: check that the fingerprint matches the trusted value.
    if (manifest.signingKeyFingerprint != _trustedFingerprint) {
      throw ExtensionFailure(
        message:
            'Untrusted extension: signature verification failed for ${manifest.id}',
        extensionId: manifest.id,
      );
    }
  }

  static void _validateRequiredFields(ExtensionManifest manifest) {
    if (manifest.id.isEmpty) {
      throw ExtensionFailure(message: 'Extension id is required');
    }
    if (manifest.name.isEmpty) {
      throw ExtensionFailure(message: 'Extension name is required');
    }
    if (manifest.allowedDomains.isEmpty) {
      throw ExtensionFailure(
        message: 'Extension must declare at least one allowed domain',
        extensionId: manifest.id,
      );
    }
  }
}
