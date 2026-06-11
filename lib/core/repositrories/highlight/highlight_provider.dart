import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/providers/isar_provider.dart';
import 'highlight_repository.dart';

final highlightRepositoryProvider = Provider<HighlightRepository>((ref) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => HighlightRepository(isar),
    loading: () => throw Exception('Isar loading'),
    error: (e, _) => throw Exception(e),
  );
});
