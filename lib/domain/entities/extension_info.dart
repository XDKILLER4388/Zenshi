import 'package:flutter/foundation.dart';

enum ExtensionHealthStatus { healthy, degraded, unavailable }

enum SourceType { manga, manhua, manhwa, webtoon, aggregator }

/// Immutable domain entity representing an installed or marketplace extension.
@immutable
class ExtensionInfo {
  final String id;
  final String name;
  final String version;
  final String sourceClass;
  final List<String> allowedDomains;
  final String? mirrorUrl;
  final bool isNsfw;
  final ExtensionHealthStatus healthStatus;
  final int consecutiveFailures;
  final SourceType sourceType;
  final String language;

  const ExtensionInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.sourceClass,
    required this.allowedDomains,
    this.mirrorUrl,
    this.isNsfw = false,
    this.healthStatus = ExtensionHealthStatus.healthy,
    this.consecutiveFailures = 0,
    required this.sourceType,
    required this.language,
  });

  ExtensionInfo copyWith({
    String? id,
    String? name,
    String? version,
    String? sourceClass,
    List<String>? allowedDomains,
    String? mirrorUrl,
    bool? isNsfw,
    ExtensionHealthStatus? healthStatus,
    int? consecutiveFailures,
    SourceType? sourceType,
    String? language,
  }) {
    return ExtensionInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      sourceClass: sourceClass ?? this.sourceClass,
      allowedDomains: allowedDomains ?? this.allowedDomains,
      mirrorUrl: mirrorUrl ?? this.mirrorUrl,
      isNsfw: isNsfw ?? this.isNsfw,
      healthStatus: healthStatus ?? this.healthStatus,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      sourceType: sourceType ?? this.sourceType,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtensionInfo &&
        other.id == id &&
        other.name == name &&
        other.version == version &&
        other.sourceClass == sourceClass &&
        listEquals(other.allowedDomains, allowedDomains) &&
        other.mirrorUrl == mirrorUrl &&
        other.isNsfw == isNsfw &&
        other.healthStatus == healthStatus &&
        other.consecutiveFailures == consecutiveFailures &&
        other.sourceType == sourceType &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        version,
        sourceClass,
        Object.hashAll(allowedDomains),
        mirrorUrl,
        isNsfw,
        healthStatus,
        consecutiveFailures,
        sourceType,
        language,
      );

  @override
  String toString() =>
      'ExtensionInfo(id: $id, name: $name, version: $version, '
      'healthStatus: $healthStatus, sourceType: $sourceType)';
}
