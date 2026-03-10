import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final undoStatusStorageServiceProvider = Provider<UndoStatusStorageService>((
  ref,
) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UndoStatusStorageService(prefs: prefs);
});

class UndoStatusStorageService {
  UndoStatusStorageService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;
  static const String _keyPrefix = 'undo_status_by_txid_';

  Map<String, String> readStatuses({required String userId}) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const <String, String>{};

    final raw = _prefs.getString('$_keyPrefix$normalizedUserId');
    if (raw == null || raw.trim().isEmpty) return const <String, String>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, String>{};

      final resolved = <String, String>{};
      decoded.forEach((key, value) {
        final txId = key.toString().trim();
        final status = value?.toString().trim();
        if (txId.isEmpty || status == null || status.isEmpty) return;
        resolved[txId] = status;
      });
      return resolved;
    } catch (_) {
      return const <String, String>{};
    }
  }

  Future<void> saveStatuses({
    required String userId,
    required Map<String, String> statuses,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final cleaned = <String, String>{};
    statuses.forEach((txId, status) {
      final normalizedTxId = txId.trim();
      final normalizedStatus = status.trim();
      if (normalizedTxId.isEmpty || normalizedStatus.isEmpty) return;
      cleaned[normalizedTxId] = normalizedStatus;
    });

    final key = '$_keyPrefix$normalizedUserId';
    if (cleaned.isEmpty) {
      await _prefs.remove(key);
      return;
    }

    await _prefs.setString(key, jsonEncode(cleaned));
  }

  Future<void> saveStatus({
    required String userId,
    required String txId,
    required String status,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedTxId = txId.trim();
    final normalizedStatus = status.trim();
    if (normalizedUserId.isEmpty ||
        normalizedTxId.isEmpty ||
        normalizedStatus.isEmpty) {
      return;
    }

    final next = readStatuses(userId: normalizedUserId);
    next[normalizedTxId] = normalizedStatus;
    await saveStatuses(userId: normalizedUserId, statuses: next);
  }

  String? readStatus({required String userId, required String txId}) {
    final normalizedUserId = userId.trim();
    final normalizedTxId = txId.trim();
    if (normalizedUserId.isEmpty || normalizedTxId.isEmpty) return null;

    return readStatuses(userId: normalizedUserId)[normalizedTxId];
  }
}
