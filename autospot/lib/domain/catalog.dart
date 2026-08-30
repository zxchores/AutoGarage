import 'catalog_cars.dart';
import 'models.dart';

export 'catalog_cars.dart';

const achievements = [
  AchievementDef(
    id: 'first_spot',
    title: 'Первый спот',
    description: 'Поймай первую машину',
    emoji: '🎯',
  ),
  AchievementDef(
    id: 'german_trio',
    title: 'Немецкий триумвират',
    description: 'BMW, Mercedes и Audi в гараже',
    emoji: '🇩🇪',
  ),
  AchievementDef(
    id: 'king_of_tuning',
    title: 'Король тюнинга',
    description: 'Поймай 3 JDM-машины',
    emoji: '🔧',
  ),
  AchievementDef(
    id: 'night_spotter',
    title: 'Ночной охотник',
    description: 'Сделай спот с 22:00 до 05:00',
    emoji: '🌙',
  ),
  AchievementDef(
    id: 'legendary_catch',
    title: 'Легенда',
    description: 'Поймай legendary-кар',
    emoji: '👑',
  ),
  AchievementDef(
    id: 'ten_spots',
    title: 'Коллекционер',
    description: '10 машин в гараже',
    emoji: '📚',
  ),
  AchievementDef(
    id: 'japan_pack',
    title: 'Япония в кармане',
    description: 'Поймай 5 японских машин',
    emoji: '🇯🇵',
  ),
  AchievementDef(
    id: 'millionaire',
    title: 'Миллионер',
    description: 'Собери гараж дороже 50 млн ₽',
    emoji: '💎',
  ),
  AchievementDef(
    id: 'italian_job',
    title: 'Итальянская работа',
    description: 'Поймай 3 итальянские машины',
    emoji: '🇮🇹',
  ),
  AchievementDef(
    id: 'city_walker',
    title: 'Городской охотник',
    description: 'Поймай машины в 3 разных районах',
    emoji: '🗺️',
  ),
];

const _makeAliases = <String, String>{
  'vw': 'volkswagen',
  'volkswagen': 'volkswagen',
  'mercedes': 'mercedes-benz',
  'mercedes-benz': 'mercedes-benz',
  'merc': 'mercedes-benz',
  'amg': 'mercedes-benz',
  'lada': 'lada',
  'vaz': 'lada',
  'ваз': 'lada',
  'bmw': 'bmw',
  'chevy': 'chevrolet',
  'citroen': 'citroën',
  'rr': 'rolls-royce',
  'rolls': 'rolls-royce',
  'rolls royce': 'rolls-royce',
};

String _norm(String value) => value.toLowerCase().trim();

String _canonMake(String value) {
  final n = _norm(value);
  return _makeAliases[n] ?? n;
}

bool _sameMake(CarSpec car, String brand) {
  final want = _canonMake(brand);
  final have = _canonMake(car.make);
  if (want.isEmpty) return true;
  if (have == want || have.contains(want) || want.contains(have)) return true;
  for (final alias in car.aliases) {
    if (_canonMake(alias) == want || alias.toLowerCase().contains(want)) {
      return true;
    }
  }
  return false;
}

bool _sameModel(CarSpec car, String model) {
  final want = _norm(model);
  if (want.isEmpty) return false;
  final have = _norm(car.model);
  if (have == want || have.contains(want) || want.contains(have)) return true;
  final title = _norm(car.title);
  if (title == want || title.contains(want)) return true;
  for (final alias in car.aliases) {
    final a = _norm(alias);
    if (a == want || a.contains(want) || want.contains(a)) return true;
  }
  return false;
}

CarSpec? matchCatalog(String brand, String model) {
  if (brand.trim().isEmpty && model.trim().isEmpty) return null;
  for (final car in carCatalog) {
    if (_sameMake(car, brand) && _sameModel(car, model)) return car;
  }
  for (final car in carCatalog) {
    if (_sameModel(car, model) || _sameModel(car, '$brand $model')) {
      return car;
    }
  }
  return null;
}

Rarity rarityForUnknown(String make, String model) {
  final text = '${make.toLowerCase()} ${model.toLowerCase()}';
  const legendary = [
    'ferrari',
    'lamborghini',
    'pagani',
    'bugatti',
    'mclaren',
    'koenigsegg',
    'rolls',
    'bentley',
  ];
  const epic = ['porsche', 'aston', 'maserati', 'amg', 'gtr', 'huracan', '911'];
  const rare = ['bmw', 'mercedes', 'audi', 'lexus', 'tesla', 'jaguar'];
  if (legendary.any(text.contains)) return Rarity.legendary;
  if (epic.any(text.contains)) return Rarity.epic;
  if (rare.any(text.contains)) return Rarity.rare;
  return Rarity.common;
}

CarSpec fallbackSpec(VisionExtraction extraction) {
  final make = extraction.make.trim();
  final model = extraction.model.trim();
  final slug = '${make}_$model'
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return CarSpec(
    id: slug.isEmpty ? 'unknown_car' : slug,
    make: make.isEmpty ? 'Unknown' : make,
    model: model.isEmpty ? 'Car' : model,
    generation: extraction.generation,
    yearFrom: extraction.yearFrom,
    yearTo: extraction.yearTo,
    bodyType: extraction.bodyType,
    horsepower: 0,
    zeroToHundred: 0,
    drivetrain: '',
    priceRub: 0,
    rarity: rarityForUnknown(make, model),
  );
}
