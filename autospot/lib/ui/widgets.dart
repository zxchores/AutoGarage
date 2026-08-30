import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../domain/models.dart';
import '../state/app_controller.dart';

class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity, this.compact = false});

  final Rarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarity(rarity);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: body,
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.mute, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class SpotPhoto extends ConsumerWidget {
  const SpotPhoto({
    super.key,
    required this.photoId,
    this.borderRadius = 18,
    this.height,
  });

  final String photoId;
  final double borderRadius;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Uint8List?>(
      future: ref.read(appProvider.notifier).photo(photoId),
      builder: (context, snap) {
        Widget child;
        if (snap.data == null) {
          child = Container(
            height: height ?? 180,
            color: AppColors.surface,
            child: const Center(
              child: Icon(Icons.directions_car_filled, color: AppColors.mute, size: 42),
            ),
          );
        } else {
          child = Image.memory(
            snap.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        );
      },
    );
  }
}

class OrangeButton extends StatelessWidget {
  const OrangeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
