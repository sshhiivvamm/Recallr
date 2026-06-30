import 'package:isar/isar.dart';

import '../../../data/models/collection_model.dart';
import '../../../data/models/Link/link_model.dart';

class CollectionRepository {
  final Isar isar;

  CollectionRepository(this.isar);

  Stream<List<FolderModel>> watchAll() async* {
    await for (final folders in isar.folderModels
        .where()
        .sortBySortOrder()
        .watch(fireImmediately: true)) {
      await Future.wait(folders.map((f) => f.links.load()));
      yield folders;
    }
  }

  Future<List<FolderModel>> getAll() {
    return isar.folderModels.where().sortBySortOrder().findAll();
  }

  Future<FolderModel> create(String name, {String? icon, String? colorHex}) async {
    final folder = FolderModel()
      ..name = name
      ..icon = icon
      ..colorHex = colorHex
      ..sortOrder = await isar.folderModels.count();

    await isar.writeTxn(() async {
      await isar.folderModels.put(folder);
    });
    return folder;
  }

  Future<void> rename(int id, String newName) async {
    await isar.writeTxn(() async {
      final folder = await isar.folderModels.get(id);
      if (folder == null) return;
      folder.name = newName;
      await isar.folderModels.put(folder);
    });
  }

  Future<void> delete(int id) async {
    await isar.writeTxn(() async {
      final folder = await isar.folderModels.get(id);
      if (folder == null) return;
      await folder.links.load();
      for (final link in folder.links) {
        link.folder.value = null;
        await link.folder.save();
      }
      await isar.folderModels.delete(id);
    });
  }

  Future<void> assignToLink(int linkId, FolderModel? folder) async {
    await isar.writeTxn(() async {
      final link = await isar.linkModels.get(linkId);
      if (link == null) return;
      // Must load before clearing; Isar won't save a null on an unloaded link.
      if (folder == null) await link.folder.load();
      link.folder.value = folder;
      await link.folder.save();
    });
  }

  Future<List<LinkModel>> getLinksByFolder(int folderId) async {
    final folder = await isar.folderModels.get(folderId);
    if (folder == null) return [];
    await folder.links.load();
    final links = folder.links.toList();
    await Future.wait(links.map((l) => l.tags.load()));
    links.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return links;
  }

  Stream<int> watchCount() {
    return isar.folderModels
        .where()
        .watch(fireImmediately: true)
        .map((f) => f.length);
  }
}
