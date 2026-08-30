import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../data/local_store.dart';
import '../data/location_service.dart';
import '../data/vision_service.dart';
import '../domain/game_logic.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());
final visionServiceProvider = Provider<VisionService>((ref) => VisionService());
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final appProvider =
    NotifierProvider<AppController, AppSnapshot>(AppController.new);

class AppController extends Notifier<AppSnapshot> {
  static const _uuid = Uuid();

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

  Future<void> completeOnboarding(String name, String city) async {
    final profile = UserProfile(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Споттер' : name.trim(),
      city: city.trim(),
      xp: 0,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      profile: profile,
      achievements: unlockedAchievements(
        garage: state.garage,
        city: profile.city,
        already: state.achievements,
      ),
    );
    await _persist();
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

  Future<IdentifiedSpot> identify(XFile file) async {
    final bytes = await file.readAsBytes();
    return ref.read(visionServiceProvider).identify(
          photoBytes: Uint8List.fromList(bytes),
          apiKey: state.apiKey,
          garage: state.garage,
        );
  }

  Future<GeoFix?> locate() => ref.read(locationServiceProvider).current();

  Future<List<String>> commitSpot(IdentifiedSpot spot, GeoFix? geo) async {
    final photoId = await _store.savePhoto(Uint8List.fromList(spot.photoBytes));
    final profile = state.profile;
    if (profile == null) {
      throw StateError('Нет профиля');
    }
    final city = (geo?.city.isNotEmpty == true) ? geo!.city : profile.city;
    final spec = spot.spec;
    final extraction = spot.extraction;
    final car = GarageCar(
      id: _uuid.v4(),
      photoId: photoId,
      spottedAt: DateTime.now(),
      city: city,
      lat: geo?.lat,
      lng: geo?.lng,
      make: spot.make,
      model: spot.model,
      generation: spec?.generation ?? extraction.generation,
      yearFrom: spec?.yearFrom ?? extraction.yearFrom,
      yearTo: spec?.yearTo ?? extraction.yearTo,
      color: extraction.color,
      bodyType: spec?.bodyType ?? extraction.bodyType,
      rarity: spot.rarity,
      priceRub: spot.priceRub,
      horsepower: spot.horsepower,
      zeroToHundred: spot.zeroToHundred,
      drivetrain: spot.drivetrain,
      condition: extraction.condition,
      tuning: extraction.tuning,
      photoQuality: extraction.photoQuality,
      confidence: extraction.confidence,
      xpEarned: spot.xp,
      catalogId: spec?.id,
      fromAi: spot.fromAi,
    );
    final garage = [car, ...state.garage];
    final nextProfile = profile.copyWith(
      xp: profile.xp + spot.xp,
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
      clearError: true,
    );
    await _persist();
    return after.difference(before).toList();
  }

  DuelRecord duel(Rival rival) {
    final record = runDuel(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      user: statsFor(state.garage),
      rival: rival,
    );
    state = state.copyWith(duels: [record, ...state.duels]);
    _persist();
    return record;
  }

  Future<Uint8List?> photo(String id) => _store.loadPhoto(id);
}
