enum Rarity { common, rare, epic, legendary }

enum CarCondition { excellent, good, damaged, restoration, corrosion }

enum PhotoQuality { poor, average, good, excellent }

enum Confidence { low, medium, high }

extension RarityX on Rarity {
  String get label => switch (this) {
        Rarity.common => 'COMMON',
        Rarity.rare => 'RARE',
        Rarity.epic => 'EPIC',
        Rarity.legendary => 'LEGENDARY',
      };

  String get ru => switch (this) {
        Rarity.common => 'Обычная',
        Rarity.rare => 'Редкая',
        Rarity.epic => 'Эпическая',
        Rarity.legendary => 'Легендарная',
      };

  int get rank => index;
}

extension CarConditionX on CarCondition {
  String get ru => switch (this) {
        CarCondition.excellent => 'Отличное',
        CarCondition.good => 'Хорошее',
        CarCondition.damaged => 'Повреждения',
        CarCondition.restoration => 'Реставрация',
        CarCondition.corrosion => 'Коррозия',
      };
}

extension PhotoQualityX on PhotoQuality {
  String get ru => switch (this) {
        PhotoQuality.poor => 'Слабый кадр',
        PhotoQuality.average => 'Нормальный кадр',
        PhotoQuality.good => 'Удачный кадр',
        PhotoQuality.excellent => 'Студийный кадр',
      };
}

class TuningFlags {
  const TuningFlags({
    this.bodykit = false,
    this.wheels = false,
    this.spoiler = false,
    this.vinyl = false,
    this.exhaust = false,
    this.lowered = false,
    this.details = const [],
  });

  final bool bodykit;
  final bool wheels;
  final bool spoiler;
  final bool vinyl;
  final bool exhaust;
  final bool lowered;
  final List<String> details;

  bool get hasAny =>
      bodykit || wheels || spoiler || vinyl || exhaust || lowered;

  bool get isRareTuning => bodykit || vinyl;

  int get count =>
      [bodykit, wheels, spoiler, vinyl, exhaust, lowered].where((e) => e).length;

  List<String> get chips {
    final items = <String>[
      if (bodykit) 'Обвес',
      if (wheels) 'Диски',
      if (spoiler) 'Спойлер',
      if (vinyl) 'Винил',
      if (exhaust) 'Выхлоп',
      if (lowered) 'Занижение',
      ...details,
    ];
    return items.toSet().toList();
  }

  Map<String, dynamic> toJson() => {
        'bodykit': bodykit,
        'wheels': wheels,
        'spoiler': spoiler,
        'vinyl': vinyl,
        'exhaust': exhaust,
        'lowered': lowered,
        'details': details,
      };

  factory TuningFlags.fromJson(Map<String, dynamic> json) => TuningFlags(
        bodykit: json['bodykit'] == true,
        wheels: json['wheels'] == true,
        spoiler: json['spoiler'] == true,
        vinyl: json['vinyl'] == true,
        exhaust: json['exhaust'] == true,
        lowered: json['lowered'] == true,
        details: ((json['details'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class CarSpec {
  const CarSpec({
    required this.id,
    required this.make,
    required this.model,
    required this.generation,
    required this.yearFrom,
    required this.yearTo,
    required this.bodyType,
    required this.horsepower,
    required this.zeroToHundred,
    required this.drivetrain,
    required this.priceRub,
    required this.rarity,
    this.aliases = const [],
  });

  final String id;
  final String make;
  final String model;
  final String generation;
  final int yearFrom;
  final int yearTo;
  final String bodyType;
  final int horsepower;
  final double zeroToHundred;
  final String drivetrain;
  final int priceRub;
  final Rarity rarity;
  final List<String> aliases;

  String get title => '$make $model';

  String get years => '$yearFrom–$yearTo';

  String get imageAsset => 'assets/cars/$id.png';
}

class GarageCar {
  const GarageCar({
    required this.id,
    required this.photoId,
    required this.spottedAt,
    required this.city,
    this.lat,
    this.lng,
    required this.make,
    required this.model,
    required this.generation,
    required this.yearFrom,
    required this.yearTo,
    required this.color,
    required this.bodyType,
    required this.rarity,
    required this.priceRub,
    required this.horsepower,
    required this.zeroToHundred,
    required this.drivetrain,
    required this.condition,
    required this.tuning,
    required this.photoQuality,
    required this.confidence,
    required this.xpEarned,
    this.catalogId,
    this.fromAi = false,
    this.district = '',
  });

  final String id;
  final String photoId;
  final DateTime spottedAt;
  final String city;
  final double? lat;
  final double? lng;
  final String make;
  final String model;
  final String generation;
  final int yearFrom;
  final int yearTo;
  final String color;
  final String bodyType;
  final Rarity rarity;
  final int priceRub;
  final int horsepower;
  final double zeroToHundred;
  final String drivetrain;
  final CarCondition condition;
  final TuningFlags tuning;
  final PhotoQuality photoQuality;
  final Confidence confidence;
  final int xpEarned;
  final String? catalogId;
  final bool fromAi;
  final String district;

  String get title => '$make $model';

  Map<String, dynamic> toJson() => {
        'id': id,
        'photoId': photoId,
        'spottedAt': spottedAt.toIso8601String(),
        'city': city,
        'lat': lat,
        'lng': lng,
        'make': make,
        'model': model,
        'generation': generation,
        'yearFrom': yearFrom,
        'yearTo': yearTo,
        'color': color,
        'bodyType': bodyType,
        'rarity': rarity.name,
        'priceRub': priceRub,
        'horsepower': horsepower,
        'zeroToHundred': zeroToHundred,
        'drivetrain': drivetrain,
        'condition': condition.name,
        'tuning': tuning.toJson(),
        'photoQuality': photoQuality.name,
        'confidence': confidence.name,
        'xpEarned': xpEarned,
        'catalogId': catalogId,
        'fromAi': fromAi,
        'district': district,
      };

  factory GarageCar.fromJson(Map<String, dynamic> json) => GarageCar(
        id: json['id'] as String,
        photoId: json['photoId'] as String,
        spottedAt: DateTime.parse(json['spottedAt'] as String),
        city: json['city'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        make: json['make'] as String? ?? '',
        model: json['model'] as String? ?? '',
        generation: json['generation'] as String? ?? '',
        yearFrom: json['yearFrom'] as int? ?? 2000,
        yearTo: json['yearTo'] as int? ?? 2000,
        color: json['color'] as String? ?? '',
        bodyType: json['bodyType'] as String? ?? '',
        rarity: Rarity.values.byName(json['rarity'] as String? ?? 'common'),
        priceRub: json['priceRub'] as int? ?? 0,
        horsepower: json['horsepower'] as int? ?? 0,
        zeroToHundred: (json['zeroToHundred'] as num?)?.toDouble() ?? 0,
        drivetrain: json['drivetrain'] as String? ?? '',
        condition: CarCondition.values
            .byName(json['condition'] as String? ?? 'good'),
        tuning: TuningFlags.fromJson(
          (json['tuning'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        photoQuality: PhotoQuality.values
            .byName(json['photoQuality'] as String? ?? 'average'),
        confidence: Confidence.values
            .byName(json['confidence'] as String? ?? 'medium'),
        xpEarned: json['xpEarned'] as int? ?? 0,
        catalogId: json['catalogId'] as String?,
        fromAi: json['fromAi'] == true,
        district: json['district'] as String? ?? '',
      );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.city,
    required this.xp,
    required this.createdAt,
    this.login = '',
    this.streak = 0,
    this.lastSpotDay = '',
    this.clan = '',
  });

  final String id;
  final String name;
  final String city;
  final int xp;
  final DateTime createdAt;
  final String login;
  final int streak;
  final String lastSpotDay;
  final String clan;

  UserProfile copyWith({
    String? name,
    String? city,
    int? xp,
    String? login,
    int? streak,
    String? lastSpotDay,
    String? clan,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        city: city ?? this.city,
        xp: xp ?? this.xp,
        createdAt: createdAt,
        login: login ?? this.login,
        streak: streak ?? this.streak,
        lastSpotDay: lastSpotDay ?? this.lastSpotDay,
        clan: clan ?? this.clan,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'xp': xp,
        'createdAt': createdAt.toIso8601String(),
        'login': login,
        'streak': streak,
        'lastSpotDay': lastSpotDay,
        'clan': clan,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Споттер',
        city: json['city'] as String? ?? '',
        xp: json['xp'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        login: json['login'] as String? ?? '',
        streak: json['streak'] as int? ?? 0,
        lastSpotDay: json['lastSpotDay'] as String? ?? '',
        clan: json['clan'] as String? ?? '',
      );
}

class DuelRecord {
  const DuelRecord({
    required this.id,
    required this.createdAt,
    required this.rivalId,
    required this.rivalName,
    required this.userPoints,
    required this.rivalPoints,
    required this.breakdown,
  });

  final String id;
  final DateTime createdAt;
  final String rivalId;
  final String rivalName;
  final int userPoints;
  final int rivalPoints;
  final Map<String, String> breakdown;

  bool get won => userPoints > rivalPoints;
  bool get draw => userPoints == rivalPoints;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'rivalId': rivalId,
        'rivalName': rivalName,
        'userPoints': userPoints,
        'rivalPoints': rivalPoints,
        'breakdown': breakdown,
      };

  factory DuelRecord.fromJson(Map<String, dynamic> json) => DuelRecord(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        rivalId: json['rivalId'] as String,
        rivalName: json['rivalName'] as String,
        userPoints: json['userPoints'] as int,
        rivalPoints: json['rivalPoints'] as int,
        breakdown: ((json['breakdown'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      );
}

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
}

class Rival {
  const Rival({
    required this.id,
    required this.name,
    required this.city,
    required this.xp,
    required this.garageValue,
    required this.totalHp,
    required this.bodykits,
    required this.rarest,
    required this.carCount,
  });

  final String id;
  final String name;
  final String city;
  final int xp;
  final int garageValue;
  final int totalHp;
  final int bodykits;
  final Rarity rarest;
  final int carCount;
}

class VisionExtraction {
  const VisionExtraction({
    required this.isCar,
    required this.make,
    required this.model,
    required this.generation,
    required this.yearFrom,
    required this.yearTo,
    required this.color,
    required this.bodyType,
    required this.confidence,
    required this.condition,
    required this.tuning,
    required this.photoQuality,
    this.notes = '',
    this.view = 'unknown',
  });

  final bool isCar;
  final String make;
  final String model;
  final String generation;
  final int yearFrom;
  final int yearTo;
  final String color;
  final String bodyType;
  final Confidence confidence;
  final CarCondition condition;
  final TuningFlags tuning;
  final PhotoQuality photoQuality;
  final String notes;

  /// front | rear | left | right | three_quarter | top | unknown
  final String view;
}

class XpBreakdown {
  const XpBreakdown({
    required this.base,
    required this.tuning,
    required this.photo,
    required this.hunt,
    required this.duplicate,
    required this.total,
    this.streak = 0,
  });

  final int base;
  final int tuning;
  final int photo;
  final int hunt;
  final bool duplicate;
  final int total;
  final int streak;

  List<(String, String)> get lines => [
        ('Редкость', '+$base'),
        if (tuning != 0) ('Тюнинг', '+$tuning'),
        if (photo != 0) ('Кадр', photo > 0 ? '+$photo' : '$photo'),
        if (hunt != 0) ('Охота дня', '+$hunt'),
        if (streak != 0) ('Серия дней', '+$streak'),
        if (duplicate) ('Дубликат цвета и поколения', '×0.3'),
      ];
}

class PendingSpot {
  const PendingSpot({
    required this.id,
    required this.photoId,
    required this.createdAt,
  });

  final String id;
  final String photoId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'photoId': photoId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingSpot.fromJson(Map<String, dynamic> json) => PendingSpot(
        id: json['id'] as String,
        photoId: json['photoId'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class IdentifiedSpot {
  const IdentifiedSpot({
    required this.extraction,
    required this.spec,
    required this.rarity,
    required this.priceRub,
    required this.horsepower,
    required this.zeroToHundred,
    required this.drivetrain,
    required this.xp,
    required this.breakdown,
    required this.duplicateModel,
    required this.firstCatch,
    required this.fromAi,
    required this.needsCatalogPick,
    required this.photoBytes,
    required this.photoHash,
    this.photoHints = const [],
  });

  final VisionExtraction extraction;
  final CarSpec? spec;
  final Rarity rarity;
  final int priceRub;
  final int horsepower;
  final double zeroToHundred;
  final String drivetrain;
  final int xp;
  final XpBreakdown breakdown;
  final bool duplicateModel;
  final bool firstCatch;
  final bool fromAi;
  final bool needsCatalogPick;
  final List<int> photoBytes;
  final String photoHash;
  final List<String> photoHints;

  String get make => spec?.make ?? extraction.make;
  String get model => spec?.model ?? extraction.model;
  String get title {
    final text = '$make $model'.trim();
    return text.isEmpty ? 'Авто' : text;
  }
}
