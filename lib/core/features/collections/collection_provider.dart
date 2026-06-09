import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/collection_model.dart';
import '../../database/providers/isar_provider.dart';
import 'collection_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  throw UnimplementedError('Initialize after isar is ready');
});

final collectionRepoProvider = FutureProvider<CollectionRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return CollectionRepository(isar);
});

final collectionsStreamProvider = StreamProvider<List<FolderModel>>((ref) async* {
  final repo = await ref.watch(collectionRepoProvider.future);
  yield* repo.watchAll();
});

final collectionsCountProvider = StreamProvider<int>((ref) async* {
  final repo = await ref.watch(collectionRepoProvider.future);
  yield* repo.watchCount();
});

final selectedFolderProvider = StateProvider<FolderModel?>((ref) => null);
