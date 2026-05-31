//This gives a live list of all tags (chips) and updates UI automatically

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../data/models/Tag/tag_model.dart';
import '../../database/providers/isar_provider.dart';

final tagListProvider = StreamProvider<List<TagModel>>((ref) async* {
  // Get Isar instance
  final isar = await ref.watch(isarProvider.future);


  // Watch all tags in database
  // - sorted alphabetically
  // - auto-updates UI whenever tags change
  yield* isar.tagModels.where().sortByName().watch(fireImmediately: true);
});
