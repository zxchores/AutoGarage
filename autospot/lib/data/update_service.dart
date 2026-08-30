import 'dart:convert';

import 'package:http/http.dart' as http;

const latestManifestUrl =
    'https://raw.githubusercontent.com/zxchores/AutoGarage/main/autospot/releases/latest.json';

class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.notes,
  });

  final String version;
  final int build;
  final String apkUrl;
  final String notes;

  bool isNewerThan(int currentBuild) => build > currentBuild;
}

class UpdateService {
  Future<AppUpdate?> check(int currentBuild) async {
    try {
      final r = await http.get(Uri.parse(latestManifestUrl)).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200 || r.body.isEmpty) return null;
      final j = jsonDecode(r.body);
      if (j is! Map) return null;
      final m = Map<String, dynamic>.from(j);
      final build = int.tryParse('${m['build'] ?? ''}');
      final version = '${m['version'] ?? ''}';
      final apk = '${m['apk'] ?? ''}';
      if (build == null || version.isEmpty || apk.isEmpty) return null;
      final u = AppUpdate(
        version: version,
        build: build,
        apkUrl: apk,
        notes: '${m['notes'] ?? ''}',
      );
      return u.isNewerThan(currentBuild) ? u : null;
    } catch (_) {
      return null;
    }
  }
}
