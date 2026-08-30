import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../domain/catalog.dart';
import '../domain/game_logic.dart';

const visionPrompt = '''
You are an automotive identification engine for a car-spotting game.
Look at the photo and return STRICT JSON only, no markdown.

Rules:
- Identify the most prominent production car. Ignore people, shops, plates, faces.
- Never transcribe license plates or personal data. Set visible_license_plate true/false only.
- If there is NO clearly visible car (street, sky, room, wall, person, bike, interior only), set is_car=false and empty strings. Do not guess.
- If a car is visible, identify make and model. If unsure, still guess make/model but set confidence to "low".
- Do not invent horsepower, 0-100 or market price. Those are filled by our catalog.
- Tuning must be based only on what is visible.
- make and model MUST match a production car.

JSON schema:
{
  "is_car": true,
  "make": "BMW",
  "model": "M3",
  "generation": "G80",
  "year_from": 2021,
  "year_to": 2024,
  "body_type": "sedan",
  "color": "green",
  "confidence": "low|medium|high",
  "condition": "excellent|good|damaged|restoration|corrosion",
  "tuning": {
    "bodykit": false,
    "wheels": false,
    "spoiler": false,
    "vinyl": false,
    "exhaust": false,
    "lowered": false,
    "details": []
  },
  "photo_quality": "poor|average|good|excellent",
  "visible_license_plate": false,
  "notes": "short visual notes"
}
''';

class PhotoAnalysis {
  const PhotoAnalysis({
    required this.quality,
    required this.hints,
    required this.color,
  });

  final PhotoQuality quality;
  final List<String> hints;
  final String color;
}

PhotoAnalysis analyzePhoto(Uint8List bytes) {
  final hints = <String>[];
  var quality = PhotoQuality.average;
  var color = '';
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const PhotoAnalysis(
      quality: PhotoQuality.poor,
      hints: ['Не удалось прочитать кадр. Сними ещё раз.'],
      color: '',
    );
  }
  final minSide = decoded.width < decoded.height ? decoded.width : decoded.height;
  if (minSide < 480) {
    quality = PhotoQuality.poor;
    hints.add('Кадр мелкий. Подойди ближе.');
  } else if (minSide >= 1000) {
    quality = PhotoQuality.good;
  }

  var brightness = 0;
  var r = 0, g = 0, b = 0;
  const step = 17;
  var n = 0;
  for (var y = 0; y < decoded.height; y += step) {
    for (var x = 0; x < decoded.width; x += step) {
      final p = decoded.getPixel(x, y);
      r += p.r.toInt();
      g += p.g.toInt();
      b += p.b.toInt();
      brightness += (p.r + p.g + p.b).toInt();
      n++;
    }
  }
  if (n > 0) {
    final avg = brightness / (n * 3);
    if (avg < 38) {
      hints.add('Темно. Ищи свет или вспышку.');
      if (quality == PhotoQuality.good) quality = PhotoQuality.average;
    } else if (avg > 230) {
      hints.add('Пересвет. Отойди от прямого солнца.');
    }
    final rr = r / n, gg = g / n, bb = b / n;
    color = _guessColor(rr, gg, bb);
  }
  hints.add('Снимай машину целиком, не обрезай колёса.');
  return PhotoAnalysis(quality: quality, hints: hints, color: color);
}

String _guessColor(double r, double g, double b) {
  final max = [r, g, b].reduce((a, c) => a > c ? a : c);
  final min = [r, g, b].reduce((a, c) => a < c ? a : c);
  if (max < 45) return 'чёрный';
  if (min > 200) return 'белый';
  if (max - min < 18) return r > 150 ? 'серебристый' : 'серый';
  if (r > g && r > b) return 'красный';
  if (b > r && b > g) return 'синий';
  if (g > r && g > b) return 'зелёный';
  if (r > 160 && g > 140 && b < 90) return 'жёлтый';
  return 'серый';
}

String photoHashOf(Uint8List bytes) => sha256.convert(bytes).toString();

bool looksLikeVehicle(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return false;
  const step = 12;
  var n = 0;
  var sum = 0.0;
  var sumSq = 0.0;
  var sky = 0;
  var midContrast = 0;
  final midTop = (decoded.height * 0.25).toInt();
  final midBot = (decoded.height * 0.85).toInt();
  for (var y = 0; y < decoded.height; y += step) {
    for (var x = 0; x < decoded.width; x += step) {
      final p = decoded.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final lum = (r + g + b) / 3;
      sum += lum;
      sumSq += lum * lum;
      n++;
      final isSky = y < decoded.height * 0.45 && b >= r && b >= g && lum > 140;
      if (isSky) sky++;
      if (y >= midTop && y <= midBot) {
        if (x + step < decoded.width) {
          final nxp = decoded.getPixel(x + step, y);
          final d = (lum - (nxp.r + nxp.g + nxp.b) / 3).abs();
          if (d > 18) midContrast++;
        }
      }
    }
  }
  if (n < 8) return false;
  final mean = sum / n;
  final variance = (sumSq / n) - mean * mean;
  final stddev = variance <= 0 ? 0.0 : math.sqrt(variance);
  if (stddev < 12) return false;
  if (sky / n > 0.62 && stddev < 28) return false;
  return midContrast > 6 || stddev > 22;
}

String? resolveVisionKey(String? stored) {
  final local = stored?.trim();
  if (local != null && local.isNotEmpty) return local;
  const gemini = String.fromEnvironment('GEMINI_API_KEY');
  if (gemini.trim().isNotEmpty) return gemini.trim();
  const openai = String.fromEnvironment('OPENAI_API_KEY');
  if (openai.trim().isNotEmpty) return openai.trim();
  return null;
}

class VisionService {
  VisionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<IdentifiedSpot> identify({
    required Uint8List photoBytes,
    required String? apiKey,
    required List<GarageCar> garage,
    required bool huntMatch,
  }) async {
    final hash = photoHashOf(photoBytes);
    final analysis = analyzePhoto(photoBytes);
    final key = resolveVisionKey(apiKey);

    if (key != null) {
      try {
        final extraction = key.startsWith('sk-')
            ? await _openAi(photoBytes, key)
            : await _gemini(photoBytes, key);
        if (!extraction.isCar) {
          throw NoCarFoundException();
        }
        if (extraction.make.trim().isEmpty || extraction.model.trim().isEmpty) {
          throw RecognitionFailedException();
        }
        final spec =
            matchCatalog(extraction.make, extraction.model) ?? fallbackSpec(extraction);
        return buildIdentifiedSpot(
          extraction: extraction,
          spec: spec,
          photoBytes: photoBytes,
          photoHash: hash,
          photoHints: analysis.hints,
          garage: garage,
          fromAi: true,
          needsCatalogPick: false,
          huntMatch: huntMatch,
        );
      } on NoCarFoundException {
        rethrow;
      } on RecognitionFailedException {
        rethrow;
      } catch (_) {
        // fall through to local presence check
      }
    }

    if (!looksLikeVehicle(photoBytes)) {
      throw NoCarFoundException();
    }
    throw RecognitionFailedException();
  }

  Future<VisionExtraction> _gemini(Uint8List bytes, String key) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': visionPrompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(bytes),
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        },
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Gemini ${response.statusCode}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final text = payload['candidates'][0]['content']['parts'][0]['text'] as String;
    return parseVisionJson(text);
  }

  Future<VisionExtraction> _openAi(Uint8List bytes, String key) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'response_format': {'type': 'json_object'},
        'temperature': 0.1,
        'messages': [
          {'role': 'system', 'content': visionPrompt},
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,${base64Encode(bytes)}',
                },
              },
            ],
          },
        ],
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('OpenAI ${response.statusCode}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final text = payload['choices'][0]['message']['content'] as String;
    return parseVisionJson(text);
  }
}

VisionExtraction parseVisionJson(String raw) {
  final cleaned = raw.trim().replaceAll(RegExp(r'```json|```'), '').trim();
  final json = jsonDecode(cleaned) as Map<String, dynamic>;
  final tuning = (json['tuning'] as Map?)?.cast<String, dynamic>() ?? const {};
  return VisionExtraction(
    isCar: json['is_car'] != false,
    make: '${json['make'] ?? ''}',
    model: '${json['model'] ?? ''}',
    generation: '${json['generation'] ?? ''}',
    yearFrom: _asInt(json['year_from'], 2015),
    yearTo: _asInt(json['year_to'], 2024),
    color: '${json['color'] ?? ''}',
    bodyType: '${json['body_type'] ?? ''}',
    confidence: _enum(Confidence.values, json['confidence'], Confidence.medium),
    condition: _enum(CarCondition.values, json['condition'], CarCondition.good),
    tuning: TuningFlags(
      bodykit: tuning['bodykit'] == true,
      wheels: tuning['wheels'] == true,
      spoiler: tuning['spoiler'] == true,
      vinyl: tuning['vinyl'] == true,
      exhaust: tuning['exhaust'] == true,
      lowered: tuning['lowered'] == true,
      details: ((tuning['details'] as List?) ?? const []).map((e) => '$e').toList(),
    ),
    photoQuality:
        _enum(PhotoQuality.values, json['photo_quality'], PhotoQuality.average),
    notes: '${json['notes'] ?? ''}',
  );
}

int _asInt(dynamic value, int fallback) {
  if (value is int) return value;
  return int.tryParse('$value') ?? fallback;
}

T _enum<T extends Enum>(List<T> values, dynamic raw, T fallback) {
  final name = '$raw'.toLowerCase().trim();
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
