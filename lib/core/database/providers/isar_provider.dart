import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../isar_service.dart';



final isarProvider = FutureProvider<Isar>((ref) async {

  // This provider gives access to the Isar database instance
  // anywhere in the app using Riverpod.

  // It waits until the database is fully initialized
  // and then returns the Isar object.

  return await IsarService.instance.db;
});