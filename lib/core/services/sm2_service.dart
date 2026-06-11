import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/Link/link_model.dart';

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

  Map<String, dynamic> toJson() => {
        'reps': repetitions,
        'ease': easeFactor,
        'interval': interval,
        'nextReview': nextReviewAt?.toIso8601String(),
      };

  factory Sm2Data.fromJson(Map<String, dynamic> j) => Sm2Data(
        repetitions: (j['reps'] as int?) ?? 0,
        easeFactor: (j['ease'] as num?)?.toDouble() ?? 2.5,
        interval: (j['interval'] as int?) ?? 1,
        nextReviewAt: j['nextReview'] != null
            ? DateTime.tryParse(j['nextReview'] as String)
            : null,
      );
}

class Sm2Service {
  Sm2Service._();
  static final Sm2Service instance = Sm2Service._();

  static const double _minEase = 1.3;

  String _key(int linkId) => 'sm2_$linkId';

  Future<Sm2Data> getData(int linkId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(linkId));
    if (raw == null) return const Sm2Data();
    try {
      return Sm2Data.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const Sm2Data();
    }
  }

  // quality: 1=Forgot, 3=Hard, 4=Good, 5=Easy
  Future<void> review(int linkId, int quality) async {
    final current = await getData(linkId);
    final next = _compute(current, quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(linkId), jsonEncode(next.toJson()));
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

  Future<List<LinkModel>> getReviewQueue(List<LinkModel> allLinks) async {
    final prefs = await SharedPreferences.getInstance();
    final due = <LinkModel>[];

    for (final link in allLinks) {
      final raw = prefs.getString(_key(link.id));
      if (raw == null) {
        due.add(link);
        continue;
      }
      try {
        final data = Sm2Data.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (isDue(data)) due.add(link);
      } catch (_) {
        due.add(link);
      }
    }

    // Oldest unseen links first, then re-reviews
    due.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return due;
  }

  Future<int> getDueCount(List<LinkModel> allLinks) async {
    final queue = await getReviewQueue(allLinks);
    return queue.length;
  }
}
