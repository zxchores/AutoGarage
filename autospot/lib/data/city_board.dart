import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/city.dart';

class CityPlayer {
  const CityPlayer({
    required this.id,
    required this.name,
    required this.xp,
    required this.cars,
    required this.lastSeen,
    this.value = 0,
    this.hp = 0,
    this.kits = 0,
    this.rarest = 0,
    this.clan = '',
  });

  final String id;
  final String name;
  final int xp;
  final int cars;
  final int lastSeen;
  final int value;
  final int hp;
  final int kits;
  final int rarest;
  final String clan;

  bool get online {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now - lastSeen <= 15 * 60;
  }

  bool get hasLineup => value > 0 || hp > 0;

  Map<String, dynamic> toJson() => {
        'i': id,
        'n': name,
        'x': xp,
        'k': cars,
        't': lastSeen,
        if (value > 0) 'v': value,
        if (hp > 0) 'h': hp,
        if (kits > 0) 'b': kits,
        if (rarest > 0) 'r': rarest,
        if (clan.isNotEmpty) 'l': clan,
      };

  factory CityPlayer.fromJson(Map<String, dynamic> json) => CityPlayer(
        id: json['i']?.toString() ?? '',
        name: json['n']?.toString() ?? 'Споттер',
        xp: (json['x'] as num?)?.toInt() ?? 0,
        cars: (json['k'] as num?)?.toInt() ?? 0,
        lastSeen: (json['t'] as num?)?.toInt() ?? 0,
        value: (json['v'] as num?)?.toInt() ?? 0,
        hp: (json['h'] as num?)?.toInt() ?? 0,
        kits: (json['b'] as num?)?.toInt() ?? 0,
        rarest: (json['r'] as num?)?.toInt() ?? 0,
        clan: json['l']?.toString() ?? '',
      );
}

class CityBoard {
  CityBoard({http.Client? client}) : _client = client ?? http.Client();

  static const _app = 'si9qzx4g';
  static const _host = 'keyvalue.immanuel.co';
  static const _staleDays = 7;
  static const _maxPlayers = 10;

  final http.Client _client;

  Future<List<CityPlayer>> fetch(String city) async {
    final key = cityKey(city);
    if (key.isEmpty) return const [];
    try {
      final uri = Uri.https(_host, '/api/KeyVal/GetValue/$_app/c_$key');
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      return _decode(res.body);
    } catch (_) {
      return const [];
    }
  }

  Future<List<CityPlayer>> publish({
    required String city,
    required CityPlayer me,
  }) async {
    final key = cityKey(city);
    if (key.isEmpty || me.id.isEmpty) return const [];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cutoff = now - _staleDays * 24 * 60 * 60;
    final merged = <String, CityPlayer>{};
    for (final p in await fetch(city)) {
      if (p.id.isEmpty || p.lastSeen < cutoff) continue;
      merged[p.id] = p;
    }
    merged[me.id] = CityPlayer(
      id: me.id,
      name: me.name.trim().isEmpty ? 'Споттер' : me.name.trim(),
      xp: me.xp,
      cars: me.cars,
      lastSeen: now,
      value: me.value,
      hp: me.hp,
      kits: me.kits,
      rarest: me.rarest,
      clan: me.clan,
    );
    final ranked = merged.values.toList()
      ..sort((a, b) {
        final byXp = b.xp.compareTo(a.xp);
        if (byXp != 0) return byXp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final top = ranked.take(_maxPlayers).toList();
    if (!top.any((p) => p.id == me.id)) {
      top
        ..removeLast()
        ..add(merged[me.id]!);
      top.sort((a, b) => b.xp.compareTo(a.xp));
    }
    try {
      final payload = _encode(top);
      final uri = Uri.https(
        _host,
        '/api/KeyVal/UpdateValue/$_app/c_$key/$payload',
      );
      await _client
          .post(uri, headers: const {'Content-Length': '0'}, body: '')
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
    return top;
  }

  List<CityPlayer> _decode(String raw) {
    final text = raw.trim().replaceAll('"', '');
    if (text.isEmpty || text == 'null') return const [];
    try {
      var b64 = text.replaceAll('-', '+').replaceAll('_', '/');
      switch (b64.length % 4) {
        case 2:
          b64 += '==';
        case 3:
          b64 += '=';
      }
      final json = utf8.decode(base64.decode(b64));
      final list = jsonDecode(json);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => CityPlayer.fromJson(e.cast<String, dynamic>()))
          .where((p) => p.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String _encode(List<CityPlayer> players) {
    var list = players;
    var encoded = _pack(list);
    while (encoded.length > 1000 && list.length > 3) {
      list = list.sublist(0, list.length - 1);
      encoded = _pack(list);
    }
    if (encoded.length > 1000) {
      encoded = _pack(
        list
            .map(
              (p) => CityPlayer(
                id: p.id,
                name: p.name,
                xp: p.xp,
                cars: p.cars,
                lastSeen: p.lastSeen,
              ),
            )
            .toList(),
      );
    }
    return encoded;
  }

  String _pack(List<CityPlayer> players) {
    final json = jsonEncode(players.map((p) => p.toJson()).toList());
    return base64Url.encode(utf8.encode(json)).replaceAll('=', '');
  }
}
