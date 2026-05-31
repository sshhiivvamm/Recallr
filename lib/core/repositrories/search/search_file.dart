import 'package:isar/isar.dart';

import '../../../data/models/Link/link_model.dart';
import '../../../data/models/search/search_model.dart';

Future<List<LinkModel>> searchLinks(
    Isar isar,
    LinkSearchParams params,
    ) async {
  final queryLower = params.query?.toLowerCase().trim();

  // STEP 1: Fetch all then filter in Dart — avoids Isar QueryBuilder generic type issues
  List<LinkModel> results = await isar.linkModels.where().findAll();

  // STEP 2: Boolean filters
  if (params.isFavorite != null) {
    results = results.where((l) => l.isFavorite == params.isFavorite).toList();
  }

  if (params.isRead != null) {
    results = results.where((l) => l.isRead == params.isRead).toList();
  }

  // STEP 3: Folder filter
  if (params.folder != null) {
    results = results
        .where((l) => l.folder.value?.id == params.folder!.id)
        .toList();
  }

  // STEP 4: Tag filter
  if (params.tag != null) {
    results = results
        .where((link) => link.tags.any((t) => t.id == params.tag!.id))
        .toList();
  }

  // STEP 5: Text search
  if (queryLower != null && queryLower.isNotEmpty) {
    results = results.where((link) {
      return (link.title.toLowerCase().contains(queryLower)) ||
          (link.description?.toLowerCase().contains(queryLower) ?? false) ||
          (link.url.toLowerCase().contains(queryLower)) ||
          (link.domain?.toLowerCase().contains(queryLower) ?? false) ||
          (link.siteName?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  // STEP 6: Sorting
  switch (params.sort) {
    case LinkSort.newest:
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case LinkSort.oldest:
      results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case LinkSort.lastOpened:
      results.sort((a, b) {
        final aTime = a.lastOpenedAt ?? DateTime(0);
        final bTime = b.lastOpenedAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
      break;
  }

  return results;
}