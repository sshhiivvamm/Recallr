import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME']!;
    final dylib =
        '$home/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(
      libraries: {
        Abi.macosArm64: dylib,
        Abi.macosX64: dylib,
      },
    );
  }
  await testMain();
}
