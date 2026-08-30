import 'models.dart';

class CarSeries {
  const CarSeries({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.matches,
  });

  final String id;
  final String title;
  final String description;
  final int target;
  final bool Function(GarageCar car) matches;

  int progress(List<GarageCar> garage) {
    if (id == 'tuners') {
      return garage.where(matches).length.clamp(0, target);
    }
    final seen = <String>{};
    for (final car in garage) {
      if (!matches(car)) continue;
      if (id == 'german_trio' || id == 'japan_pack') {
        seen.add(car.make.toLowerCase());
      } else {
        seen.add('${car.make}|${car.model}'.toLowerCase());
      }
    }
    return seen.length.clamp(0, target);
  }
}

final carSeries = <CarSeries>[
  CarSeries(
    id: 'german_trio',
    title: 'Немецкая тройка',
    description: 'BMW, Audi и Mercedes',
    target: 3,
    matches: (c) {
      final m = c.make.toLowerCase();
      return m.contains('bmw') || m.contains('audi') || m.contains('mercedes') || m.contains('amg');
    },
  ),
  CarSeries(
    id: 'japan_pack',
    title: 'JDM',
    description: 'Toyota, Nissan и Honda',
    target: 3,
    matches: (c) {
      final m = c.make.toLowerCase();
      return m.contains('toyota') || m.contains('nissan') || m.contains('honda');
    },
  ),
  CarSeries(
    id: 'wagons',
    title: 'Универсалы',
    description: 'Octavia, RS6 и другие wagon',
    target: 2,
    matches: (c) =>
        c.bodyType.toLowerCase().contains('универсал') ||
        c.model.toLowerCase().contains('rs6') ||
        c.model.toLowerCase().contains('octavia'),
  ),
  CarSeries(
    id: 'italian',
    title: 'Итальянцы',
    description: 'Ferrari, Lamborghini, Pagani',
    target: 1,
    matches: (c) {
      final m = c.make.toLowerCase();
      return m.contains('ferrari') || m.contains('lamborghini') || m.contains('pagani');
    },
  ),
  CarSeries(
    id: 'tuners',
    title: 'Обвесы',
    description: 'Машины с обвесом',
    target: 5,
    matches: (c) => c.tuning.bodykit,
  ),
];

class DailyHunt {
  DailyHunt({
    required this.id,
    required this.title,
    required this.description,
    required this.bonusXp,
    required this.matches,
  });

  final String id;
  final String title;
  final String description;
  final int bonusXp;
  final bool Function(GarageCar car) matches;

  bool matchesSpot(IdentifiedSpot spot) {
    if (spot.spec == null) return false;
    return matches(
      GarageCar(
        id: 'tmp',
        photoId: '',
        spottedAt: DateTime.now(),
        city: '',
        make: spot.make,
        model: spot.model,
        generation: spot.spec!.generation,
        yearFrom: spot.spec!.yearFrom,
        yearTo: spot.spec!.yearTo,
        color: spot.extraction.color,
        bodyType: spot.spec!.bodyType,
        rarity: spot.rarity,
        priceRub: spot.priceRub,
        horsepower: spot.horsepower,
        zeroToHundred: spot.zeroToHundred,
        drivetrain: spot.drivetrain,
        condition: spot.extraction.condition,
        tuning: spot.extraction.tuning,
        photoQuality: spot.extraction.photoQuality,
        confidence: spot.extraction.confidence,
        xpEarned: 0,
        catalogId: spot.spec!.id,
      ),
    );
  }
}

final _hunts = <DailyHunt>[
  DailyHunt(
    id: 'bmw',
    title: 'Охота дня: BMW',
    description: 'Любая BMW',
    bonusXp: 25,
    matches: (c) => c.make.toLowerCase().contains('bmw'),
  ),
  DailyHunt(
    id: 'kit',
    title: 'Охота дня: обвес',
    description: 'Машина с обвесом',
    bonusXp: 25,
    matches: (c) => c.tuning.bodykit,
  ),
  DailyHunt(
    id: 'jp',
    title: 'Охота дня: Япония',
    description: 'Toyota, Nissan или Honda',
    bonusXp: 25,
    matches: (c) {
      final m = c.make.toLowerCase();
      return m.contains('toyota') || m.contains('nissan') || m.contains('honda');
    },
  ),
  DailyHunt(
    id: 'wagon',
    title: 'Охота дня: универсал',
    description: 'Универсал или RS6 / Octavia',
    bonusXp: 25,
    matches: (c) =>
        c.bodyType.toLowerCase().contains('универсал') ||
        c.model.toLowerCase().contains('rs6') ||
        c.model.toLowerCase().contains('octavia'),
  ),
  DailyHunt(
    id: 'rare',
    title: 'Охота дня: Rare+',
    description: 'Rare, Epic или Legendary',
    bonusXp: 30,
    matches: (c) => c.rarity != Rarity.common,
  ),
];

DailyHunt huntFor(DateTime now) {
  final day = DateTime(now.year, now.month, now.day).difference(DateTime(now.year)).inDays;
  return _hunts[day % _hunts.length];
}

String huntDateKey(DateTime now) {
  final d = DateTime(now.year, now.month, now.day);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
