import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/providers/isar_provider.dart';
import 'link_repository.dart';

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  // Get Isar async state
  final isarAsync = ref.watch(isarProvider);

  return isarAsync.when(
    // When DB is ready → return repository
    data: (isar) => LinkRepository(isar),

    // While loading → prevent usage
    loading: () => throw Exception("Isar loading"),

    // On error → forward error
    error: (e, _) => throw Exception(e),
  );
});