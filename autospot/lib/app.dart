import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'state/app_controller.dart';

class AutoSpotApp extends ConsumerWidget {
  const AutoSpotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final app = ref.watch(appProvider);
    final theme = buildTheme(light: app.lightTheme, large: app.largeText);
    return MaterialApp.router(
      title: 'AutoSpot',
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(app.largeText ? 1.18 : 1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
