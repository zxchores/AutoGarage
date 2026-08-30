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

String normalizeColor(String raw) {
  final n = raw.toLowerCase().trim();
  if (n.isEmpty) return '';
  const map = <String, String>{
    'black': 'чёрный',
    'черный': 'чёрный',
    'чёрный': 'чёрный',
    'white': 'белый',
    'белый': 'белый',
    'gray': 'серый',
    'grey': 'серый',
    'серебристый': 'серый',
    'silver': 'серый',
    'серый': 'серый',
    'blue': 'синий',
    'синий': 'синий',
    'голубой': 'синий',
    'red': 'красный',
    'красный': 'красный',
    'green': 'зелёный',
    'зеленый': 'зелёный',
    'зелёный': 'зелёный',
    'yellow': 'жёлтый',
    'желтый': 'жёлтый',
    'жёлтый': 'жёлтый',
    'orange': 'оранжевый',
    'оранжевый': 'оранжевый',
    'brown': 'коричневый',
    'коричневый': 'коричневый',
    'purple': 'фиолетовый',
    'фиолетовый': 'фиолетовый',
    'beige': 'бежевый',
    'бежевый': 'бежевый',
    'gold': 'золотой',
    'золотой': 'золотой',
  };
  if (map.containsKey(n)) return map[n]!;
  for (final e in map.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return n;
}

String variantKey({
  required String? catalogId,
  required String make,
  required String model,
  required String color,
  required String generation,
}) {
  final id = (catalogId ?? '$make|$model').toLowerCase().trim();
  return '$id|${normalizeColor(color)}|${generation.toLowerCase().trim()}';
}

bool sameVariant(GarageCar car, {required String? catalogId, required String make, required String model, required String color, required String generation}) {
  return variantKey(
        catalogId: car.catalogId,
        make: car.make,
        model: car.model,
        color: car.color,
        generation: car.generation,
      ) ==
      variantKey(
        catalogId: catalogId,
        make: make,
        model: model,
        color: color,
        generation: generation,
      );
}

int streakAfterSpot({required String lastSpotDay, required int streak, required DateTime now}) {
  final today = huntDayKey(now);
  if (lastSpotDay == today) return streak < 1 ? 1 : streak;
  final yesterday = huntDayKey(now.subtract(const Duration(days: 1)));
  if (lastSpotDay == yesterday) return streak + 1;
  return 1;
}

int streakBonusXp(int streak) => (streak.clamp(1, 14) * 2);

String huntDayKey(DateTime now) {
  final d = DateTime(now.year, now.month, now.day);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

XpBreakdown xpBreakdown({
  required Rarity rarity,
  required TuningFlags tuning,
  required PhotoQuality photoQuality,
  required bool duplicateModel,
  required bool huntMatch,
  int streakDays = 0,
}) {
  final base = switch (rarity) {
    Rarity.common => 15,
    Rarity.rare => 40,
    Rarity.epic => 90,
    Rarity.legendary => 200,
  };
  var tuningXp = 0;
  if (tuning.isRareTuning) tuningXp += 25;
  if (tuning.count >= 3) tuningXp += 10;
  final photo = switch (photoQuality) {
    PhotoQuality.poor => -5,
    PhotoQuality.average => 0,
    PhotoQuality.good => 10,
    PhotoQuality.excellent => 18,
  };
  final hunt = huntMatch ? 25 : 0;
  final streak = streakDays > 0 ? streakBonusXp(streakDays) : 0;
  var total = base + tuningXp + photo + hunt + streak;
  if (duplicateModel) {
    total = (total * 0.3).round();
  }
  return XpBreakdown(
    base: base,
    tuning: tuningXp,
    photo: photo,
    hunt: hunt,
    duplicate: duplicateModel,
    total: total.clamp(1, 400),
    streak: streak,
  );
}

int xpForSpot({
  required Rarity rarity,
  required TuningFlags tuning,
  required PhotoQuality photoQuality,
  required Confidence confidence,
  required bool duplicateModel,
  bool huntMatch = false,
  int streakDays = 0,
}) {
  return xpBreakdown(
    rarity: rarity,
    tuning: tuning,
    photoQuality: photoQuality,
    duplicateModel: duplicateModel,
    huntMatch: huntMatch,
    streakDays: streakDays,
  ).total;
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

int duelXp(DuelRecord record) {
  if (record.won) return 40;
  if (record.draw) return 15;
  return 5;
}

Duration? duelCooldownLeft(DateTime? last, {DateTime? now}) {
  if (last == null) return null;
  final left = last.add(const Duration(minutes: 3)).difference(now ?? DateTime.now());
  return left.isNegative ? null : left;
}

DuelRecord runDuel({
  required String id,
  required DateTime createdAt,
  required GarageStats user,
  required GarageStats rival,
  required String rivalId,
  required String rivalName,
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

  compare('rarest', user.rarest.rank, rival.rarest.rank, user.rarest.ru, rival.rarest.ru);
  compare('value', user.value, rival.value, '${user.value}', '${rival.value}');
  compare('hp', user.horsepower, rival.horsepower, '${user.horsepower}', '${rival.horsepower}');
  compare('kits', user.bodykits, rival.bodykits, '${user.bodykits}', '${rival.bodykits}');

  return DuelRecord(
    id: id,
    createdAt: createdAt,
    rivalId: rivalId,
    rivalName: rivalName,
    userPoints: userPts,
    rivalPoints: rivalPts,
    breakdown: breakdown,
  );
}

GarageStats ghostLineup(DateTime now) {
  final seed = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  final picks = <CarSpec>[];
  for (var i = 0; i < 3; i++) {
    picks.add(carCatalog[(seed + i * 13) % carCatalog.length]);
  }
  var rarest = Rarity.common;
  for (final car in picks) {
    if (car.rarity.rank > rarest.rank) rarest = car.rarity;
  }
  return GarageStats(
    value: picks.fold(0, (s, c) => s + c.priceRub),
    horsepower: picks.fold(0, (s, c) => s + c.horsepower),
    bodykits: 1,
    rarest: rarest,
    count: 3,
  );
}

IdentifiedSpot buildIdentifiedSpot({
  required VisionExtraction extraction,
  required CarSpec? spec,
  required List<int> photoBytes,
  required String photoHash,
  required List<String> photoHints,
  required List<GarageCar> garage,
  required bool fromAi,
  required bool needsCatalogPick,
  required bool huntMatch,
  int streakDays = 0,
}) {
  final resolved = spec;
  final rarity = resolved?.rarity ?? Rarity.common;
  final duplicate = resolved != null &&
      garage.any(
        (c) => sameVariant(
          c,
          catalogId: resolved.id,
          make: resolved.make,
          model: resolved.model,
          color: extraction.color,
          generation: extraction.generation.isEmpty
              ? resolved.generation
              : extraction.generation,
        ),
      );
  final breakdown = xpBreakdown(
    rarity: rarity,
    tuning: extraction.tuning,
    photoQuality: extraction.photoQuality,
    duplicateModel: duplicate,
    huntMatch: huntMatch && !duplicate,
    streakDays: streakDays,
  );
  return IdentifiedSpot(
    extraction: extraction,
    spec: resolved,
    rarity: rarity,
    priceRub: resolved?.priceRub ?? 0,
    horsepower: resolved?.horsepower ?? 0,
    zeroToHundred: resolved?.zeroToHundred ?? 0,
    drivetrain: resolved?.drivetrain ?? '',
    xp: needsCatalogPick ? 0 : breakdown.total,
    breakdown: breakdown,
    duplicateModel: duplicate,
    firstCatch: resolved != null && !duplicate,
    fromAi: fromAi,
    needsCatalogPick: needsCatalogPick,
    photoBytes: photoBytes,
    photoHash: photoHash,
    photoHints: photoHints,
  );
}

IdentifiedSpot applyCatalogPick({
  required IdentifiedSpot current,
  required CarSpec spec,
  required List<GarageCar> garage,
  required bool huntMatch,
}) {
  final extraction = VisionExtraction(
    isCar: true,
    make: spec.make,
    model: spec.model,
    generation: spec.generation,
    yearFrom: spec.yearFrom,
    yearTo: spec.yearTo,
    color: current.extraction.color,
    bodyType: spec.bodyType,
    confidence: current.extraction.confidence,
    condition: current.extraction.condition,
    tuning: current.extraction.tuning,
    photoQuality: current.extraction.photoQuality,
    notes: current.extraction.notes,
  );
  return buildIdentifiedSpot(
    extraction: extraction,
    spec: spec,
    photoBytes: current.photoBytes,
    photoHash: current.photoHash,
    photoHints: current.photoHints,
    garage: garage,
    fromAi: current.fromAi,
    needsCatalogPick: false,
    huntMatch: huntMatch,
    streakDays: current.breakdown.streak > 0
        ? (current.breakdown.streak ~/ 2).clamp(1, 14)
        : 0,
  );
}

class DuplicatePhotoException implements Exception {
  @override
  String toString() => 'Это фото уже было в гараже';
}

class NoCarFoundException implements Exception {
  @override
  String toString() => 'Не вижу машины рядом. Наведи камеру на авто целиком.';
}

class RecognitionFailedException implements Exception {
  @override
  String toString() =>
      'Вижу авто, но модель не прочитал. Проверь интернет и сними ещё раз.';
}
