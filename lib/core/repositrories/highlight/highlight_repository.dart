import 'package:isar/isar.dart';

import '../../../data/models/Highlight/highlight_model.dart';

class HighlightRepository {
  final Isar _isar;

  HighlightRepository(this._isar);

  Future<void> saveHighlight(HighlightModel highlight) async {
    await _isar.writeTxn(() async {
      await _isar.highlightModels.put(highlight);
    });
  }

  Future<List<HighlightModel>> getByLinkId(int linkId) async {
    return _isar.highlightModels
        .filter()
        .linkIdEqualTo(linkId)
        .sortByCreatedAt()
        .findAll();
  }

  Stream<List<HighlightModel>> watchByLinkId(int linkId) {
    return _isar.highlightModels
        .filter()
        .linkIdEqualTo(linkId)
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  Future<void> deleteHighlight(int id) async {
    await _isar.writeTxn(() async {
      await _isar.highlightModels.delete(id);
    });
  }

  Future<void> updateNote(int id, String note) async {
    await _isar.writeTxn(() async {
      final highlight = await _isar.highlightModels.get(id);
      if (highlight == null) return;
      highlight.note = note;
      await _isar.highlightModels.put(highlight);
    });
  }
}
