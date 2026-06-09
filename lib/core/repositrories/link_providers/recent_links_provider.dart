import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/Link/link_model.dart';
import 'link_repository_provider.dart';

final discoverLinkProvider = FutureProvider<LinkModel?>((ref) {
  final repo = ref.watch(linkRepositoryProvider);
  return repo.getDiscoverLink();
});

final readingStreakProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(linkRepositoryProvider);
  return repo.getReadingStreak();
});

final totalLinksCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(linkRepositoryProvider);
  return repo.watchTotalLinksCount();
});

final thisWeekLinksCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(linkRepositoryProvider);
  return repo.watchThisWeekLinksCount();
});

final recentLinksStreamProvider =
StreamProvider<List<LinkModel>>((ref) async* {

  // Get repository
  final repo = ref.watch(linkRepositoryProvider);

  // Listen to stream from repository
  await for (final links in repo.watchRecentLinks()) {

    //  Load folder for each link BEFORE sending to UI
    await Future.wait(
      links.map((link) => link.folder.load()),
    );

    await Future.wait(
      links.map((link) =>  link.tags.load()),
    );

    // Emit updated links
    yield links;
  }
});