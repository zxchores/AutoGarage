import 'dart:typed_data';

import 'package:autospot/data/auth.dart';
import 'package:autospot/data/vision_service.dart';
import 'package:autospot/domain/catalog.dart';
import 'package:autospot/domain/game_logic.dart';
import 'package:autospot/domain/meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

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

  test('duplicate model reduces XP, first catch does not', () {
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
      confidence: Confidence.high,
      duplicateModel: true,
    );
    expect(reduced, lessThan(full));
    expect(reduced, greaterThanOrEqualTo(1));
  });

  test('hunt bonus is listed in breakdown', () {
    final xp = xpBreakdown(
      rarity: Rarity.rare,
      tuning: const TuningFlags(),
      photoQuality: PhotoQuality.average,
      duplicateModel: false,
      huntMatch: true,
    );
    expect(xp.hunt, 25);
    expect(xp.lines.any((e) => e.$1.contains('Охота')), isTrue);
  });

  test('catalog matches aliases', () {
    expect(matchCatalog('BMW', 'M3')?.id, 'bmw_m3');
    expect(matchCatalog('VW', 'Polo')?.make, 'Volkswagen');
    expect(matchCatalog('Mercedes', 'C-Class')?.id, 'mercedes_c');
  });

  test('catalog cars have image assets', () {
    expect(carCatalog.first.imageAsset, startsWith('assets/cars/'));
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
  });

  test('duel awards a point per winning metric', () {
    const user = GarageStats(
      value: 10,
      horsepower: 500,
      bodykits: 2,
      rarest: Rarity.epic,
      count: 3,
    );
    const rival = GarageStats(
      value: 5,
      horsepower: 100,
      bodykits: 0,
      rarest: Rarity.common,
      count: 3,
    );
    final duel = runDuel(
      id: 'd1',
      createdAt: DateTime(2026, 1, 1),
      user: user,
      rival: rival,
      rivalId: 'r1',
      rivalName: 'Kai',
    );
    expect(duel.won, isTrue);
    expect(duel.userPoints, 4);
    expect(duelXp(duel), 40);
  });

  test('series progress counts german brands', () {
    final garage = [
      _car('BMW', '3 Series'),
      _car('Audi', 'A4'),
      _car('Mercedes-Benz', 'C-Class'),
    ];
    final german = carSeries.firstWhere((s) => s.id == 'german_trio');
    expect(german.progress(garage), 3);
  });

  test('vision reply parser reads fenced JSON and plain titles', () {
    final fenced = parseVisionReply(
      '```json\n{"is_car":true,"make":"BMW","model":"M3"}\n```',
    );
    expect(fenced.isCar, isTrue);
    expect(fenced.make, 'BMW');
    expect(parseVisionReply('BMW M3').make, 'BMW');
    expect(parseVisionReply('no car in this photo').isCar, isFalse);
  });

  test('vision JSON without a car stays is_car false', () {
    const raw = '''
    {"is_car": false, "make": "", "model": "", "generation": "", "year_from": 0, "year_to": 0,
     "body_type": "", "color": "", "confidence": "low", "condition": "good",
     "tuning": {}, "photo_quality": "poor", "visible_license_plate": false, "notes": ""}
    ''';
    expect(parseVisionJson(raw).isCar, isFalse);
  });

  test('totp secret verifies current code and rejects garbage', () {
    final secret = newTotpSecret();
    final code = totpCode(secret);
    expect(totpVerify(secret, code), isTrue);
    expect(totpVerify(secret, '000000'), isFalse);
  });

  test('solid color photo is not treated as a car', () {
    final image = img.Image(width: 64, height: 64);
    img.fill(image, color: img.ColorRgb8(180, 200, 230));
    final bytes = Uint8List.fromList(img.encodePng(image));
    expect(looksLikeVehicle(bytes), isFalse);
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
