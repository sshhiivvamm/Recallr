import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final readerModeDefaultProvider =
    StateNotifierProvider<ReaderDefaultNotifier, bool>(
  (ref) => ReaderDefaultNotifier(),
);

class ReaderDefaultNotifier extends StateNotifier<bool> {
  ReaderDefaultNotifier() : super(false) {
    SharedPreferences.getInstance().then((p) {
      if (mounted) state = p.getBool(_key) ?? false;
    });
  }

  static const _key = 'reader_mode_default';

  Future<void> set(bool val) async {
    state = val;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, val);
  }
}
