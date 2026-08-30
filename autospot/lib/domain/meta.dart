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
        seen.add('${car.make}|${car.model}|${car.color}|${car.generation}'.toLowerCase());
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
  CarSeries(
    id: 'bmw_m',
    title: 'Все BMW M',
    description: 'M2, M3, M4, M5 и остальные M',
    target: 4,
    matches: (c) {
      if (!c.make.toLowerCase().contains('bmw')) return false;
      final m = c.model.toLowerCase();
      return RegExp(r'(^|\s)m\d|m340|m550|x\d m').hasMatch(m) ||
          m.startsWith('m') && m.length <= 6;
    },
  ),
  CarSeries(
    id: 'tiggo',
    title: 'Все Tiggo',
    description: 'Chery Tiggo любых поколений',
    target: 3,
    matches: (c) =>
        c.make.toLowerCase().contains('chery') &&
        c.model.toLowerCase().contains('tiggo'),
  ),
  CarSeries(
    id: 'vesta',
    title: 'Все Vesta',
    description: 'Lada Vesta, SW и Cross',
    target: 3,
    matches: (c) =>
        c.make.toLowerCase().contains('lada') &&
        c.model.toLowerCase().contains('vesta'),
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
        district: '',
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
  DailyHunt(
    id: 'district',
    title: 'Охота района',
    description: 'Спотни машину с геометкой района',
    bonusXp: 25,
    matches: (c) => c.district.trim().isNotEmpty,
  ),
];

final _weekend = <DailyHunt>[
  DailyHunt(
    id: 'weekend_cn',
    title: 'Выходные: китайцы',
    description: 'Chery, Geely, Haval, Changan, Exeed или Tank',
    bonusXp: 40,
    matches: (c) {
      final m = c.make.toLowerCase();
      return m.contains('chery') ||
          m.contains('geely') ||
          m.contains('haval') ||
          m.contains('changan') ||
          m.contains('exeed') ||
          m.contains('tank');
    },
  ),
  DailyHunt(
    id: 'weekend_jdm',
    title: 'Выходные: JDM',
    description: 'Toyota, Nissan, Honda, Mazda или Subaru',
    bonusXp: 40,
    matches: (c) {
      final m = c.make.toLowerCase();
      return m.contains('toyota') ||
          m.contains('nissan') ||
          m.contains('honda') ||
          m.contains('mazda') ||
          m.contains('subaru');
    },
  ),
  DailyHunt(
    id: 'weekend_lada',
    title: 'Выходные: Lada',
    description: 'Любая Lada',
    bonusXp: 40,
    matches: (c) => c.make.toLowerCase().contains('lada'),
  ),
];

DailyHunt huntFor(DateTime now) {
  final day = DateTime(now.year, now.month, now.day).difference(DateTime(now.year)).inDays;
  final weekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  if (weekend) return _weekend[day % _weekend.length];
  return _hunts[day % _hunts.length];
}

String huntDateKey(DateTime now) {
  final d = DateTime(now.year, now.month, now.day);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
