import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../core/city.dart';
import '../data/app_permissions.dart';
import '../data/auth.dart';
import '../data/city_board.dart';
import '../data/cloud_sync.dart';
import '../data/local_store.dart';
import '../data/location_service.dart';
import '../data/vision_service.dart';
import '../domain/game_logic.dart';
import '../domain/meta.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());
final visionServiceProvider = Provider<VisionService>((ref) => VisionService());
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());
final cityBoardProvider = Provider<CityBoard>((ref) => CityBoard());
final cloudSyncProvider = Provider<CloudSync>((ref) => CloudSync());

final appProvider =
    NotifierProvider<AppController, AppSnapshot>(AppController.new);

GarageStats lineupOf(CityPlayer player) {
  if (player.hasLineup) {
    final rarest = Rarity.values[player.rarest.clamp(0, Rarity.values.length - 1)];
    return GarageStats(
      value: player.value,
      horsepower: player.hp,
      bodykits: player.kits,
      rarest: rarest,
      count: player.cars,
    );
  }
  return GarageStats(
    value: (player.xp * 8000).clamp(80000, 80000000),
    horsepower: (player.cars * 140).clamp(90, 6000),
    bodykits: player.cars ~/ 5,
    rarest: player.xp > 3500
        ? Rarity.epic
        : player.xp > 800
            ? Rarity.rare
            : Rarity.common,
    count: player.cars,
  );
}

class AppController extends Notifier<AppSnapshot> {
  static const _uuid = Uuid();

  UserAccount? _pendingAccount;
  UserAccount? _pendingLogin;
  CloudAccount? _pendingCloud;

  @override
  AppSnapshot build() {
    Future.microtask(reload);
    return const AppSnapshot(
      ready: false,
      profile: null,
      garage: [],
      achievements: {},
      duels: [],
      apiKey: null,
    );
  }

  LocalStore get _store => ref.read(localStoreProvider);

  Future<void> reload() async {
    final loaded = await _store.load();
    state = loaded;
  }

  Future<void> _persist() => _store.save(state);

  Future<UserAccount?> _sessionAccount() async {
    final id = state.sessionUserId;
    if (id == null) return null;
    for (final account in await _store.loadAccounts()) {
      if (account.id == id) return account;
    }
    return null;
  }

  Future<void> _cloudPush() async {
    final account = await _sessionAccount();
    final profile = state.profile;
    if (account == null || profile == null) return;
    try {
      await ref.read(cloudSyncProvider).saveAccount(
            account: account,
            profile: profile,
            garage: state.garage,
          );
    } catch (_) {}
  }

  DailyHunt get hunt => huntFor(DateTime.now());

  bool get huntDone => state.huntCompletedOn == huntDateKey(DateTime.now());

  int get upcomingStreak {
    final profile = state.profile;
    if (profile == null) return 1;
    return streakAfterSpot(
      lastSpotDay: profile.lastSpotDay,
      streak: profile.streak,
      now: DateTime.now(),
    );
  }

  Future<UserAccount> startRegister({
    required String login,
    required String password,
    required String name,
    required String city,
  }) async {
    final normalized = normalizeLogin(login);
    if (normalized.length < 3) {
      throw AuthException('Логин слишком короткий');
    }
    if (!RegExp(r'^[a-z0-9._-]{3,24}$').hasMatch(normalized)) {
      throw AuthException('Логин: латиница, цифры, точка или _');
    }
    if (!passwordLooksOk(password)) {
      throw AuthException('Пароль минимум 6 символов');
    }
    final nick = name.trim().isEmpty ? normalized : name.trim();
    final hometown = cityLabel(city);
    final accounts = await _store.loadAccounts();
    if (accounts.any((a) => a.login == normalized)) {
      throw AuthException('Такой логин уже занят');
    }
    final remote = await ref.read(cloudSyncProvider).loadAccount(normalized);
    if (remote != null) {
      throw AuthException('Такой логин уже занят');
    }
    final salt = newSalt();
    final account = UserAccount(
      id: _uuid.v4(),
      login: normalized,
      salt: salt,
      passwordHash: hashPassword(password, salt),
      totpSecret: newTotpSecret(),
      name: nick,
      city: hometown,
      createdAt: DateTime.now(),
    );
    _pendingAccount = account;
    _pendingLogin = null;
    _pendingCloud = null;
    return account;
  }

  Future<void> confirmRegister(String code) async {
    final pending = _pendingAccount;
    if (pending == null) {
      throw AuthException('Сначала заполни регистрацию');
    }
    if (!totpVerify(pending.totpSecret, code)) {
      throw AuthException('Неверный код 2FA');
    }
    final accounts = [...await _store.loadAccounts(), pending];
    await _store.saveAccounts(accounts);
    await _store.setSession(pending.id);
    await _store.migrateLegacyIfNeeded(pending.id);
    final profile = UserProfile(
      id: pending.id,
      name: pending.name,
      city: pending.city,
      xp: 0,
      createdAt: pending.createdAt,
      login: pending.login,
    );
    _pendingAccount = null;
    await reload();
    if (state.profile == null) {
      state = state.copyWith(
        sessionUserId: pending.id,
        profile: profile,
        achievements: unlockedAchievements(
          garage: state.garage,
          city: profile.city,
          already: state.achievements,
        ),
      );
      await _persist();
    }
    await AppPermissions.requestAll();
    await publishPresence();
    await _cloudPush();
  }

  Future<void> startLogin({
    required String login,
    required String password,
  }) async {
    final normalized = normalizeLogin(login);
    final accounts = await _store.loadAccounts();
    UserAccount? match;
    for (final account in accounts) {
      if (account.login == normalized) match = account;
    }
    if (match != null) {
      if (hashPassword(password, match.salt) != match.passwordHash) {
        throw AuthException('Неверный пароль');
      }
      _pendingLogin = match;
      _pendingAccount = null;
      _pendingCloud = null;
      return;
    }
    final remote = await ref.read(cloudSyncProvider).loadAccount(normalized);
    if (remote == null) {
      throw AuthException('Нет такого логина');
    }
    if (hashPassword(password, remote.account.salt) !=
        remote.account.passwordHash) {
      throw AuthException('Неверный пароль');
    }
    _pendingLogin = remote.account;
    _pendingCloud = remote;
    _pendingAccount = null;
  }

  Future<void> confirmLogin(String code) async {
    final pending = _pendingLogin;
    if (pending == null) {
      throw AuthException('Сначала введи логин и пароль');
    }
    if (!totpVerify(pending.totpSecret, code)) {
      throw AuthException('Неверный код 2FA');
    }
    final cloud = _pendingCloud;
    if (cloud != null) {
      final accounts = await _store.loadAccounts();
      if (!accounts.any((a) => a.id == pending.id)) {
        await _store.saveAccounts([...accounts, pending]);
      }
      await _store.setSession(pending.id);
      _pendingLogin = null;
      _pendingCloud = null;
      await reload();
      state = state.copyWith(
        sessionUserId: pending.id,
        profile: cloud.profile,
        garage: cloud.garage.isEmpty ? state.garage : cloud.garage,
      );
      await _persist();
    } else {
      await _store.setSession(pending.id);
      _pendingLogin = null;
      await reload();
    }
    await AppPermissions.requestAll();
    await publishPresence();
  }

  Future<void> logout() async {
    await _store.setSession(null);
    _pendingAccount = null;
    _pendingLogin = null;
    _pendingCloud = null;
    state = state.copyWith(clearSession: true, ready: true);
  }

  Future<void> updateProfile({String? name, String? city, String? clan}) async {
    final profile = state.profile;
    if (profile == null) return;
    final next = profile.copyWith(
      name: name,
      city: city == null ? profile.city : cityLabel(city),
      clan: clan,
    );
    state = state.copyWith(
      profile: next,
      achievements: unlockedAchievements(
        garage: state.garage,
        city: next.city,
        already: state.achievements,
      ),
    );
    await _persist();
    await publishPresence();
    await _cloudPush();
  }

  Future<void> setTheme({bool? light, bool? large}) async {
    state = state.copyWith(
      lightTheme: light,
      largeText: large,
    );
    await _persist();
  }

  Future<List<CityPlayer>> publishPresence() async {
    final profile = state.profile;
    if (profile == null || profile.city.trim().isEmpty) return const [];
    final uniqueCars = state.garage
        .map((c) => (c.catalogId ?? '${c.make}|${c.model}').toLowerCase())
        .toSet()
        .length;
    final stats = statsFor(state.garage);
    return ref.read(cityBoardProvider).publish(
          city: profile.city,
          me: CityPlayer(
            id: profile.id,
            name: profile.name,
            xp: profile.xp,
            cars: uniqueCars,
            lastSeen: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            value: stats.value,
            hp: stats.horsepower,
            kits: stats.bodykits,
            rarest: stats.rarest.rank,
            clan: profile.clan,
          ),
        );
  }

  Future<List<CityPlayer>> cityPlayers() async {
    final profile = state.profile;
    if (profile == null || profile.city.trim().isEmpty) return const [];
    final remote = await publishPresence();
    if (remote.isNotEmpty) return remote;
    return [
      CityPlayer(
        id: profile.id,
        name: profile.name,
        xp: profile.xp,
        cars: state.garage
            .map((c) => (c.catalogId ?? '${c.make}|${c.model}').toLowerCase())
            .toSet()
            .length,
        lastSeen: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        clan: profile.clan,
      ),
    ];
  }

  Future<void> saveApiKey(String key) async {
    state = state.copyWith(apiKey: key.trim());
    await _persist();
  }

  Future<void> backupCloud() => _cloudPush();

  Future<void> restoreCloud() async {
    final account = await _sessionAccount();
    if (account == null) return;
    final remote = await ref.read(cloudSyncProvider).loadAccount(account.login);
    if (remote == null) {
      throw AuthException('В облаке пусто');
    }
    state = state.copyWith(
      profile: remote.profile,
      garage: remote.garage.isEmpty ? state.garage : remote.garage,
    );
    await _persist();
  }

  IdentifiedSpot _withStreak(IdentifiedSpot raw) {
    return buildIdentifiedSpot(
      extraction: raw.extraction,
      spec: raw.spec,
      photoBytes: raw.photoBytes,
      photoHash: raw.photoHash,
      photoHints: raw.photoHints,
      garage: state.garage,
      fromAi: raw.fromAi,
      needsCatalogPick: raw.needsCatalogPick,
      huntMatch: raw.spec != null && hunt.matchesSpot(raw) && !huntDone,
      streakDays: upcomingStreak,
    );
  }

  Future<IdentifiedSpot> identifyBytes(
    Uint8List bytes, {
    bool queueOnFail = true,
  }) async {
    final hash = photoHashOf(bytes);
    if (state.photoHashes.contains(hash)) {
      throw DuplicatePhotoException();
    }
    try {
      final raw = await ref.read(visionServiceProvider).identify(
            photoBytes: bytes,
            apiKey: state.apiKey,
            garage: state.garage,
            huntMatch: false,
          );
      return _withStreak(raw);
    } on DuplicatePhotoException {
      rethrow;
    } on NoCarFoundException {
      rethrow;
    } catch (e) {
      if (queueOnFail && e is RecognitionFailedException) {
        await enqueuePending(bytes);
      }
      rethrow;
    }
  }

  Future<IdentifiedSpot> identify(XFile file) async {
    return identifyBytes(Uint8List.fromList(await file.readAsBytes()));
  }

  Future<void> enqueuePending(Uint8List bytes) async {
    final photoId = await _store.savePhoto(bytes);
    final item = PendingSpot(
      id: _uuid.v4(),
      photoId: photoId,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(pendingSpots: [item, ...state.pendingSpots]);
    await _persist();
  }

  Future<IdentifiedSpot?> retryPending(PendingSpot item) async {
    final bytes = await _store.loadPhoto(item.photoId);
    if (bytes == null) {
      state = state.copyWith(
        pendingSpots: state.pendingSpots.where((e) => e.id != item.id).toList(),
      );
      await _persist();
      return null;
    }
    final spot = await identifyBytes(bytes, queueOnFail: false);
    state = state.copyWith(
      pendingSpots: state.pendingSpots.where((e) => e.id != item.id).toList(),
    );
    await _persist();
    return spot;
  }

  Future<GeoFix?> locate() => ref.read(locationServiceProvider).current();

  Future<List<String>> commitSpot(IdentifiedSpot spot, GeoFix? geo) async {
    if (spot.spec == null) {
      throw StateError('Модель не распознана');
    }
    if (state.photoHashes.contains(spot.photoHash)) {
      throw DuplicatePhotoException();
    }
    final photoId = await _store.savePhoto(Uint8List.fromList(spot.photoBytes));
    final profile = state.profile;
    if (profile == null) {
      throw StateError('Нет профиля');
    }
    final rawCity = (geo?.city.isNotEmpty == true) ? geo!.city : profile.city;
    final city = cityLabel(rawCity);
    final spec = spot.spec!;
    final extraction = spot.extraction;
    final nextStreak = streakAfterSpot(
      lastSpotDay: profile.lastSpotDay,
      streak: profile.streak,
      now: DateTime.now(),
    );
    var resolved = buildIdentifiedSpot(
      extraction: extraction,
      spec: spec,
      photoBytes: spot.photoBytes,
      photoHash: spot.photoHash,
      photoHints: spot.photoHints,
      garage: state.garage,
      fromAi: spot.fromAi,
      needsCatalogPick: false,
      huntMatch: hunt.matchesSpot(spot) && !huntDone,
      streakDays: nextStreak,
    );
    final color = normalizeColor(extraction.color);
    final car = GarageCar(
      id: _uuid.v4(),
      photoId: photoId,
      spottedAt: DateTime.now(),
      city: city,
      lat: geo?.lat,
      lng: geo?.lng,
      make: spec.make,
      model: spec.model,
      generation: extraction.generation.isEmpty
          ? spec.generation
          : extraction.generation,
      yearFrom: spec.yearFrom,
      yearTo: spec.yearTo,
      color: color,
      bodyType: spec.bodyType,
      rarity: spec.rarity,
      priceRub: spec.priceRub,
      horsepower: spec.horsepower,
      zeroToHundred: spec.zeroToHundred,
      drivetrain: spec.drivetrain,
      condition: extraction.condition,
      tuning: extraction.tuning,
      photoQuality: extraction.photoQuality,
      confidence: extraction.confidence,
      xpEarned: resolved.xp,
      catalogId: spec.id,
      fromAi: resolved.fromAi,
      district: geo?.district ?? '',
    );
    final garage = [car, ...state.garage];
    var huntOn = state.huntCompletedOn;
    if (!huntDone && hunt.matches(car)) {
      huntOn = huntDateKey(DateTime.now());
    }
    final nextProfile = profile.copyWith(
      xp: profile.xp + resolved.xp,
      city: city.isEmpty ? profile.city : city,
      streak: nextStreak,
      lastSpotDay: huntDateKey(DateTime.now()),
    );
    final before = state.achievements;
    final after = unlockedAchievements(
      garage: garage,
      city: nextProfile.city,
      already: before,
    );
    state = state.copyWith(
      profile: nextProfile,
      garage: garage,
      achievements: after,
      photoHashes: [...state.photoHashes, resolved.photoHash],
      huntCompletedOn: huntOn,
      clearError: true,
    );
    await _persist();
    await publishPresence();
    try {
      await ref.read(cloudSyncProvider).postSighting(
            city: nextProfile.city,
            catalogId: spec.id,
            nick: nextProfile.name,
          );
    } catch (_) {}
    await _cloudPush();
    return after.difference(before).toList();
  }

  DuelRecord duelWith(List<GarageCar> lineup, {CityPlayer? rival}) {
    final left = duelCooldownLeft(state.lastDuelAt);
    if (left != null) {
      throw StateError('Подожди ${left.inMinutes + 1} мин до следующей дуэли');
    }
    if (lineup.length != 3) {
      throw StateError('Выбери ровно 3 машины');
    }
    if (rival != null && rival.id == state.profile?.id) {
      throw StateError('Нельзя дуэлиться с собой');
    }
    final record = runDuel(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      user: statsFor(lineup),
      rival: rival == null ? ghostLineup(DateTime.now()) : lineupOf(rival),
      rivalId: rival?.id ?? 'ghost',
      rivalName: rival?.name ?? 'Тренировка',
    );
    final xp = duelXp(record);
    final profile = state.profile;
    state = state.copyWith(
      duels: [record, ...state.duels],
      lastDuelAt: DateTime.now(),
      profile: profile?.copyWith(xp: (profile.xp) + xp),
    );
    _persist();
    publishPresence();
    _cloudPush();
    return record;
  }

  Future<List<Sighting>> carSightings(String catalogId) async {
    final city = state.profile?.city ?? '';
    return ref.read(cloudSyncProvider).sightings(city: city, catalogId: catalogId);
  }

  Future<Uint8List?> photo(String id) => _store.loadPhoto(id);
}
