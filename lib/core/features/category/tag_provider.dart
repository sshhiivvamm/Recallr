// features/categories/providers/tag_repository_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recallr/core/features/category/tag_repository.dart';
import '../../database/providers/isar_provider.dart';


final tagRepositoryProvider = Provider<TagRepository>((ref) {
  // Get Isar instance (async state)
  final isarAsync = ref.watch(isarProvider);

  return isarAsync.when(
    // When DB is ready → create repository
    data: (isar) => TagRepository(isar),

    // If still loading → throw error (should not be used yet)
    loading: () => throw Exception("Isar loading"),

    // If error → forward error
    error: (e, _) => throw Exception(e),
  );
});
