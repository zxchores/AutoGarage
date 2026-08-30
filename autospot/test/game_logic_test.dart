import 'package:autospot/data/vision_service.dart';
import 'package:autospot/domain/catalog.dart';
import 'package:autospot/domain/game_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('XP grows with rarity and rare tuning', () {
    const tuning = TuningFlags(bodykit: true, vinyl: true);
    final common = xpForSpot(
      rarity: Rarity.common,
      tuning: const TuningFlags(),
      photoQuality: PhotoQuality.average,
      confidence: Confidence.high,
      duplicateModel: false,
    );
    final legendary = xpForSpot(
      rarity: Rarity.legendary,
      tuning: tuning,
      photoQuality: PhotoQuality.excellent,
      confidence: Confidence.high,
      duplicateModel: false,
    );
    expect(legendary, greaterThan(common));
    expect(legendary, lessThanOrEqualTo(400));
  });

  test('duplicate model and low confidence reduce XP', () {
    final full = xpForSpot(
      rarity: Rarity.epic,
      tuning: const TuningFlags(bodykit: true),
      photoQuality: PhotoQuality.good,
      confidence: Confidence.high,
      duplicateModel: false,
    );
    final reduced = xpForSpot(
      rarity: Rarity.epic,
      tuning: const TuningFlags(bodykit: true),
      photoQuality: PhotoQuality.good,
      confidence: Confidence.low,
      duplicateModel: true,
    );
    expect(reduced, lessThan(full));
    expect(reduced, greaterThanOrEqualTo(1));
  });

  test('catalog matches aliases', () {
    expect(matchCatalog('BMW', 'M3')?.id, 'bmw_m3');
    expect(matchCatalog('VW', 'Polo')?.make, 'Volkswagen');
    expect(matchCatalog('Mercedes', 'C-Class')?.id, 'mercedes_c');
  });

  test('vision JSON parser reads tuning flags', () {
    const raw = '''
    {
      "is_car": true,
      "make": "Audi",
      "model": "RS6 Avant",
      "generation": "C8",
      "year_from": 2021,
      "year_to": 2024,
      "body_type": "wagon",
      "color": "black",
      "confidence": "high",
      "condition": "excellent",
      "tuning": {
        "bodykit": true,
        "wheels": true,
        "spoiler": false,
        "vinyl": false,
        "exhaust": true,
        "lowered": true,
        "details": ["RS exhaust"]
      },
      "photo_quality": "good",
      "visible_license_plate": false,
      "notes": "ok"
    }
    ''';
    final parsed = parseVisionJson(raw);
    expect(parsed.make, 'Audi');
    expect(parsed.tuning.bodykit, isTrue);
    expect(parsed.tuning.count, 4);
    expect(parsed.confidence, Confidence.high);
  });

  test('duel awards a point per winning metric', () {
    const user = GarageStats(
      value: 10,
      horsepower: 500,
      bodykits: 2,
      rarest: Rarity.epic,
      count: 3,
    );
    const rival = Rival(
      id: 'r1',
      name: 'Kai',
      city: 'Москва',
      xp: 100,
      garageValue: 5,
      totalHp: 100,
      bodykits: 0,
      rarest: Rarity.common,
      carCount: 2,
    );
    final duel = runDuel(
      id: 'd1',
      createdAt: DateTime(2026, 1, 1),
      user: user,
      rival: rival,
    );
    expect(duel.won, isTrue);
    expect(duel.userPoints, 4);
    expect(duel.rivalPoints, 0);
  });

  test('achievements unlock german trio and first spot', () {
    final garage = [
      _car('BMW', '3 Series'),
      _car('Audi', 'A4'),
      _car('Mercedes-Benz', 'C-Class'),
    ];
    final ids = unlockedAchievements(garage: garage, city: 'Москва');
    expect(ids, containsAll(['first_spot', 'german_trio', 'city_walker']));
  });
}

GarageCar _car(String make, String model) {
  return GarageCar(
    id: make,
    photoId: 'p',
    spottedAt: DateTime(2026, 1, 1, 12),
    city: 'Москва',
    make: make,
    model: model,
    generation: '',
    yearFrom: 2020,
    yearTo: 2024,
    color: 'чёрный',
    bodyType: 'седан',
    rarity: Rarity.rare,
    priceRub: 400000,
    horsepower: 250,
    zeroToHundred: 6,
    drivetrain: 'RWD',
    condition: CarCondition.good,
    tuning: const TuningFlags(),
    photoQuality: PhotoQuality.good,
    confidence: Confidence.high,
    xpEarned: 40,
  );
}
