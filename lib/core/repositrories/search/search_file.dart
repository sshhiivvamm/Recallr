import 'package:isar/isar.dart';

import '../../../data/models/Highlight/highlight_model.dart';
import '../../../data/models/Link/link_model.dart';
import '../../../data/models/search/search_model.dart';

Future<List<SearchResult>> searchLinks(
    Isar isar,
    LinkSearchParams params,
    ) async {
  final queryLower = params.query?.toLowerCase().trim();

  // Push the most-selective boolean filters into Isar so we don't load the
  // full table into Dart when the user is browsing Favourites or Unread.
  List<LinkModel> results;
  if (params.isFavorite != null && params.isRead != null) {
    results = await isar.linkModels
        .filter()
        .isFavoriteEqualTo(params.isFavorite!)
        .isReadEqualTo(params.isRead!)
        .findAll();
  } else if (params.isFavorite != null) {
    results = await isar.linkModels
        .filter()
        .isFavoriteEqualTo(params.isFavorite!)
        .findAll();
  } else if (params.isRead != null) {
    results = await isar.linkModels
        .filter()
        .isReadEqualTo(params.isRead!)
        .findAll();
  } else {
    results = await isar.linkModels.where().findAll();
  }

  if (params.folder != null) {
    await Future.wait(results.map((l) => l.folder.load()));
    results = results
        .where((l) => l.folder.value?.id == params.folder!.id)
        .toList();
  }

  // Load tags unconditionally — required for tag-filter AND for badge display
  await Future.wait(results.map((l) => l.tags.load()));

  if (params.tag != null) {
    results = results
        .where((link) => link.tags.any((t) => t.id == params.tag!.id))
        .toList();
  }

  // Push text matching to Isar's C layer when a query is present.
  // This avoids deserializing every record into Dart just to call .contains().
  if (queryLower != null && queryLower.isNotEmpty) {
    results = await isar.linkModels
        .filter()
        .titleContains(queryLower, caseSensitive: false)
        .or()
        .descriptionContains(queryLower, caseSensitive: false)
        .or()
        .notesContains(queryLower, caseSensitive: false)
        .or()
        .urlContains(queryLower, caseSensitive: false)
        .or()
        .domainContains(queryLower, caseSensitive: false)
        .or()
        .siteNameContains(queryLower, caseSensitive: false)
        .findAll();
    // Boolean filters applied in Dart — just field comparisons on already-loaded objects.
    if (params.isFavorite != null) {
      results = results.where((l) => l.isFavorite == params.isFavorite!).toList();
    }
    if (params.isRead != null) {
      results = results.where((l) => l.isRead == params.isRead!).toList();
    }
  }

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

  final linkResults = results
      .map((link) => _makeResult(link, params.query?.trim()))
      .toList();

  // Also surface links whose saved highlights match the query.
  // textContains() filters C-side in Isar — avoids loading all highlight text.
  if (queryLower != null && queryLower.isNotEmpty) {
    final existingIds = results.map((l) => l.id).toSet();
    final seenIds = <int>{};
    final matchingHighlights = await isar.highlightModels
        .filter()
        .textContains(queryLower, caseSensitive: false)
        .findAll();
    for (final h in matchingHighlights) {
      if (existingIds.contains(h.linkId)) continue; // already in link results
      if (!seenIds.add(h.linkId)) continue;          // deduplicate same link
      final link = await isar.linkModels.get(h.linkId);
      if (link == null) continue;
      await link.tags.load();
      final snippet =
          h.text.length > 120 ? '${h.text.substring(0, 120)}…' : h.text;
      linkResults.add(SearchResult(
        link: link,
        matchedField: MatchedField.highlight,
        snippet: snippet,
      ));
    }
  }

  return linkResults;
}

SearchResult _makeResult(LinkModel link, String? query) {
  if (query == null || query.isEmpty) {
    return SearchResult(link: link, matchedField: MatchedField.title);
  }
  final lower = query.toLowerCase();

  if (link.title.toLowerCase().contains(lower)) {
    return SearchResult(link: link, matchedField: MatchedField.title);
  }
  if (link.description?.toLowerCase().contains(lower) == true) {
    return SearchResult(
      link: link,
      matchedField: MatchedField.description,
      snippet: _extractSnippet(link.description, query),
    );
  }
  if (link.notes?.toLowerCase().contains(lower) == true) {
    return SearchResult(
      link: link,
      matchedField: MatchedField.notes,
      snippet: _extractSnippet(link.notes, query),
    );
  }
  // url/domain/siteName match — no snippet useful to surface
  return SearchResult(link: link, matchedField: MatchedField.title);
}

String? _extractSnippet(String? text, String query) {
  if (text == null || text.isEmpty) return null;
  final lower = text.toLowerCase();
  final idx = lower.indexOf(query.toLowerCase());
  if (idx == -1) return null;
  const halfWindow = 55;
  final start = (idx - halfWindow).clamp(0, text.length);
  final end = (idx + query.length + halfWindow).clamp(0, text.length);
  var snippet = text.substring(start, end).trim();
  if (start > 0) snippet = '…$snippet';
  if (end < text.length) snippet = '$snippet…';
  return snippet;
}
