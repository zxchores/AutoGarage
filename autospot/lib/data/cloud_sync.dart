import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/city.dart';
import '../domain/models.dart';
import 'auth.dart';

const kvHost = 'keyvalue.immanuel.co';
const kvApp = 'si9qzx4g';

class Sighting {
  const Sighting({required this.nick, required this.at});

  final String nick;
  final DateTime at;
}

class CloudAccount {
  const CloudAccount({
    required this.account,
    required this.profile,
    required this.garage,
  });

  final UserAccount account;
  final UserProfile profile;
  final List<GarageCar> garage;
}

class CloudSync {
  static const _chunk = 4;

  Future<void> saveAccount({
    required UserAccount account,
    required UserProfile profile,
    required List<GarageCar> garage,
  }) async {
    final meta = <String, dynamic>{
      'i': account.id,
      's': account.salt,
      'h': account.passwordHash,
      'o': account.totpSecret,
      'n': profile.name,
      'c': profile.city,
      'x': profile.xp,
      'k': profile.streak,
      'l': profile.clan,
      'd': profile.lastSpotDay,
      'g': garage.length,
      'a': account.createdAt.toIso8601String(),
    };
    await kvSet('u_${normalizeLogin(account.login)}', kvEncode(meta));
    for (var i = 0; i < garage.length; i += _chunk) {
      final slice = garage.skip(i).take(_chunk).map(_carOut).toList();
      await kvSet('g_${account.id}_${i ~/ _chunk}', kvEncode(slice));
    }
  }

  Future<CloudAccount?> loadAccount(String login) async {
    final raw = await kvGet('u_${normalizeLogin(login)}');
    if (raw.isEmpty) return null;
    final j = kvDecode(raw);
    if (j is! Map) return null;
    final m = Map<String, dynamic>.from(j);
    final id = '${m['i'] ?? ''}';
    if (id.isEmpty) return null;
    final n = (m['g'] as num?)?.toInt() ?? 0;
    final garage = <GarageCar>[];
    final chunks = n == 0 ? 0 : ((n + _chunk - 1) ~/ _chunk);
    for (var i = 0; i < chunks; i++) {
      final chunk = await kvGet('g_${id}_$i');
      if (chunk.isEmpty) continue;
      final list = kvDecode(chunk);
      if (list is! List) continue;
      for (final e in list) {
        if (e is Map) garage.add(_carIn(Map<String, dynamic>.from(e)));
      }
    }
    final created =
        DateTime.tryParse('${m['a'] ?? ''}') ?? DateTime.now();
    final name = '${m['n'] ?? login}';
    final city = cityLabel('${m['c'] ?? ''}');
    return CloudAccount(
      account: UserAccount(
        id: id,
        login: normalizeLogin(login),
        salt: '${m['s']}',
        passwordHash: '${m['h']}',
        totpSecret: '${m['o']}',
        name: name,
        city: city,
        createdAt: created,
      ),
      profile: UserProfile(
        id: id,
        name: name,
        city: city,
        xp: (m['x'] as num?)?.toInt() ?? 0,
        createdAt: created,
        login: normalizeLogin(login),
        streak: (m['k'] as num?)?.toInt() ?? 0,
        lastSpotDay: '${m['d'] ?? ''}',
        clan: '${m['l'] ?? ''}',
      ),
      garage: garage,
    );
  }

  Future<void> postSighting({
    required String city,
    required String catalogId,
    required String nick,
  }) async {
    final key = cityKey(city);
    if (key.isEmpty || catalogId.isEmpty || nick.trim().isEmpty) return;
    final slot = 'm_${key}_$catalogId';
    final raw = await kvGet(slot);
    final list = <Map<String, dynamic>>[];
    if (raw.isNotEmpty) {
      final j = kvDecode(raw);
      if (j is List) {
        for (final e in j) {
          if (e is Map) list.add(Map<String, dynamic>.from(e));
        }
      }
    }
    list.removeWhere((e) => e['n'] == nick);
    list.insert(0, {
      'n': nick,
      't': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
    });
    var payload = list.take(8).toList();
    while (kvEncode(payload).length > 1000 && payload.length > 1) {
      payload = payload.sublist(0, payload.length - 1);
    }
    await kvSet(slot, kvEncode(payload));
  }

  Future<List<Sighting>> sightings({
    required String city,
    required String catalogId,
  }) async {
    final key = cityKey(city);
    if (key.isEmpty || catalogId.isEmpty) return const [];
    final raw = await kvGet('m_${key}_$catalogId');
    if (raw.isEmpty) return const [];
    final j = kvDecode(raw);
    if (j is! List) return const [];
    return j.whereType<Map>().map((e) {
      final t = (e['t'] as num?)?.toInt() ?? 0;
      return Sighting(
        nick: '${e['n'] ?? '?'}',
        at: DateTime.fromMillisecondsSinceEpoch(t * 1000, isUtc: true)
            .toLocal(),
      );
    }).toList();
  }

  Map<String, dynamic> _carOut(GarageCar c) => {
        'i': c.id,
        'c': c.catalogId ?? '',
        'm': c.make,
        'o': c.model,
        'f': c.yearFrom,
        'e': c.yearTo,
        'g': c.generation,
        'r': c.rarity.name,
        'p': c.priceRub,
        'h': c.horsepower,
        's': c.spottedAt.toIso8601String(),
        'l': c.color,
        'd': c.district,
        'y': c.city,
        'b': c.bodyType,
        'w': c.horsepower,
        'z': c.zeroToHundred,
        'v': c.drivetrain,
        'x': c.xpEarned,
      };

  GarageCar _carIn(Map<String, dynamic> c) => GarageCar(
        id: '${c['i']}',
        photoId: '',
        spottedAt: DateTime.tryParse('${c['s']}') ?? DateTime.now(),
        city: '${c['y'] ?? ''}',
        make: '${c['m'] ?? ''}',
        model: '${c['o'] ?? ''}',
        generation: '${c['g'] ?? ''}',
        yearFrom: (c['f'] as num?)?.toInt() ?? 2020,
        yearTo: (c['e'] as num?)?.toInt() ?? 2024,
        color: '${c['l'] ?? ''}',
        bodyType: '${c['b'] ?? ''}',
        rarity: Rarity.values.firstWhere(
          (r) => r.name == '${c['r']}',
          orElse: () => Rarity.common,
        ),
        priceRub: (c['p'] as num?)?.toInt() ?? 0,
        horsepower: (c['h'] as num?)?.toInt() ?? (c['w'] as num?)?.toInt() ?? 0,
        zeroToHundred: (c['z'] as num?)?.toDouble() ?? 0,
        drivetrain: '${c['v'] ?? ''}',
        condition: CarCondition.good,
        tuning: const TuningFlags(),
        photoQuality: PhotoQuality.average,
        confidence: Confidence.medium,
        xpEarned: (c['x'] as num?)?.toInt() ?? 0,
        catalogId: '${c['c'] ?? ''}'.isEmpty ? null : '${c['c']}',
        district: '${c['d'] ?? ''}',
        fromAi: true,
      );
}

Future<void> kvSet(String key, String value) async {
  await http
      .post(
        Uri.https(kvHost, '/api/KeyVal/UpdateValue/$kvApp/$key/$value'),
        headers: const {'Content-Length': '0'},
        body: '',
      )
      .timeout(const Duration(seconds: 8));
}

Future<String> kvGet(String key) async {
  try {
    final r = await http
        .get(Uri.https(kvHost, '/api/KeyVal/GetValue/$kvApp/$key'))
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) return '';
    final t = r.body.trim().replaceAll('"', '');
    if (t.isEmpty || t == 'null' || t == 'Key not exists.') return '';
    return t;
  } catch (_) {
    return '';
  }
}

String kvEncode(Object value) =>
    base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

dynamic kvDecode(String raw) {
  try {
    var s = raw.replaceAll('-', '+').replaceAll('_', '/');
    while (s.length % 4 != 0) {
      s += '=';
    }
    return jsonDecode(utf8.decode(base64Decode(s)));
  } catch (_) {
    return null;
  }
}
