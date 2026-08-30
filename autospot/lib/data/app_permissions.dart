import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<void> requestAll() async {
    if (kIsWeb) return;
    final items = <Permission>[
      Permission.camera,
      Permission.locationWhenInUse,
    ];
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      items.add(Permission.photos);
    }
    if (!kIsWeb && Platform.isAndroid) {
      items.add(Permission.storage);
    }
    try {
      await items.request();
    } catch (_) {}
  }
}
