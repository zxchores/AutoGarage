import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/catalog.dart';
import '../domain/game_logic.dart';

const visionPrompt = '''
You are an automotive identification engine for a car-spotting game.
Look at the photo and return STRICT JSON only, no markdown.

Rules:
- Identify the most prominent car. Ignore people, shops, plates, faces.
- Never transcribe license plates or personal data. Set visible_license_plate true/false only.
- If it is not a car, set is_car=false and empty strings.
- If unsure, still guess make/model but set confidence to "low".
- Do not invent horsepower, 0-100 or market price. Those are filled by our catalog.
- Tuning must be based only on what is visible.

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
    "details": ["optional visible notes"]
  },
  "photo_quality": "poor|average|good|excellent",
  "visible_license_plate": false,
  "notes": "short visual notes"
}
''';

class VisionService {
  VisionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<IdentifiedSpot> identify({
    required Uint8List photoBytes,
    required String? apiKey,
    required List<GarageCar> garage,
  }) async {
    final key = apiKey?.trim();
    if (key == null || key.isEmpty) {
      return _mock(photoBytes, garage);
    }
    try {
      final extraction = key.startsWith('sk-')
          ? await _openAi(photoBytes, key)
          : await _gemini(photoBytes, key);
      return buildSpot(
        extraction: extraction,
        photoBytes: photoBytes,
        garage: garage,
        fromAi: true,
      );
    } catch (_) {
      return _mock(photoBytes, garage);
    }
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
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Gemini ${response.statusCode}: ${response.body}');
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
        'temperature': 0.2,
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
      throw Exception('OpenAI ${response.statusCode}: ${response.body}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final text = payload['choices'][0]['message']['content'] as String;
    return parseVisionJson(text);
  }

  IdentifiedSpot _mock(Uint8List bytes, List<GarageCar> garage) {
    var hash = 0;
    for (final b in bytes.take(4000)) {
      hash = (hash * 33 + b) & 0x7fffffff;
    }
    final spec = carCatalog[hash % carCatalog.length];
    final extraction = VisionExtraction(
      isCar: true,
      make: spec.make,
      model: spec.model,
      generation: spec.generation,
      yearFrom: spec.yearFrom,
      yearTo: spec.yearTo,
      color: _colors[hash % _colors.length],
      bodyType: spec.bodyType,
      confidence: Confidence.values[hash % 3],
      condition: CarCondition.values[hash % CarCondition.values.length],
      tuning: TuningFlags(
        bodykit: hash.isEven,
        wheels: (hash ~/ 2).isEven,
        spoiler: hash % 3 == 0,
        vinyl: hash % 7 == 0,
        exhaust: hash % 5 == 0,
        lowered: hash % 4 == 0,
        details: const [],
      ),
      photoQuality: PhotoQuality.values[min(hash % 4, 3)],
      notes: 'Демо-режим без ключа Vision API. Та же фотография даёт ту же машину.',
    );
    return buildSpot(
      extraction: extraction,
      photoBytes: bytes,
      garage: garage,
      fromAi: false,
    );
  }
}

const _colors = [
  'чёрный',
  'белый',
  'серый',
  'синий',
  'красный',
  'зелёный',
  'жёлтый',
  'серебристый',
];

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
    condition:
        _enum(CarCondition.values, json['condition'], CarCondition.good),
    tuning: TuningFlags(
      bodykit: tuning['bodykit'] == true,
      wheels: tuning['wheels'] == true,
      spoiler: tuning['spoiler'] == true,
      vinyl: tuning['vinyl'] == true,
      exhaust: tuning['exhaust'] == true,
      lowered: tuning['lowered'] == true,
      details: ((tuning['details'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
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
