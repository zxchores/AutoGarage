import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              _tab(Icons.grid_view_rounded, 'Гараж', 0),
              _tab(Icons.camera_alt_rounded, 'Спот', 1, spotlight: true),
              _tab(Icons.emoji_events_rounded, 'Город', 2),
              _tab(Icons.person_rounded, 'Профиль', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(IconData icon, String label, int index, {bool spotlight = false}) {
    final selected = navigationShell.currentIndex == index;
    final color = selected ? AppColors.orange : AppColors.mute;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => navigationShell.goBranch(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.all(spotlight ? 8 : 4),
              decoration: BoxDecoration(
                color: spotlight
                    ? AppColors.orange.withValues(alpha: selected ? 1 : 0.75)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: spotlight ? Colors.black : color,
                size: spotlight ? 22 : 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: spotlight ? AppColors.orange : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
