import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meeting.dart';

/// Persistencia local de las reuniones. Usa shared_preferences para que funcione
/// igual en Android, iOS, web y Windows sin depender del sistema de archivos.
class MeetingStore {
  static const _key = 'meetings_v1';

  Future<List<Meeting>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Meeting.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  Future<void> save(List<Meeting> meetings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(meetings.map((m) => m.toJson()).toList()),
    );
  }
}
