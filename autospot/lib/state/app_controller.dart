import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../data/app_permissions.dart';
import '../data/auth.dart';
import '../data/local_store.dart';
import '../data/location_service.dart';
import '../data/vision_service.dart';
import '../domain/game_logic.dart';
import '../domain/meta.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());
final visionServiceProvider = Provider<VisionService>((ref) => VisionService());
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final appProvider =
    NotifierProvider<AppController, AppSnapshot>(AppController.new);

class AppController extends Notifier<AppSnapshot> {
  static const _uuid = Uuid();

  UserAccount? _pendingAccount;
  UserAccount? _pendingLogin;

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

  DailyHunt get hunt => huntFor(DateTime.now());

  bool get huntDone => state.huntCompletedOn == huntDateKey(DateTime.now());

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
    final accounts = await _store.loadAccounts();
    if (accounts.any((a) => a.login == normalized)) {
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
      city: city.trim(),
      createdAt: DateTime.now(),
    );
    _pendingAccount = account;
    _pendingLogin = null;
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
    if (match == null) {
      throw AuthException('Нет такого логина');
    }
    if (hashPassword(password, match.salt) != match.passwordHash) {
      throw AuthException('Неверный пароль');
    }
    _pendingLogin = match;
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
    await _store.setSession(pending.id);
    _pendingLogin = null;
    await reload();
    await AppPermissions.requestAll();
  }

  Future<void> logout() async {
    await _store.setSession(null);
    _pendingAccount = null;
    _pendingLogin = null;
    state = state.copyWith(clearSession: true, ready: true);
  }

  Future<void> updateProfile({String? name, String? city}) async {
    final profile = state.profile;
    if (profile == null) return;
    final next = profile.copyWith(name: name, city: city);
    state = state.copyWith(
      profile: next,
      achievements: unlockedAchievements(
        garage: state.garage,
        city: next.city,
        already: state.achievements,
      ),
    );
    await _persist();
  }

  Future<void> saveApiKey(String key) async {
    state = state.copyWith(apiKey: key.trim());
    await _persist();
  }

  Future<IdentifiedSpot> identifyBytes(Uint8List bytes) async {
    final hash = photoHashOf(bytes);
    if (state.photoHashes.contains(hash)) {
      throw DuplicatePhotoException();
    }
    final raw = await ref.read(visionServiceProvider).identify(
          photoBytes: bytes,
          apiKey: state.apiKey,
          garage: state.garage,
          huntMatch: false,
        );
    if (raw.spec != null && hunt.matchesSpot(raw) && !huntDone) {
      return buildIdentifiedSpot(
        extraction: raw.extraction,
        spec: raw.spec,
        photoBytes: raw.photoBytes,
        photoHash: raw.photoHash,
        photoHints: raw.photoHints,
        garage: state.garage,
        fromAi: raw.fromAi,
        needsCatalogPick: false,
        huntMatch: true,
      );
    }
    return raw;
  }

  Future<IdentifiedSpot> identify(XFile file) async {
    return identifyBytes(Uint8List.fromList(await file.readAsBytes()));
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
    final city = (geo?.city.isNotEmpty == true) ? geo!.city : profile.city;
    final spec = spot.spec!;
    final extraction = spot.extraction;
    var resolved = spot;
    if (!spot.breakdown.duplicate && hunt.matchesSpot(spot) && !huntDone) {
      resolved = buildIdentifiedSpot(
        extraction: extraction,
        spec: spec,
        photoBytes: spot.photoBytes,
        photoHash: spot.photoHash,
        photoHints: spot.photoHints,
        garage: state.garage,
        fromAi: spot.fromAi,
        needsCatalogPick: false,
        huntMatch: true,
      );
    }
    final car = GarageCar(
      id: _uuid.v4(),
      photoId: photoId,
      spottedAt: DateTime.now(),
      city: city,
      lat: geo?.lat,
      lng: geo?.lng,
      make: spec.make,
      model: spec.model,
      generation: spec.generation,
      yearFrom: spec.yearFrom,
      yearTo: spec.yearTo,
      color: extraction.color,
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
    );
    final garage = [car, ...state.garage];
    var huntOn = state.huntCompletedOn;
    if (!huntDone && hunt.matches(car)) {
      huntOn = huntDateKey(DateTime.now());
    }
    final nextProfile = profile.copyWith(
      xp: profile.xp + resolved.xp,
      city: city.isEmpty ? profile.city : city,
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
    return after.difference(before).toList();
  }

  DuelRecord duelWith(List<GarageCar> lineup) {
    final left = duelCooldownLeft(state.lastDuelAt);
    if (left != null) {
      throw StateError('Подожди ${left.inMinutes + 1} мин до следующей дуэли');
    }
    if (lineup.length != 3) {
      throw StateError('Выбери ровно 3 машины');
    }
    final record = runDuel(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      user: statsFor(lineup),
      rival: ghostLineup(DateTime.now()),
      rivalId: 'ghost',
      rivalName: 'Тренировка',
    );
    final xp = duelXp(record);
    final profile = state.profile;
    state = state.copyWith(
      duels: [record, ...state.duels],
      lastDuelAt: DateTime.now(),
      profile: profile?.copyWith(xp: (profile.xp) + xp),
    );
    _persist();
    return record;
  }

  Future<Uint8List?> photo(String id) => _store.loadPhoto(id);
}
