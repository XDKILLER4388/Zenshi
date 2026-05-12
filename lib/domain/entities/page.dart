import 'package:flutter/foundation.dart';

/// Immutable domain entity representing a single page within a chapter.
@immutable
class Page {
  final int index;
  final String imageUrl;

  /// Set when the page has been downloaded to local storage.
  final String? localPath;

  const Page({
    required this.index,
    required this.imageUrl,
    this.localPath,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Page &&
        other.index == index &&
        other.imageUrl == imageUrl &&
        other.localPath == localPath;
  }

  @override
  int get hashCode => Object.hash(index, imageUrl, localPath);

  @override
  String toString() =>
      'Page(index: $index, imageUrl: $imageUrl, localPath: $localPath)';
}
