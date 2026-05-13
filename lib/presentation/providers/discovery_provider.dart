import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/asura_service.dart';
import '../../data/remote/flame_service.dart';
import '../../data/remote/mangadex_service.dart';
import '../../data/remote/manganato_service.dart';
import '../../data/remote/reaper_service.dart';
import '../../domain/entities/manga.dart';

/// Discovery providers for multiple sources.

final mangadexPopularProvider = FutureProvider<List<Manga>>((ref) async {
  return MangaDexService.fetchPopular(limit: 15);
});

final asuraLatestProvider = FutureProvider<List<Manga>>((ref) async {
  return AsuraService.fetchLatest();
});

final reaperLatestProvider = FutureProvider<List<Manga>>((ref) async {
  return ReaperService.fetchLatest();
});

final flameLatestProvider = FutureProvider<List<Manga>>((ref) async {
  return FlameService.fetchLatest();
});

final manganatoLatestProvider = FutureProvider<List<Manga>>((ref) async {
  return ManganatoService.fetchLatest();
});
