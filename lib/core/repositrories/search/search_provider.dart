import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recallr/core/repositrories/search/search_file.dart';

import '../../../data/models/Link/link_model.dart';
import '../../../data/models/search/search_model.dart';
import '../../database/providers/isar_provider.dart';

final searchParamsProvider = StateProvider<LinkSearchParams>(
      (_) =>  LinkSearchParams(),
);

final searchResultsProvider =
FutureProvider.family<List<LinkModel>, LinkSearchParams>(
      (ref, params) async {
    final isar = await ref.read(isarProvider.future);
    return searchLinks(isar, params);
  },
);

enum ViewMode { list, compact }

final viewModeProvider = StateProvider<ViewMode>((ref) {
  return ViewMode.list;
});
