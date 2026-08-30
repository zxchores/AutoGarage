import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import 'photo_web.dart' if (dart.library.io) 'photo_io.dart' as photos;

class AppSnapshot {
  const AppSnapshot({
    required this.ready,
    required this.profile,
    required this.garage,
    required this.achievements,
    required this.duels,
    required this.apiKey,
    this.photoHashes = const [],
    this.lastDuelAt,
    this.huntCompletedOn,
    this.lastError,
  });

  final bool ready;
  final UserProfile? profile;
  final List<GarageCar> garage;
  final Set<String> achievements;
  final List<DuelRecord> duels;
  final String? apiKey;
  final List<String> photoHashes;
  final DateTime? lastDuelAt;
  final String? huntCompletedOn;
  final String? lastError;

  bool get onboarded => profile != null && profile!.name.trim().isNotEmpty;

  AppSnapshot copyWith({
    bool? ready,
    UserProfile? profile,
    List<GarageCar>? garage,
    Set<String>? achievements,
    List<DuelRecord>? duels,
    String? apiKey,
    List<String>? photoHashes,
    DateTime? lastDuelAt,
    String? huntCompletedOn,
    String? lastError,
    bool clearError = false,
  }) =>
      AppSnapshot(
        ready: ready ?? this.ready,
        profile: profile ?? this.profile,
        garage: garage ?? this.garage,
        achievements: achievements ?? this.achievements,
        duels: duels ?? this.duels,
        apiKey: apiKey ?? this.apiKey,
        photoHashes: photoHashes ?? this.photoHashes,
        lastDuelAt: lastDuelAt ?? this.lastDuelAt,
        huntCompletedOn: huntCompletedOn ?? this.huntCompletedOn,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}

class LocalStore {
  static const _profile = 'autospot.profile';
  static const _garage = 'autospot.garage';
  static const _achievements = 'autospot.achievements';
  static const _duels = 'autospot.duels';
  static const _apiKey = 'autospot.apiKey';
  static const _hashes = 'autospot.hashes';
  static const _duelAt = 'autospot.lastDuel';
  static const _hunt = 'autospot.hunt';

  final Map<String, Uint8List> memoryPhotos = {};

  Future<AppSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    UserProfile? profile;
    final rawProfile = prefs.getString(_profile);
    if (rawProfile != null) {
      profile =
          UserProfile.fromJson(jsonDecode(rawProfile) as Map<String, dynamic>);
    }
    final garage = (jsonDecode(prefs.getString(_garage) ?? '[]') as List)
        .map((e) => GarageCar.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final achievements =
        (prefs.getStringList(_achievements) ?? const <String>[]).toSet();
    final duels = (jsonDecode(prefs.getString(_duels) ?? '[]') as List)
        .map((e) => DuelRecord.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return AppSnapshot(
      ready: true,
      profile: profile,
      garage: garage,
      achievements: achievements,
      duels: duels,
      apiKey: prefs.getString(_apiKey),
      photoHashes: prefs.getStringList(_hashes) ?? const [],
      lastDuelAt: DateTime.tryParse(prefs.getString(_duelAt) ?? ''),
      huntCompletedOn: prefs.getString(_hunt),
    );
  }

  Future<void> save(AppSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = snapshot.profile;
    if (profile == null) {
      await prefs.remove(_profile);
    } else {
      await prefs.setString(_profile, jsonEncode(profile.toJson()));
    }
    await prefs.setString(
      _garage,
      jsonEncode(snapshot.garage.map((e) => e.toJson()).toList()),
    );
    await prefs.setStringList(_achievements, snapshot.achievements.toList());
    await prefs.setString(
      _duels,
      jsonEncode(snapshot.duels.map((e) => e.toJson()).toList()),
    );
    final key = snapshot.apiKey;
    if (key == null || key.isEmpty) {
      await prefs.remove(_apiKey);
    } else {
      await prefs.setString(_apiKey, key);
    }
    await prefs.setStringList(_hashes, snapshot.photoHashes);
    final duelAt = snapshot.lastDuelAt;
    if (duelAt == null) {
      await prefs.remove(_duelAt);
    } else {
      await prefs.setString(_duelAt, duelAt.toIso8601String());
    }
    final hunt = snapshot.huntCompletedOn;
    if (hunt == null) {
      await prefs.remove(_hunt);
    } else {
      await prefs.setString(_hunt, hunt);
    }
  }

  Future<String> savePhoto(Uint8List bytes) async {
    final id = const Uuid().v4();
    memoryPhotos[id] = bytes;
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        await photos.writePhotoFile(dir.path, id, bytes);
      } catch (_) {}
    }
    return id;
  }

  Future<Uint8List?> loadPhoto(String id) async {
    final cached = memoryPhotos[id];
    if (cached != null) return cached;
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final bytes = await photos.readPhotoFile(dir.path, id);
      if (bytes != null) memoryPhotos[id] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }
}
