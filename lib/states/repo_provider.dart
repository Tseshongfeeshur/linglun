import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/data/database/database.dart';
import 'package:linglun/data/repo/repo.dart';

final databaseProvider = Provider<LinglunDatabase>((ref) {
  final db = LinglunDatabase();
  ref.onDispose(db.close);
  return db;
});

final repoProvider = Provider<Repo>((ref) {
  final db = ref.watch(databaseProvider);
  return Repo(db);
});
