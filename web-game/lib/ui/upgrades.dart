import 'package:flutter/material.dart';
import '../game/difficulty.dart';
import '../services/access_store.dart';

// Web v1 has unlimited puzzles, no billing SDK and no ad-dependent progress.
Future<bool> ensureAccess(BuildContext context, AccessKind kind, Difficulty tier) async => kind != AccessKind.hint || tier.allowsHints;
Future<void> useAccess(AccessKind kind, Difficulty tier, Future<void> Function() action) async {
  if (kind == AccessKind.hint && !tier.allowsHints) throw StateError('Pro stays unassisted');
  await action();
}
