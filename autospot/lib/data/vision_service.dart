import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../domain/catalog.dart';
import '../domain/game_logic.dart';

const visionPrompt = '''
Identify the main production car in THIS photo. Look at grille, headlights, tail lights, badge, proportions.
Ignore people, shops, interiors, plates. Never copy a license plate.

Reply with ONE line, then JSON.
Line: MAKE|MODEL|GEN|COLOR
Example form only: Toyota|RAV4|XA50|white

JSON:
{"is_car":true,"make":"","model":"","generation":"","year_from":0,"year_to":0,"body_type":"","color":"","confidence":"low|medium|high","condition":"good","tuning":{"bodykit":false,"wheels":false,"spoiler":false,"vinyl":false,"exhaust":false,"lowered":false,"details":[]},"photo_quality":"average","notes":""}

Rules:
- Official English names. Model is the nameplate, never SUV/sedan/crossover.
- Keep performance badges if readable: M3, GTI, RS6, AMG, Type R, WRX.
- Common street cars: Lada, Haval, Geely, Chery, Kia, Hyundai, Skoda, VW, Toyota, BMW, Mercedes-Benz, Audi.
- No car: NO_CAR and {"is_car":false,"make":"","model":""}
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
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const PhotoAnalysis(
      quality: PhotoQuality.poor,
      hints: ['Не удалось прочитать кадр. Сними ещё раз.'],
      color: '',
    );
  }
  return _analyzeDecoded(decoded);
}

PhotoAnalysis _analyzeDecoded(img.Image decoded) {
  final hints = <String>[];
  var quality = PhotoQuality.average;
  var color = '';
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
  return _looksLikeVehicleDecoded(decoded);
}

bool _looksLikeVehicleDecoded(img.Image decoded) {
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

const _spacePrompt = '''
What production car is in this photo? Answer from THIS image only.
First line: MAKE|MODEL|GEN|COLOR
Then JSON: {"is_car":true,"make":"","model":"","generation":"","body_type":"","color":"","confidence":"medium"}
Model is a nameplate, not SUV/sedan. Keep M3/GTI/RS/AMG/Type R if the badge is visible.
No car: NO_CAR
''';

const _builtInSpaces = <(String, String)>[
  ('maziyarpanahi-qwen2-vl-2b.hf.space', 'qwen_inference'),
];

String? resolveVisionKey(String? stored) {
  final local = stored?.trim();
  if (local != null && local.isNotEmpty) return local;
  const gemini = String.fromEnvironment('GEMINI_API_KEY');
  if (gemini.trim().isNotEmpty) return gemini.trim();
  const openai = String.fromEnvironment('OPENAI_API_KEY');
  if (openai.trim().isNotEmpty) return openai.trim();
  return null;
}

Uint8List compressForVision(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  return _jpegForVision(decoded);
}

img.Image focusCar(img.Image src) {
  if (src.width < 720 || src.height < 540) return src;
  final x = (src.width * 0.03).round();
  final y = (src.height * 0.06).round();
  final w = (src.width * 0.94).round();
  final h = (src.height * 0.88).round();
  if (w < 320 || h < 240) return src;
  return img.copyCrop(src, x: x, y: y, width: w, height: h);
}

Uint8List _jpegForVision(img.Image decoded) {
  var work = decoded;
  if (work.width > 1024) {
    work = img.copyResize(work, width: 1024);
  } else if (work.height > 1280) {
    work = img.copyResize(work, height: 1280);
  }
  return Uint8List.fromList(img.encodeJpg(work, quality: 82));
}

bool isFlatFrame(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return true;
  return _isFlatDecoded(decoded);
}

bool _isFlatDecoded(img.Image decoded) {
  const step = 14;
  var n = 0;
  var sum = 0.0;
  var sumSq = 0.0;
  for (var y = 0; y < decoded.height; y += step) {
    for (var x = 0; x < decoded.width; x += step) {
      final p = decoded.getPixel(x, y);
      final lum = (p.r + p.g + p.b) / 3;
      sum += lum;
      sumSq += lum * lum;
      n++;
    }
  }
  if (n < 8) return true;
  final mean = sum / n;
  final variance = (sumSq / n) - mean * mean;
  final stddev = variance <= 0 ? 0.0 : math.sqrt(variance);
  return stddev < 11;
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
    var decoded = img.decodeImage(photoBytes);
    if (decoded == null) {
      throw NoCarFoundException();
    }
    if (decoded.width > 1600) {
      decoded = img.copyResize(decoded, width: 1600);
    }
    decoded = focusCar(decoded);
    final analysis = _analyzeDecoded(decoded);
    if (_isFlatDecoded(decoded)) {
      throw NoCarFoundException();
    }

    final compact = _jpegForVision(decoded);
    final key = resolveVisionKey(apiKey);

    if (key != null) {
      try {
        return _spotFromExtraction(
          extraction: key.startsWith('sk-')
              ? await _openAi(compact, key)
              : await _gemini(compact, key),
          photoBytes: photoBytes,
          hash: hash,
          analysis: analysis,
          garage: garage,
          huntMatch: huntMatch,
        );
      } on NoCarFoundException {
        rethrow;
      } on RecognitionFailedException {
        rethrow;
      } catch (_) {}
    }

    for (final space in _builtInSpaces) {
      try {
        return _spotFromExtraction(
          extraction: await _huggingFaceSpace(compact, space.$1, space.$2),
          photoBytes: photoBytes,
          hash: hash,
          analysis: analysis,
          garage: garage,
          huntMatch: huntMatch,
        );
      } on NoCarFoundException {
        rethrow;
      } on RecognitionFailedException {
        rethrow;
      } catch (_) {}
    }

    if (!_looksLikeVehicleDecoded(decoded)) {
      throw NoCarFoundException();
    }
    throw RecognitionFailedException();
  }

  IdentifiedSpot _spotFromExtraction({
    required VisionExtraction extraction,
    required Uint8List photoBytes,
    required String hash,
    required PhotoAnalysis analysis,
    required List<GarageCar> garage,
    required bool huntMatch,
  }) {
    if (!extraction.isCar) {
      throw NoCarFoundException();
    }
    if (extraction.make.trim().isEmpty && extraction.model.trim().isEmpty) {
      throw RecognitionFailedException();
    }
    final resolved = extraction.color.trim().isEmpty && analysis.color.isNotEmpty
        ? VisionExtraction(
            isCar: extraction.isCar,
            make: extraction.make,
            model: extraction.model,
            generation: extraction.generation,
            yearFrom: extraction.yearFrom,
            yearTo: extraction.yearTo,
            color: analysis.color,
            bodyType: extraction.bodyType,
            confidence: extraction.confidence,
            condition: extraction.condition,
            tuning: extraction.tuning,
            photoQuality: extraction.photoQuality,
            notes: extraction.notes,
          )
        : extraction;
    final spec = matchCatalog(
          resolved.make,
          resolved.model,
          generation: resolved.generation,
          bodyType: resolved.bodyType,
        ) ??
        matchCatalog('', '${resolved.make} ${resolved.model}'.trim()) ??
        fallbackSpec(resolved);
    return buildIdentifiedSpot(
      extraction: resolved,
      spec: spec,
      photoBytes: photoBytes,
      photoHash: hash,
      photoHints: analysis.hints,
      garage: garage,
      fromAi: true,
      needsCatalogPick: false,
      huntMatch: huntMatch,
    );
  }

  Future<VisionExtraction> _huggingFaceSpace(
    Uint8List bytes,
    String host,
    String endpoint,
  ) async {
    final upload = http.MultipartRequest(
      'POST',
      Uri.parse('https://$host/upload'),
    );
    upload.headers['User-Agent'] = 'AutoSpot/1.4';
    upload.files.add(
      http.MultipartFile.fromBytes('files', bytes, filename: 'spot.jpg'),
    );
    final uploaded = await http.Response.fromStream(
      await _client.send(upload).timeout(const Duration(seconds: 12)),
    );
    if (uploaded.statusCode >= 400) {
      throw Exception('upload ${uploaded.statusCode}');
    }
    final path = (jsonDecode(uploaded.body) as List).first as String;
    final file = {
      'path': path,
      'orig_name': 'spot.jpg',
      'mime_type': 'image/jpeg',
      'meta': {'_type': 'gradio.FileData'},
    };
    final call = await _client
        .post(
          Uri.parse('https://$host/call/$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'AutoSpot/1.4',
          },
          body: jsonEncode({
            'data': [file, _spacePrompt],
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (call.statusCode >= 400) {
      throw Exception('call ${call.statusCode}');
    }
    final eventId = '${jsonDecode(call.body)['event_id'] ?? ''}';
    if (eventId.isEmpty) {
      throw Exception('no event');
    }
    final stream = await _client
        .get(
          Uri.parse('https://$host/call/$endpoint/$eventId'),
          headers: {
            'Accept': 'text/event-stream',
            'User-Agent': 'AutoSpot/1.4',
          },
        )
        .timeout(const Duration(seconds: 22));
    if (stream.statusCode >= 400) {
      throw Exception('stream ${stream.statusCode}');
    }
    final answer = parseSpaceStream(stream.body);
    if (answer == null || answer.trim().isEmpty) {
      throw Exception('empty vision reply');
    }
    return parseVisionReply(answer);
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

String? parseSpaceStream(String raw) {
  String? last;
  for (final line in raw.split('\n')) {
    if (!line.startsWith('data: ')) continue;
    final chunk = line.substring(6).trim();
    if (chunk.isEmpty || chunk == 'null') continue;
    try {
      final payload = jsonDecode(chunk);
      if (payload is List && payload.isNotEmpty) {
        final text = '${payload.first}'.trim();
        if (text.isNotEmpty) last = text;
        continue;
      }
      if (payload is Map) {
        if (payload['success'] == false) continue;
        final data = payload['output']?['data'];
        if (data is List && data.isNotEmpty) {
          final text = '${data.first}'.trim();
          if (text.isNotEmpty) last = text;
        }
      }
    } catch (_) {}
  }
  return last;
}

VisionExtraction parseVisionReply(String raw) {
  final cleaned = raw.trim().replaceAll(RegExp(r'```json|```'), '').trim();
  final lower = cleaned.toLowerCase();
  if (RegExp(r'no_car|no car|not a car|нет машин|не вижу').hasMatch(lower) &&
      !RegExp(r'"is_car"\s*:\s*true').hasMatch(lower)) {
    return const VisionExtraction(
      isCar: false,
      make: '',
      model: '',
      generation: '',
      yearFrom: 0,
      yearTo: 0,
      color: '',
      bodyType: '',
      confidence: Confidence.low,
      condition: CarCondition.good,
      tuning: TuningFlags(),
      photoQuality: PhotoQuality.average,
    );
  }
  final start = cleaned.indexOf('{');
  final end = cleaned.lastIndexOf('}');
  if (start >= 0 && end > start) {
    try {
      final parsed = parseVisionJson(cleaned.substring(start, end + 1));
      if (parsed.make.trim().isNotEmpty || parsed.model.trim().isNotEmpty) {
        return parsed;
      }
    } catch (_) {}
  }
  final pipe = RegExp(
    r'([A-Za-zА-Яа-яёЁ0-9.\- ]{2,24})\|([A-Za-zА-Яа-яёЁ0-9.\- ]{1,40})\|([^|\n]{0,24})\|?([^|\n]{0,20})',
  ).firstMatch(cleaned);
  if (pipe != null) {
    final make = pipe.group(1)!.trim();
    final model = pipe.group(2)!.trim();
    if (make.toLowerCase() != 'make' && model.toLowerCase() != 'model') {
      final guessed = matchCatalog(make, model);
      return VisionExtraction(
        isCar: true,
        make: guessed?.make ?? make,
        model: guessed?.model ?? model,
        generation: pipe.group(3)?.trim() ?? guessed?.generation ?? '',
        yearFrom: guessed?.yearFrom ?? 2018,
        yearTo: guessed?.yearTo ?? 2024,
        color: pipe.group(4)?.trim() ?? '',
        bodyType: guessed?.bodyType ?? '',
        confidence: Confidence.medium,
        condition: CarCondition.good,
        tuning: const TuningFlags(),
        photoQuality: PhotoQuality.average,
        notes: cleaned,
      );
    }
  }
  final labeled = RegExp(
    r'make\s*[:=]\s*([A-Za-zА-Яа-яёЁ0-9.\- ]+).*model\s*[:=]\s*([A-Za-zА-Яа-яёЁ0-9.\- ]+)',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(cleaned);
  if (labeled != null) {
    return parseVisionReply('${labeled.group(1)} ${labeled.group(2)}');
  }
  final parts = cleaned
      .replaceAll(RegExp(r'[^A-Za-z0-9А-Яа-яёЁ\- ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    final guessed = matchCatalog(parts.first, parts.sublist(1).join(' '));
    if (guessed != null) {
      return VisionExtraction(
        isCar: true,
        make: guessed.make,
        model: guessed.model,
        generation: guessed.generation,
        yearFrom: guessed.yearFrom,
        yearTo: guessed.yearTo,
        color: '',
        bodyType: guessed.bodyType,
        confidence: Confidence.low,
        condition: CarCondition.good,
        tuning: const TuningFlags(),
        photoQuality: PhotoQuality.average,
        notes: cleaned,
      );
    }
  }
  throw const FormatException('Непонятный ответ ИИ');
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
