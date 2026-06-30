import 'dart:math';

import '../../data/models/Link/link_model.dart';
import '../database/isar_service.dart';

class Sm2Data {
  final int repetitions;
  final double easeFactor;
  final int interval;
  final DateTime? nextReviewAt;

  const Sm2Data({
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.nextReviewAt,
  });
}

class Sm2Service {
  Sm2Service._();
  static final Sm2Service instance = Sm2Service._();

  static const double _minEase = 1.3;

  Sm2Data _fromModel(LinkModel link) => Sm2Data(
        repetitions: link.smRepetitions,
        easeFactor: link.smEaseFactor,
        interval: link.smInterval,
        nextReviewAt: link.smNextReview,
      );

  Future<Sm2Data> getData(int linkId) async {
    final isar = await IsarService.instance.db;
    final link = await isar.linkModels.get(linkId);
    if (link == null) return const Sm2Data();
    return _fromModel(link);
  }

  // quality: 1=Forgot, 3=Hard, 4=Good, 5=Easy
  Future<void> review(int linkId, int quality) async {
    final isar = await IsarService.instance.db;
    await isar.writeTxn(() async {
      final link = await isar.linkModels.get(linkId);
      if (link == null) return;
      final next = _compute(_fromModel(link), quality);
      link.smRepetitions = next.repetitions;
      link.smEaseFactor = next.easeFactor;
      link.smInterval = next.interval;
      link.smNextReview = next.nextReviewAt;
      await isar.linkModels.put(link);
    });
  }

  Sm2Data _compute(Sm2Data current, int quality) {
    int reps = current.repetitions;
    double ease = current.easeFactor;
    int interval;

    if (quality < 3) {
      // Failed — reset to beginning
      reps = 0;
      interval = 1;
    } else {
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 6;
      } else {
        interval = (current.interval * ease).round();
      }
      reps += 1;
      ease = max(
        _minEase,
        ease + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02),
      );
    }

    return Sm2Data(
      repetitions: reps,
      easeFactor: ease,
      interval: interval,
      nextReviewAt: DateTime.now().add(Duration(days: interval)),
    );
  }

  bool isDue(Sm2Data data) {
    if (data.nextReviewAt == null) return true;
    return data.nextReviewAt!.isBefore(DateTime.now());
  }

  // SM-2 data is now on the model — no I/O needed here
  Future<List<LinkModel>> getReviewQueue(List<LinkModel> allLinks) async {
    final due = <LinkModel>[];
    for (final link in allLinks) {
      if (isDue(_fromModel(link))) due.add(link);
    }
    due.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return due;
  }

  Future<int> getDueCount(List<LinkModel> allLinks) async {
    return (await getReviewQueue(allLinks)).length;
  }
}
