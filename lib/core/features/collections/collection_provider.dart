import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/collection_model.dart';
import '../../../data/models/Link/link_model.dart';
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
  await for (final folders in repo.watchAll()) {
    // Load backlinks so folder.links.length is accurate everywhere
    await Future.wait(folders.map((f) => f.links.load()));
    yield folders;
  }
});

final collectionsCountProvider = StreamProvider<int>((ref) async* {
  final repo = await ref.watch(collectionRepoProvider.future);
  yield* repo.watchCount();
});

final selectedFolderProvider = StateProvider<FolderModel?>((ref) => null);

final folderLinksProvider = StreamProvider.autoDispose
    .family<List<LinkModel>, int>((ref, folderId) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.linkModels.watchLazy(fireImmediately: true).asyncMap((_) async {
    final folder = await isar.folderModels.get(folderId);
    if (folder == null) return <LinkModel>[];
    await folder.links.load();
    final links = folder.links.toList();
    await Future.wait(links.map((l) => l.tags.load()));
    links.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return links;
  });
});
