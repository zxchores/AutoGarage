import 'catalog.dart';
import 'models.dart';

export 'models.dart';

class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.title,
    required this.minXp,
    required this.nextXp,
  });

  final int level;
  final String title;
  final int minXp;
  final int? nextXp;

  double progress(int xp) {
    final next = nextXp;
    if (next == null) return 1;
    final span = next - minXp;
    if (span <= 0) return 1;
    return ((xp - minXp) / span).clamp(0.0, 1.0);
  }
}

const _levels = <(int, String)>[
  (0, 'Споттер-любитель'),
  (200, 'Уличный наблюдатель'),
  (600, 'Авто-охотник'),
  (1500, 'Городской охотник'),
  (3500, 'Мастер споттинга'),
  (7000, 'Легенда улиц'),
];

LevelInfo levelFor(int xp) {
  var index = 0;
  for (var i = 0; i < _levels.length; i++) {
    if (xp >= _levels[i].$1) index = i;
  }
  final next = index + 1 < _levels.length ? _levels[index + 1].$1 : null;
  return LevelInfo(
    level: index + 1,
    title: _levels[index].$2,
    minXp: _levels[index].$1,
    nextXp: next,
  );
}

int xpForSpot({
  required Rarity rarity,
  required TuningFlags tuning,
  required PhotoQuality photoQuality,
  required Confidence confidence,
  required bool duplicateModel,
}) {
  var xp = switch (rarity) {
    Rarity.common => 15,
    Rarity.rare => 40,
    Rarity.epic => 90,
    Rarity.legendary => 200,
  };
  if (tuning.isRareTuning) xp += 25;
  if (tuning.count >= 3) xp += 10;
  xp += switch (photoQuality) {
    PhotoQuality.poor => -5,
    PhotoQuality.average => 0,
    PhotoQuality.good => 10,
    PhotoQuality.excellent => 18,
  };
  if (confidence == Confidence.low) {
    xp = (xp * 0.5).round();
  }
  if (duplicateModel) {
    xp = (xp * 0.3).round();
  }
  return xp.clamp(1, 400);
}

Set<String> unlockedAchievements({
  required List<GarageCar> garage,
  required String city,
  Set<String> already = const {},
}) {
  final next = {...already};
  if (garage.isNotEmpty) next.add('first_spot');
  if (garage.length >= 10) next.add('ten_spots');
  if (city.trim().isNotEmpty) next.add('city_walker');

  final makes = garage.map((c) => c.make.toLowerCase()).toSet();
  bool hasMake(String part) => makes.any((m) => m.contains(part));

  if (hasMake('bmw') && hasMake('audi') && (hasMake('mercedes') || hasMake('amg'))) {
    next.add('german_trio');
  }
  if (hasMake('toyota') && hasMake('nissan') && hasMake('honda')) {
    next.add('japan_pack');
  }
  if (garage.where((c) => c.tuning.bodykit).length >= 5) {
    next.add('king_of_tuning');
  }
  if (garage.any((c) => c.rarity == Rarity.legendary)) {
    next.add('legendary_catch');
  }
  if (garage.any((c) => c.spottedAt.hour <= 4)) {
    next.add('night_spotter');
  }
  final value = garage.fold<int>(0, (s, c) => s + c.priceRub);
  if (value >= 1000000) next.add('millionaire');
  if (hasMake('ferrari') || hasMake('lamborghini') || hasMake('pagani')) {
    next.add('italian_job');
  }
  return next;
}

class GarageStats {
  const GarageStats({
    required this.value,
    required this.horsepower,
    required this.bodykits,
    required this.rarest,
    required this.count,
  });

  final int value;
  final int horsepower;
  final int bodykits;
  final Rarity rarest;
  final int count;
}

GarageStats statsFor(List<GarageCar> garage) {
  if (garage.isEmpty) {
    return const GarageStats(
      value: 0,
      horsepower: 0,
      bodykits: 0,
      rarest: Rarity.common,
      count: 0,
    );
  }
  var rarest = Rarity.common;
  for (final car in garage) {
    if (car.rarity.rank > rarest.rank) rarest = car.rarity;
  }
  return GarageStats(
    value: garage.fold(0, (s, c) => s + c.priceRub),
    horsepower: garage.fold(0, (s, c) => s + c.horsepower),
    bodykits: garage.where((c) => c.tuning.bodykit).length,
    rarest: rarest,
    count: garage.length,
  );
}

DuelRecord runDuel({
  required String id,
  required DateTime createdAt,
  required GarageStats user,
  required Rival rival,
}) {
  var userPts = 0;
  var rivalPts = 0;
  final breakdown = <String, String>{};

  void compare(String key, num a, num b, String aLabel, String bLabel) {
    if (a > b) {
      userPts++;
      breakdown[key] = 'win|$aLabel|$bLabel';
    } else if (b > a) {
      rivalPts++;
      breakdown[key] = 'loss|$aLabel|$bLabel';
    } else {
      breakdown[key] = 'draw|$aLabel|$bLabel';
    }
  }

  compare(
    'rarest',
    user.rarest.rank,
    rival.rarest.rank,
    user.rarest.ru,
    rival.rarest.ru,
  );
  compare('value', user.value, rival.garageValue, '${user.value}', '${rival.garageValue}');
  compare('hp', user.horsepower, rival.totalHp, '${user.horsepower}', '${rival.totalHp}');
  compare('kits', user.bodykits, rival.bodykits, '${user.bodykits}', '${rival.bodykits}');

  return DuelRecord(
    id: id,
    createdAt: createdAt,
    rivalId: rival.id,
    rivalName: rival.name,
    userPoints: userPts,
    rivalPoints: rivalPts,
    breakdown: breakdown,
  );
}

List<Rival> rivalsForCity(String city, {int userXp = 0}) {
  final seed = city.toLowerCase().hashCode.abs();
  const names = [
    'Nox',
    'Raven',
    'Кай',
    'Mira',
    'Volk',
    'Алекс',
    'DriftKid',
    'Luna',
    'Тихий',
    'GTR_Ivan',
    'Sofia',
    'NightOwl',
  ];
  final list = <Rival>[];
  for (var i = 0; i < 8; i++) {
    final localSeed = seed + i * 97;
    final rarity = Rarity.values[localSeed % 4];
    list.add(
      Rival(
        id: 'rival_$city$i',
        name: names[(seed + i) % names.length],
        city: city.isEmpty ? 'Неизвестный город' : city,
        xp: 80 + (localSeed % 4200) + (userXp * (i + 1) ~/ 14),
        garageValue: 800000 + (localSeed % 25000000),
        totalHp: 400 + (localSeed % 4200),
        bodykits: localSeed % 9,
        rarest: rarity,
        carCount: 3 + localSeed % 18,
      ),
    );
  }
  list.sort((a, b) => b.xp.compareTo(a.xp));
  return list;
}

CarSpec fallbackSpec(VisionExtraction extraction) {
  return CarSpec(
    id: 'custom',
    make: extraction.make.isEmpty ? 'Unknown' : extraction.make,
    model: extraction.model.isEmpty ? 'Car' : extraction.model,
    generation: extraction.generation,
    yearFrom: extraction.yearFrom,
    yearTo: extraction.yearTo,
    bodyType: extraction.bodyType,
    horsepower: 150,
    zeroToHundred: 9.5,
    drivetrain: 'FWD',
    priceRub: 1800000,
    rarity: Rarity.common,
  );
}

IdentifiedSpot buildSpot({
  required VisionExtraction extraction,
  required List<int> photoBytes,
  required List<GarageCar> garage,
  required bool fromAi,
}) {
  final spec = matchCatalog(extraction.make, extraction.model);
  final resolved = spec ?? fallbackSpec(extraction);
  final rarity = spec?.rarity ?? Rarity.common;
  final duplicate = garage.any(
    (c) =>
        c.make.toLowerCase() == resolved.make.toLowerCase() &&
        c.model.toLowerCase() == resolved.model.toLowerCase(),
  );
  final xp = xpForSpot(
    rarity: rarity,
    tuning: extraction.tuning,
    photoQuality: extraction.photoQuality,
    confidence: extraction.confidence,
    duplicateModel: duplicate,
  );
  return IdentifiedSpot(
    extraction: extraction,
    spec: spec,
    rarity: rarity,
    priceRub: spec?.priceRub ?? resolved.priceRub,
    horsepower: spec?.horsepower ?? resolved.horsepower,
    zeroToHundred: spec?.zeroToHundred ?? resolved.zeroToHundred,
    drivetrain: spec?.drivetrain ?? resolved.drivetrain,
    xp: xp,
    duplicateModel: duplicate,
    fromAi: fromAi,
    photoBytes: photoBytes,
  );
}
