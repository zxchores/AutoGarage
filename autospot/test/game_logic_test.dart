import 'dart:typed_data';

import 'package:autospot/core/city.dart';
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
    expect(matchCatalog('bwm', 'M3')?.id, 'bmw_m3');
    expect(matchCatalog('mersedes', 'C-Class')?.id, 'mercedes_c');
    expect(matchCatalog('volcwagen', 'Polo')?.make, 'Volkswagen');
    expect(matchCatalog('hyndai', 'Solaris')?.id, 'hyundai_solaris');
    expect(matchCatalog('шкода', 'Octavia')?.id, 'skoda_octavia');
    expect(matchCatalog('gelly', 'Coolray')?.make, 'Geely');
    expect(matchCatalog('cadilac', 'XT5')?.make, 'Cadillac');
    expect(matchCatalog('mitshubishi', 'Outlander')?.id, 'mitsubishi_outlander');
    expect(matchCatalog('BMW', '320i')?.id, 'bmw_3');
    expect(matchCatalog('BMW', '3 Series')?.id, 'bmw_3');
    expect(matchCatalog('BMW', 'X5 M')?.model, contains('X5 M'));
    expect(matchCatalog('BMW', 'X5')?.id, 'bmw_x5');
    expect(matchCatalog('Mercedes', 'C200')?.id, 'mercedes_c');
    expect(matchCatalog('VW', 'Golf GTI')?.id, 'vw_golf_gti');
    expect(matchCatalog('VW', 'Golf')?.id, 'vw_golf');
    expect(matchCatalog('Toyota', 'Land Cruiser Prado')?.model, contains('Prado'));
    expect(matchCatalog('Toyota', 'Land Cruiser')?.model, 'Land Cruiser');
    expect(matchCatalog('', 'Toyota Camry')?.model, 'Camry');
    expect(matchCatalog('Lada', 'Vesta SW Cross')?.id, 'lada_vestasw_cross');
  });

  test('street catalog covers requested brands', () {
    final makes = carCatalog.map((c) => c.make.toLowerCase()).toSet();
    for (final brand in [
      'audi',
      'toyota',
      'nissan',
      'honda',
      'bmw',
      'tesla',
      'mercedes',
      'hyundai',
      'skoda',
      'volkswagen',
      'opel',
      'porsche',
      'mazda',
      'subaru',
      'mitsubishi',
      'lexus',
      'chery',
      'geely',
      'haval',
      'exeed',
      'changan',
      'tank',
      'ford',
      'chevrolet',
      'cadillac',
      'jeep',
      'ram',
      'kia',
      'genesis',
      'lada',
      'byd',
      'nio',
      'xpeng',
      'xiaomi',
      'rivian',
      'lucid',
      'suzuki',
      'mg',
      'dacia',
      'seat',
      'polestar',
    ]) {
      expect(
        makes.any((m) => m.contains(brand)),
        isTrue,
        reason: 'missing $brand',
      );
    }
    expect(carCatalog.length, greaterThan(1200));
    expect(carCatalog.map((c) => c.id).toSet().length, carCatalog.length);
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

  test('space stream keeps the last model answer', () {
    const raw = '''
event: generating
data: [""]

event: generating
data: ["{\\"is_car\\":true,\\"make\\":\\"BMW\\",\\"model\\":\\"3 Series\\"}"]

event: complete
data: ["{\\"is_car\\":true,\\"make\\":\\"BMW\\",\\"model\\":\\"3 Series\\"}"]
''';
    expect(parseSpaceStream(raw), contains('BMW'));
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

  test('color and generation make a separate garage card', () {
    final black = _car('BMW', 'X5', color: 'чёрный', generation: 'G05', catalogId: 'bmw_x5');
    final white = buildIdentifiedSpot(
      extraction: const VisionExtraction(
        isCar: true,
        make: 'BMW',
        model: 'X5',
        generation: 'G05',
        yearFrom: 2019,
        yearTo: 2024,
        color: 'white',
        bodyType: 'SUV',
        confidence: Confidence.high,
        condition: CarCondition.good,
        tuning: TuningFlags(),
        photoQuality: PhotoQuality.good,
      ),
      spec: matchCatalog('BMW', 'X5'),
      photoBytes: const [],
      photoHash: 'h1',
      photoHints: const [],
      garage: [black],
      fromAi: true,
      needsCatalogPick: false,
      huntMatch: false,
    );
    expect(white.duplicateModel, isFalse);
    expect(white.firstCatch, isTrue);
    final sameBlack = buildIdentifiedSpot(
      extraction: const VisionExtraction(
        isCar: true,
        make: 'BMW',
        model: 'X5',
        generation: 'G05',
        yearFrom: 2019,
        yearTo: 2024,
        color: 'black',
        bodyType: 'SUV',
        confidence: Confidence.high,
        condition: CarCondition.good,
        tuning: TuningFlags(),
        photoQuality: PhotoQuality.good,
      ),
      spec: matchCatalog('BMW', 'X5'),
      photoBytes: const [],
      photoHash: 'h2',
      photoHints: const [],
      garage: [black],
      fromAi: true,
      needsCatalogPick: false,
      huntMatch: false,
    );
    expect(sameBlack.duplicateModel, isTrue);
  });

  test('daily streak grows after yesterday and resets otherwise', () {
    expect(
      streakAfterSpot(lastSpotDay: '2026-08-29', streak: 3, now: DateTime(2026, 8, 30)),
      4,
    );
    expect(
      streakAfterSpot(lastSpotDay: '2026-08-28', streak: 3, now: DateTime(2026, 8, 30)),
      1,
    );
    expect(
      streakAfterSpot(lastSpotDay: '2026-08-30', streak: 5, now: DateTime(2026, 8, 30)),
      5,
    );
    final xp = xpBreakdown(
      rarity: Rarity.common,
      tuning: const TuningFlags(),
      photoQuality: PhotoQuality.average,
      duplicateModel: false,
      huntMatch: false,
      streakDays: 5,
    );
    expect(xp.streak, 10);
    expect(xp.lines.any((e) => e.$1.contains('Серия')), isTrue);
  });

  test('weekend hunt and extra series exist', () {
    final saturday = huntFor(DateTime(2026, 8, 29));
    expect(saturday.id, startsWith('weekend_'));
    expect(carSeries.any((s) => s.id == 'bmw_m'), isTrue);
    expect(carSeries.any((s) => s.id == 'tiggo'), isTrue);
    expect(carSeries.any((s) => s.id == 'vesta'), isTrue);
    final vesta = carSeries.firstWhere((s) => s.id == 'vesta');
    expect(
      vesta.progress([
        _car('Lada', 'Vesta'),
        _car('Lada', 'Vesta SW'),
        _car('Lada', 'Vesta SW Cross'),
      ]),
      3,
    );
  });

  test('pipe vision reply is parsed', () {
    final parsed = parseVisionReply('BMW|3 Series|G20|black');
    expect(parsed.isCar, isTrue);
    expect(parsed.make.toLowerCase(), contains('bmw'));
    expect(parsed.model.toLowerCase(), contains('3'));
  });

  test('vision prompt covers every car viewpoint', () {
    expect(visionPrompt.toLowerCase(), contains('360'));
    expect(visionPrompt.toLowerCase(), contains('front'));
    expect(visionPrompt.toLowerCase(), contains('left'));
    expect(visionPrompt.toLowerCase(), contains('right'));
    expect(visionPrompt.toLowerCase(), contains('overhead'));
    expect(visionPrompt.toLowerCase(), contains('do not assume a rear'));
  });

  test('vision json keeps viewpoint from any angle', () {
    const raw = '''
    {"is_car": true, "make": "Toyota", "model": "Camry", "generation": "XV70",
     "year_from": 2018, "year_to": 2024, "body_type": "sedan", "color": "white",
     "view": "diagonal", "confidence": "high", "condition": "good",
     "tuning": {}, "photo_quality": "good"}
    ''';
    final parsed = parseVisionJson(raw);
    expect(parsed.make, 'Toyota');
    expect(parsed.model, 'Camry');
    expect(parsed.view, 'three_quarter');
    expect(normalizeCarView('overhead'), 'top');
    expect(normalizeCarView('back'), 'rear');
    expect(normalizeCarView('left'), 'left');
  });

  test('focus crop keeps almost the full frame', () {
    final image = img.Image(width: 800, height: 600);
    img.fill(image, color: img.ColorRgb8(40, 40, 40));
    final cropped = focusCar(image);
    expect(cropped.width, greaterThanOrEqualTo(760));
    expect(cropped.height, greaterThanOrEqualTo(560));
  });

  test('city names collapse case and spelling variants', () {
    expect(cityKey('красноярск'), cityKey('Красноярск'));
    expect(cityKey('КРАСНОЯРСК'), cityKey('Krasnoyarsk'));
    expect(cityKey('г. Красноярск'), cityKey('krasnoiarsk'));
    expect(cityLabel('красноярск'), 'Красноярск');
    expect(cityLabel('KRASNOYARSK'), 'Красноярск');
    expect(sameCity('мск', 'Москва'), isTrue);
    expect(sameCity('SPB', 'Питер'), isTrue);
    expect(sameCity('екб', 'Екатеринбург'), isTrue);
    expect(cityLabel('москва'), 'Москва');
    expect(cityLabel('санкт-петербург'), 'Санкт-Петербург');
    expect(sameCity('Красноярск', 'Новосибирск'), isFalse);
  });
}

GarageCar _car(
  String make,
  String model, {
  String color = 'чёрный',
  String generation = '',
  String? catalogId,
}) {
  return GarageCar(
    id: '$make-$model-$color-$generation',
    photoId: 'p',
    spottedAt: DateTime(2026, 1, 1, 12),
    city: 'Москва',
    make: make,
    model: model,
    generation: generation,
    yearFrom: 2020,
    yearTo: 2024,
    color: color,
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
    catalogId: catalogId,
  );
}
