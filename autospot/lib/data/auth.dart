import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UserAccount {
  const UserAccount({
    required this.id,
    required this.login,
    required this.salt,
    required this.passwordHash,
    required this.totpSecret,
    required this.name,
    required this.city,
    required this.createdAt,
  });

  final String id;
  final String login;
  final String salt;
  final String passwordHash;
  final String totpSecret;
  final String name;
  final String city;
  final DateTime createdAt;

  String get otpauthUri =>
      'otpauth://totp/AutoSpot:${Uri.encodeComponent(login)}'
      '?secret=$totpSecret&issuer=AutoSpot&algorithm=SHA1&digits=6&period=30';

  Map<String, dynamic> toJson() => {
        'id': id,
        'login': login,
        'salt': salt,
        'passwordHash': passwordHash,
        'totpSecret': totpSecret,
        'name': name,
        'city': city,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: json['id'] as String,
        login: json['login'] as String,
        salt: json['salt'] as String,
        passwordHash: json['passwordHash'] as String,
        totpSecret: json['totpSecret'] as String,
        name: json['name'] as String? ?? '',
        city: json['city'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

const _b32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

String normalizeLogin(String raw) => raw.trim().toLowerCase();

String newSalt() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String hashPassword(String password, String salt) =>
    sha256.convert(utf8.encode('$salt:$password')).toString();

bool passwordLooksOk(String password) => password.length >= 6;

String newTotpSecret() {
  final rng = Random.secure();
  final bytes = List<int>.generate(20, (_) => rng.nextInt(256));
  return base32Encode(bytes);
}

String base32Encode(List<int> bytes) {
  var buffer = 0;
  var bits = 0;
  final out = StringBuffer();
  for (final byte in bytes) {
    buffer = (buffer << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      out.write(_b32[(buffer >> bits) & 31]);
    }
  }
  if (bits > 0) {
    out.write(_b32[(buffer << (5 - bits)) & 31]);
  }
  return out.toString();
}

Uint8List base32Decode(String input) {
  final clean = input.replaceAll(RegExp(r'[\s=]'), '').toUpperCase();
  var buffer = 0;
  var bits = 0;
  final out = <int>[];
  for (final unit in clean.codeUnits) {
    final index = _b32.codeUnits.indexOf(unit);
    if (index < 0) continue;
    buffer = (buffer << 5) | index;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      out.add((buffer >> bits) & 0xff);
    }
  }
  return Uint8List.fromList(out);
}

String totpCode(String secret, {DateTime? now, int driftSteps = 0}) {
  final instant = now ?? DateTime.now();
  final counter =
      (instant.toUtc().millisecondsSinceEpoch ~/ 1000) ~/ 30 + driftSteps;
  final key = base32Decode(secret);
  final data = ByteData(8)..setUint64(0, counter, Endian.big);
  final digest = Hmac(sha1, key).convert(data.buffer.asUint8List());
  final bytes = digest.bytes;
  final offset = bytes[19] & 0x0f;
  final binary = ((bytes[offset] & 0x7f) << 24) |
      ((bytes[offset + 1] & 0xff) << 16) |
      ((bytes[offset + 2] & 0xff) << 8) |
      (bytes[offset + 3] & 0xff);
  return (binary % 1000000).toString().padLeft(6, '0');
}

bool totpVerify(String secret, String code) {
  final trimmed = code.trim();
  if (trimmed.length != 6) return false;
  final now = DateTime.now();
  for (final drift in [-1, 0, 1]) {
    if (totpCode(secret, now: now, driftSteps: drift) == trimmed) {
      return true;
    }
  }
  return false;
}
