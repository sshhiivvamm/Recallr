import 'package:isar/isar.dart';
import '../../../../data/models/Link/link_model.dart';

class LinkRepository {
  final Isar isar;

  LinkRepository(this.isar);

  /// 📌 Fetch recently saved links
  Future<List<LinkModel>> getRecentLinks({int limit = 10}) async {
    // This method returns the latest saved links
    // sorted by createdAt in descending order (newest first)

    return await isar.linkModels
        .where()
        .sortByCreatedAtDesc() // newest first
        .limit(limit) // limit results (default: 10)
        .findAll();
  }

  /// 📌 Watch recent links (real-time updates)
  Stream<List<LinkModel>> watchRecentLinks({int limit = 10}) async* {
    // This stream automatically emits updated data
    // whenever a new link is added or modified

    yield* isar.linkModels
        .where()
        .sortByCreatedAtDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }
}
