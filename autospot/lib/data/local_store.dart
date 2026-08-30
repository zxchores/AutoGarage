import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import 'auth.dart';
import 'photo_web.dart' if (dart.library.io) 'photo_io.dart' as photos;

class AppSnapshot {
  const AppSnapshot({
    required this.ready,
    required this.profile,
    required this.garage,
    required this.achievements,
    required this.duels,
    required this.apiKey,
    this.sessionUserId,
    this.photoHashes = const [],
    this.lastDuelAt,
    this.huntCompletedOn,
    this.lastError,
    this.lightTheme = false,
    this.largeText = false,
    this.pendingSpots = const [],
  });

  final bool ready;
  final UserProfile? profile;
  final List<GarageCar> garage;
  final Set<String> achievements;
  final List<DuelRecord> duels;
  final String? apiKey;
  final String? sessionUserId;
  final List<String> photoHashes;
  final DateTime? lastDuelAt;
  final String? huntCompletedOn;
  final String? lastError;
  final bool lightTheme;
  final bool largeText;
  final List<PendingSpot> pendingSpots;

  bool get onboarded =>
      sessionUserId != null &&
      sessionUserId!.isNotEmpty &&
      profile != null &&
      profile!.name.trim().isNotEmpty;

  AppSnapshot copyWith({
    bool? ready,
    UserProfile? profile,
    List<GarageCar>? garage,
    Set<String>? achievements,
    List<DuelRecord>? duels,
    String? apiKey,
    String? sessionUserId,
    List<String>? photoHashes,
    DateTime? lastDuelAt,
    String? huntCompletedOn,
    String? lastError,
    bool? lightTheme,
    bool? largeText,
    List<PendingSpot>? pendingSpots,
    bool clearError = false,
    bool clearSession = false,
  }) =>
      AppSnapshot(
        ready: ready ?? this.ready,
        profile: clearSession ? null : (profile ?? this.profile),
        garage: clearSession ? const [] : (garage ?? this.garage),
        achievements: clearSession ? const {} : (achievements ?? this.achievements),
        duels: clearSession ? const [] : (duels ?? this.duels),
        apiKey: apiKey ?? this.apiKey,
        sessionUserId: clearSession ? null : (sessionUserId ?? this.sessionUserId),
        photoHashes: clearSession ? const [] : (photoHashes ?? this.photoHashes),
        lastDuelAt: clearSession ? null : (lastDuelAt ?? this.lastDuelAt),
        huntCompletedOn:
            clearSession ? null : (huntCompletedOn ?? this.huntCompletedOn),
        lastError: clearError ? null : (lastError ?? this.lastError),
        lightTheme: lightTheme ?? this.lightTheme,
        largeText: largeText ?? this.largeText,
        pendingSpots: clearSession ? const [] : (pendingSpots ?? this.pendingSpots),
      );
}

class LocalStore {
  static const _accounts = 'autospot.accounts';
  static const _session = 'autospot.session';
  static const _apiKey = 'autospot.apiKey';
  static const _legacyProfile = 'autospot.profile';
  static const _legacyGarage = 'autospot.garage';
  static const _legacyAchievements = 'autospot.achievements';
  static const _legacyDuels = 'autospot.duels';
  static const _legacyHashes = 'autospot.hashes';
  static const _legacyDuelAt = 'autospot.lastDuel';
  static const _legacyHunt = 'autospot.hunt';
  static const _light = 'autospot.ui.light';
  static const _large = 'autospot.ui.large';

  final Map<String, Uint8List> memoryPhotos = {};

  String _uk(String userId, String name) => 'autospot.user.$userId.$name';

  Future<List<UserAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accounts);
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List)
        .map((e) => UserAccount.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveAccounts(List<UserAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accounts,
      jsonEncode(accounts.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> setSession(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null || userId.isEmpty) {
      await prefs.remove(_session);
    } else {
      await prefs.setString(_session, userId);
    }
  }

  UserProfile? _readProfile(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  List<GarageCar> _readGarage(SharedPreferences prefs, String key) {
    return (jsonDecode(prefs.getString(key) ?? '[]') as List)
        .map((e) => GarageCar.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  List<DuelRecord> _readDuels(SharedPreferences prefs, String key) {
    return (jsonDecode(prefs.getString(key) ?? '[]') as List)
        .map((e) => DuelRecord.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<AppSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await loadAccounts();
    final session = prefs.getString(_session);
    UserAccount? account;
    if (session != null) {
      for (final item in accounts) {
        if (item.id == session) account = item;
      }
    }

    if (account == null) {
      return AppSnapshot(
        ready: true,
        profile: null,
        sessionUserId: null,
        garage: const [],
        achievements: const {},
        duels: const [],
        apiKey: prefs.getString(_apiKey),
        lightTheme: prefs.getBool(_light) ?? false,
        largeText: prefs.getBool(_large) ?? false,
      );
    }

    final profile = _readProfile(prefs, _uk(account.id, 'profile')) ??
        _readProfile(prefs, _legacyProfile);
    final garageRaw = prefs.getString(_uk(account.id, 'garage'));
    final garage = garageRaw != null
        ? _readGarage(prefs, _uk(account.id, 'garage'))
        : _readGarage(prefs, _legacyGarage);
    final achievements = (prefs.getStringList(_uk(account.id, 'achievements')) ??
            prefs.getStringList(_legacyAchievements) ??
            const <String>[])
        .toSet();
    final duelsRaw = prefs.getString(_uk(account.id, 'duels'));
    final duels = duelsRaw != null
        ? _readDuels(prefs, _uk(account.id, 'duels'))
        : _readDuels(prefs, _legacyDuels);
    final hashes = prefs.getStringList(_uk(account.id, 'hashes')) ??
        prefs.getStringList(_legacyHashes) ??
        const <String>[];

    return AppSnapshot(
      ready: true,
      profile: (profile ??
              UserProfile(
                id: account.id,
                name: account.name,
                city: account.city,
                xp: 0,
                createdAt: account.createdAt,
                login: account.login,
              ))
          .copyWith(login: account.login),
      sessionUserId: account.id,
      garage: garage,
      achievements: achievements,
      duels: duels,
      apiKey: prefs.getString(_apiKey),
      photoHashes: hashes,
      lastDuelAt: DateTime.tryParse(
        prefs.getString(_uk(account.id, 'lastDuel')) ??
            prefs.getString(_legacyDuelAt) ??
            '',
      ),
      huntCompletedOn:
          prefs.getString(_uk(account.id, 'hunt')) ?? prefs.getString(_legacyHunt),
      lightTheme: prefs.getBool(_light) ?? false,
      largeText: prefs.getBool(_large) ?? false,
      pendingSpots: ((jsonDecode(
                prefs.getString(_uk(account.id, 'pending')) ?? '[]',
              ) as List)
            .whereType<Map>()
            .map((e) => PendingSpot.fromJson(e.cast<String, dynamic>()))
            .toList()),
    );
  }

  Future<void> save(AppSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = snapshot.sessionUserId;
    final key = snapshot.apiKey;
    await prefs.setBool(_light, snapshot.lightTheme);
    await prefs.setBool(_large, snapshot.largeText);
    if (key == null || key.isEmpty) {
      await prefs.remove(_apiKey);
    } else {
      await prefs.setString(_apiKey, key);
    }
    if (userId == null || userId.isEmpty) {
      await prefs.remove(_session);
      return;
    }
    await prefs.setString(_session, userId);
    final profile = snapshot.profile;
    if (profile == null) {
      await prefs.remove(_uk(userId, 'profile'));
    } else {
      await prefs.setString(_uk(userId, 'profile'), jsonEncode(profile.toJson()));
    }
    await prefs.setString(
      _uk(userId, 'garage'),
      jsonEncode(snapshot.garage.map((e) => e.toJson()).toList()),
    );
    await prefs.setStringList(
      _uk(userId, 'achievements'),
      snapshot.achievements.toList(),
    );
    await prefs.setString(
      _uk(userId, 'duels'),
      jsonEncode(snapshot.duels.map((e) => e.toJson()).toList()),
    );
    await prefs.setStringList(_uk(userId, 'hashes'), snapshot.photoHashes);
    final duelAt = snapshot.lastDuelAt;
    if (duelAt == null) {
      await prefs.remove(_uk(userId, 'lastDuel'));
    } else {
      await prefs.setString(_uk(userId, 'lastDuel'), duelAt.toIso8601String());
    }
    final hunt = snapshot.huntCompletedOn;
    if (hunt == null) {
      await prefs.remove(_uk(userId, 'hunt'));
    } else {
      await prefs.setString(_uk(userId, 'hunt'), hunt);
    }
    await prefs.setString(
      _uk(userId, 'pending'),
      jsonEncode(snapshot.pendingSpots.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> migrateLegacyIfNeeded(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_uk(userId, 'garage')) != null) return;
    if (prefs.getString(_legacyGarage) == null &&
        prefs.getString(_legacyProfile) == null) {
      return;
    }
    final profile = _readProfile(prefs, _legacyProfile);
    if (profile != null) {
      await prefs.setString(
        _uk(userId, 'profile'),
        jsonEncode(profile.copyWith().toJson()),
      );
    }
    await prefs.setString(
      _uk(userId, 'garage'),
      prefs.getString(_legacyGarage) ?? '[]',
    );
    await prefs.setStringList(
      _uk(userId, 'achievements'),
      prefs.getStringList(_legacyAchievements) ?? const [],
    );
    await prefs.setString(
      _uk(userId, 'duels'),
      prefs.getString(_legacyDuels) ?? '[]',
    );
    await prefs.setStringList(
      _uk(userId, 'hashes'),
      prefs.getStringList(_legacyHashes) ?? const [],
    );
    final duelAt = prefs.getString(_legacyDuelAt);
    if (duelAt != null) {
      await prefs.setString(_uk(userId, 'lastDuel'), duelAt);
    }
    final hunt = prefs.getString(_legacyHunt);
    if (hunt != null) await prefs.setString(_uk(userId, 'hunt'), hunt);
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
