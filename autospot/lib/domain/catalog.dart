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
  'volcwagen': 'volkswagen',
  'wolkswagen': 'volkswagen',
  'фольксваген': 'volkswagen',
  'mercedes': 'mercedes-benz',
  'mercedes-benz': 'mercedes-benz',
  'mercedesbenz': 'mercedes-benz',
  'mercedes-amg': 'mercedes-benz',
  'mercedesamg': 'mercedes-benz',
  'mersedes': 'mercedes-benz',
  'merc': 'mercedes-benz',
  'amg': 'mercedes-benz',
  'мерседес': 'mercedes-benz',
  'lada': 'lada',
  'vaz': 'lada',
  'ваз': 'lada',
  'лада': 'lada',
  'bmw': 'bmw',
  'bwm': 'bmw',
  'бмв': 'bmw',
  'chevy': 'chevrolet',
  'chevrolet': 'chevrolet',
  'шевроле': 'chevrolet',
  'citroen': 'citroen',
  'citroën': 'citroen',
  'ситроен': 'citroen',
  'rr': 'rolls-royce',
  'rolls': 'rolls-royce',
  'rolls royce': 'rolls-royce',
  'rolls-royce': 'rolls-royce',
  'toyota': 'toyota',
  'тойота': 'toyota',
  'nissan': 'nissan',
  'ниссан': 'nissan',
  'honda': 'honda',
  'хонда': 'honda',
  'tesla': 'tesla',
  'тесла': 'tesla',
  'hyundai': 'hyundai',
  'hyndai': 'hyundai',
  'хендай': 'hyundai',
  'хёндай': 'hyundai',
  'skoda': 'skoda',
  'škoda': 'skoda',
  'шкода': 'skoda',
  'шкоду': 'skoda',
  'opel': 'opel',
  'опель': 'opel',
  'porsche': 'porsche',
  'порше': 'porsche',
  'mazda': 'mazda',
  'мазда': 'mazda',
  'subaru': 'subaru',
  'субару': 'subaru',
  'mitsubishi': 'mitsubishi',
  'mitshubishi': 'mitsubishi',
  'mitsubisi': 'mitsubishi',
  'митсубиси': 'mitsubishi',
  'мицубиси': 'mitsubishi',
  'lexus': 'lexus',
  'лексус': 'lexus',
  'chery': 'chery',
  'чери': 'chery',
  'geely': 'geely',
  'gelly': 'geely',
  'джили': 'geely',
  'haval': 'haval',
  'хавейл': 'haval',
  'хавал': 'haval',
  'exeed': 'exeed',
  'эксид': 'exeed',
  'changan': 'changan',
  'чанган': 'changan',
  'tank': 'tank',
  'танк': 'tank',
  'ford': 'ford',
  'форд': 'ford',
  'cadillac': 'cadillac',
  'cadilac': 'cadillac',
  'кадиллак': 'cadillac',
  'jeep': 'jeep',
  'джип': 'jeep',
  'ram': 'ram',
  'рам': 'ram',
  'kia': 'kia',
  'киа': 'kia',
  'genesis': 'genesis',
  'генезис': 'genesis',
  'audi': 'audi',
  'ауди': 'audi',
  'seat': 'seat',
  'сеат': 'seat',
  'cupra': 'cupra',
  'купра': 'cupra',
  'dacia': 'dacia',
  'дачия': 'dacia',
  'ds': 'ds',
  'alpine': 'alpine',
  'альпин': 'alpine',
  'smart': 'smart',
  'смарт': 'smart',
  'polestar': 'polestar',
  'полестар': 'polestar',
  'lotus': 'lotus',
  'лотос': 'lotus',
  'mg': 'mg',
  'мг': 'mg',
  'byd': 'byd',
  'бид': 'byd',
  'nio': 'nio',
  'нио': 'nio',
  'xpeng': 'xpeng',
  'сяопен': 'xpeng',
  'xiaomi': 'xiaomi',
  'сяоми': 'xiaomi',
  'li': 'li auto',
  'li auto': 'li auto',
  'lixiang': 'li auto',
  'лисян': 'li auto',
  'zeekr': 'zeekr',
  'зикр': 'zeekr',
  'lynk': 'lynk & co',
  'lynk & co': 'lynk & co',
  'линк': 'lynk & co',
  'hongqi': 'hongqi',
  'хунци': 'hongqi',
  'wuling': 'wuling',
  'вулинг': 'wuling',
  'rivian': 'rivian',
  'ривиан': 'rivian',
  'lucid': 'lucid',
  'люсид': 'lucid',
  'vinfast': 'vinfast',
  'винфаст': 'vinfast',
  'tata': 'tata',
  'тата': 'tata',
  'mahindra': 'mahindra',
  'махиндра': 'mahindra',
  'suzuki': 'suzuki',
  'сузуки': 'suzuki',
  'daihatsu': 'daihatsu',
  'дайхатсу': 'daihatsu',
  'isuzu': 'isuzu',
  'исузу': 'isuzu',
  'acura': 'acura',
  'акура': 'acura',
  'lincoln': 'lincoln',
  'линкольн': 'lincoln',
  'buick': 'buick',
  'бьюик': 'buick',
  'gmc': 'gmc',
  'джиэмси': 'gmc',
  'chrysler': 'chrysler',
  'крайслер': 'chrysler',
  'lancia': 'lancia',
  'лянча': 'lancia',
  'ineos': 'ineos',
  'aurus': 'aurus',
  'аурус': 'aurus',
  'ora': 'ora',
  'ора': 'ora',
  'aito': 'aito',
  'аито': 'aito',
  'avatr': 'avatr',
  'аватр': 'avatr',
  'leapmotor': 'leapmotor',
  'deepal': 'deepal',
  'aion': 'aion',
  'аион': 'aion',
};

String _norm(String value) => value.toLowerCase().trim();

String _compact(String value) =>
    _norm(value).replaceAll(RegExp(r'[^a-z0-9а-яё]+'), '');

List<String> _tokens(String value) => _norm(value)
    .replaceAll(RegExp(r'[^a-z0-9а-яё]+'), ' ')
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty && t != 'the' && t != 'car')
    .toList();

String _canonMake(String value) {
  final n = _norm(value);
  return _makeAliases[n] ?? n;
}

/// Common engine/trim codes the vision model returns instead of the model name.
const _modelCodes = <String, (String, String)>{
  '320i': ('bmw', '3 Series'),
  '320d': ('bmw', '3 Series'),
  '318i': ('bmw', '3 Series'),
  '318d': ('bmw', '3 Series'),
  '328i': ('bmw', '3 Series'),
  '330i': ('bmw', '3 Series'),
  '330d': ('bmw', '3 Series'),
  '340i': ('bmw', '3 Series'),
  'm340i': ('bmw', 'M340i'),
  '3er': ('bmw', '3 Series'),
  '3series': ('bmw', '3 Series'),
  '530i': ('bmw', '5 Series'),
  '530d': ('bmw', '5 Series'),
  '520d': ('bmw', '5 Series'),
  '540i': ('bmw', '5 Series'),
  '5er': ('bmw', '5 Series'),
  '5series': ('bmw', '5 Series'),
  '730d': ('bmw', '7 Series'),
  '740i': ('bmw', '7 Series'),
  '7series': ('bmw', '7 Series'),
  'x5m': ('bmw', 'X5 M'),
  'x6m': ('bmw', 'X6 M'),
  'x3m': ('bmw', 'X3 M'),
  'm3': ('bmw', 'M3'),
  'm4': ('bmw', 'M4'),
  'm5': ('bmw', 'M5'),
  'm2': ('bmw', 'M2'),
  'm8': ('bmw', 'M8'),
  'c180': ('mercedes-benz', 'C-Class'),
  'c200': ('mercedes-benz', 'C-Class'),
  'c220': ('mercedes-benz', 'C-Class'),
  'c250': ('mercedes-benz', 'C-Class'),
  'c300': ('mercedes-benz', 'C-Class'),
  'cclass': ('mercedes-benz', 'C-Class'),
  'e200': ('mercedes-benz', 'E-Class'),
  'e220': ('mercedes-benz', 'E-Class'),
  'e300': ('mercedes-benz', 'E-Class'),
  'eclass': ('mercedes-benz', 'E-Class'),
  'sclass': ('mercedes-benz', 'S-Class'),
  's500': ('mercedes-benz', 'S-Class'),
  'gclass': ('mercedes-benz', 'G-Class'),
  'g63': ('mercedes-benz', 'G63 AMG'),
  'c63': ('mercedes-benz', 'C63'),
  'e63': ('mercedes-benz', 'E63 AMG'),
  'a200': ('mercedes-benz', 'A-Class'),
  'aclass': ('mercedes-benz', 'A-Class'),
  'a4': ('audi', 'A4'),
  'a6': ('audi', 'A6'),
  'a3': ('audi', 'A3'),
  'q5': ('audi', 'Q5'),
  'q7': ('audi', 'Q7'),
  'q8': ('audi', 'Q8'),
  'rs6': ('audi', 'RS6 Avant'),
  'rs7': ('audi', 'RS7'),
  'rs3': ('audi', 'RS3'),
  'polosedan': ('volkswagen', 'Polo Sedan'),
  'pologti': ('volkswagen', 'Polo GTI'),
  'golfgti': ('volkswagen', 'Golf GTI'),
  'golfr': ('volkswagen', 'Golf R'),
  'tiguan': ('volkswagen', 'Tiguan'),
  'passat': ('volkswagen', 'Passat'),
  'octavia': ('skoda', 'Octavia'),
  'octaviars': ('skoda', 'Octavia RS'),
  'rapid': ('skoda', 'Rapid'),
  'kodiaq': ('skoda', 'Kodiaq'),
  'camry': ('toyota', 'Camry'),
  'rav4': ('toyota', 'RAV4'),
  'corolla': ('toyota', 'Corolla'),
  'prado': ('toyota', 'Land Cruiser Prado'),
  'landcruiserprado': ('toyota', 'Land Cruiser Prado'),
  'landcruiser': ('toyota', 'Land Cruiser'),
  'lc300': ('toyota', 'Land Cruiser'),
  'lc200': ('toyota', 'Land Cruiser'),
  'qashqai': ('nissan', 'Qashqai'),
  'xtrail': ('nissan', 'X-Trail'),
  'gtr': ('nissan', 'GT-R'),
  'civic': ('honda', 'Civic'),
  'civictyper': ('honda', 'Civic Type R'),
  'crv': ('honda', 'CR-V'),
  'solaris': ('hyundai', 'Solaris'),
  'creta': ('hyundai', 'Creta'),
  'tucson': ('hyundai', 'Tucson'),
  'santafe': ('hyundai', 'Santa Fe'),
  'rio': ('kia', 'Rio'),
  'sportage': ('kia', 'Sportage'),
  'sorento': ('kia', 'Sorento'),
  'k5': ('kia', 'K5'),
  'vesta': ('lada', 'Vesta'),
  'vestasw': ('lada', 'Vesta SW'),
  'vestaswcross': ('lada', 'Vesta SW Cross'),
  'granta': ('lada', 'Granta'),
  'niva': ('lada', 'Niva Travel'),
  'coolray': ('geely', 'Coolray'),
  'monjaro': ('geely', 'Monjaro'),
  'atlas': ('geely', 'Atlas'),
  'tiggo4': ('chery', 'Tiggo 4'),
  'tiggo4pro': ('chery', 'Tiggo 4 Pro'),
  'tiggo7': ('chery', 'Tiggo 7 Pro'),
  'tiggo7pro': ('chery', 'Tiggo 7 Pro'),
  'tiggo8': ('chery', 'Tiggo 8 Pro'),
  'tiggo8pro': ('chery', 'Tiggo 8 Pro'),
  'jolion': ('haval', 'Jolion'),
  'dargo': ('haval', 'Dargo'),
  'cx5': ('mazda', 'CX-5'),
  'cx30': ('mazda', 'CX-30'),
  'model3': ('tesla', 'Model 3'),
  'modely': ('tesla', 'Model Y'),
  'models': ('tesla', 'Model S'),
  'modelx': ('tesla', 'Model X'),
  'x1': ('bmw', 'X1'),
  'x3': ('bmw', 'X3'),
  'x4': ('bmw', 'X4'),
  'x5': ('bmw', 'X5'),
  'x6': ('bmw', 'X6'),
  'x7': ('bmw', 'X7'),
  '118i': ('bmw', '1 Series'),
  '118d': ('bmw', '1 Series'),
  '116i': ('bmw', '1 Series'),
  '218i': ('bmw', '2 Series'),
  'm550i': ('bmw', '5 Series'),
  'gla': ('mercedes-benz', 'GLA'),
  'glb': ('mercedes-benz', 'GLB'),
  'glc': ('mercedes-benz', 'GLC'),
  'gle': ('mercedes-benz', 'GLE'),
  'gls': ('mercedes-benz', 'GLS'),
  'cla': ('mercedes-benz', 'CLA'),
  'cls': ('mercedes-benz', 'CLS'),
  'a180': ('mercedes-benz', 'A-Class'),
  'q3': ('audi', 'Q3'),
  'a5': ('audi', 'A5'),
  'a7': ('audi', 'A7'),
  'a8': ('audi', 'A8'),
  'qashqaij11': ('nissan', 'Qashqai'),
  'almera': ('nissan', 'Almera'),
  'jetta': ('volkswagen', 'Jetta'),
  'polo': ('volkswagen', 'Polo'),
  'touareg': ('volkswagen', 'Touareg'),
  'karoq': ('skoda', 'Karoq'),
  'superb': ('skoda', 'Superb'),
  'fabia': ('skoda', 'Fabia'),
  'solaris2': ('hyundai', 'Solaris'),
  'elantra': ('hyundai', 'Elantra'),
  'sonata': ('hyundai', 'Sonata'),
  'riox': ('kia', 'Rio'),
  'rioxline': ('kia', 'Rio'),
  'ceed': ('kia', 'Ceed'),
  'cerato': ('kia', 'Cerato'),
  'optima': ('kia', 'Optima'),
  'camry70': ('toyota', 'Camry'),
  'camryxv70': ('toyota', 'Camry'),
  'landcruiser300': ('toyota', 'Land Cruiser'),
  'highlander': ('toyota', 'Highlander'),
  'prior': ('lada', 'Priora'),
  'priora': ('lada', 'Priora'),
  'kalina': ('lada', 'Kalina'),
  'largus': ('lada', 'Largus'),
  'xray': ('lada', 'XRAY'),
  'niva2121': ('lada', 'Niva'),
  'nivatravel': ('lada', 'Niva Travel'),
  'grantafl': ('lada', 'Granta'),
  'vestasport': ('lada', 'Vesta'),
  'atlaspro': ('geely', 'Atlas'),
  'okavango': ('geely', 'Okavango'),
  'belgee': ('belgee', 'X50'),
  'x50': ('belgee', 'X50'),
  'f7': ('haval', 'F7'),
  'h9': ('haval', 'H9'),
  'uni': ('changan', 'UNI-T'),
  'unit': ('changan', 'UNI-T'),
  'unik': ('changan', 'UNI-K'),
  'cx9': ('mazda', 'CX-9'),
  'mazda3': ('mazda', '3'),
  'mazda6': ('mazda', '6'),
  'forester': ('subaru', 'Forester'),
  'outback': ('subaru', 'Outback'),
  'impreza': ('subaru', 'Impreza'),
  'outlander': ('mitsubishi', 'Outlander'),
  'pajero': ('mitsubishi', 'Pajero'),
  'asx': ('mitsubishi', 'ASX'),
  'rx': ('lexus', 'RX'),
  'nx': ('lexus', 'NX'),
  'lx': ('lexus', 'LX'),
  'es': ('lexus', 'ES'),
  'focus': ('ford', 'Focus'),
  'mondeo': ('ford', 'Mondeo'),
  'kuga': ('ford', 'Kuga'),
  'explorer': ('ford', 'Explorer'),
  'cruze': ('chevrolet', 'Cruze'),
  'tahoe': ('chevrolet', 'Tahoe'),
  'lacetti': ('chevrolet', 'Lacetti'),
  'octaviaa7': ('skoda', 'Octavia'),
  'octaviaa8': ('skoda', 'Octavia'),
};

(String, String) _rewriteQuery(String brand, String model) {
  var make = _canonMake(brand);
  var name = _norm(model);
  if (name.startsWith(make) && make.isNotEmpty) {
    name = name.substring(make.length).trim();
  }
  for (final alias in _makeAliases.keys) {
    if (alias.length >= 3 && name.startsWith('$alias ')) {
      make = make.isEmpty ? _canonMake(alias) : make;
      name = name.substring(alias.length).trim();
      break;
    }
  }
  final compact = _compact(name);
  final code = _modelCodes[compact];
  if (code != null) {
    if (make.isEmpty || make == code.$1 || code.$1.contains(make)) {
      return (code.$1, code.$2);
    }
  }
  return (make, name);
}

int _scoreCar(
  CarSpec car,
  String wantMake,
  String wantModel, {
  String generation = '',
  String bodyType = '',
}) {
  final haveMake = _canonMake(car.make);
  if (wantMake.isNotEmpty) {
    final makeOk = haveMake == wantMake ||
        haveMake.contains(wantMake) ||
        wantMake.contains(haveMake);
    if (!makeOk) return 0;
  }
  final want = _norm(wantModel);
  if (want.isEmpty) return 0;
  final have = _norm(car.model);
  final wantC = _compact(want);
  final haveC = _compact(have);
  final titleC = _compact(car.title);
  var score = 0;
  if (wantC == haveC || wantC == titleC) {
    score = 120;
  } else if (car.aliases.any((a) => _compact(a) == wantC)) {
    score = 115;
  } else if (wantC.length >= 3 && haveC.startsWith(wantC)) {
    score = 80 - ((haveC.length - wantC.length).clamp(0, 20));
  } else if (wantC.length >= 3 && wantC.startsWith(haveC) && haveC.length >= 3) {
    score = 70;
  } else {
    final wantTok = _tokens(want);
    final haveTok = _tokens(have);
    if (wantTok.isEmpty) return 0;
    final overlap = wantTok.where(haveTok.contains).length;
    if (overlap == 0) return 0;
    score = 40 + overlap * 12;
    if (overlap == wantTok.length && overlap == haveTok.length) score = 110;
    if (overlap == wantTok.length && haveTok.length > wantTok.length) {
      score = 75;
    }
  }
  final gen = _compact(generation);
  if (gen.isNotEmpty && _compact(car.generation) == gen) score += 8;
  final body = _norm(bodyType);
  if (body.isNotEmpty && _norm(car.bodyType).contains(body)) score += 3;
  return score;
}

CarSpec? matchCatalog(
  String brand,
  String model, {
  String generation = '',
  String bodyType = '',
}) {
  if (brand.trim().isEmpty && model.trim().isEmpty) return null;
  final rewritten = _rewriteQuery(brand, model);
  final wantMake = rewritten.$1;
  final wantModel = rewritten.$2;
  CarSpec? best;
  var bestScore = 0;
  for (final car in carCatalog) {
    final score = _scoreCar(
      car,
      wantMake,
      wantModel,
      generation: generation,
      bodyType: bodyType,
    );
    if (score > bestScore ||
        (score == bestScore && best != null && car.yearFrom > best.yearFrom)) {
      best = car;
      bestScore = score;
    }
  }
  if (best != null && bestScore >= 55) return best;
  if (wantMake.isEmpty) {
    for (final car in carCatalog) {
      final score = _scoreCar(
        car,
        '',
        '$brand $model'.trim(),
        generation: generation,
        bodyType: bodyType,
      );
      if (score > bestScore ||
          (score == bestScore &&
              best != null &&
              car.yearFrom > best.yearFrom)) {
        best = car;
        bestScore = score;
      }
    }
  }
  if (best != null && bestScore >= 55) return best;
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
