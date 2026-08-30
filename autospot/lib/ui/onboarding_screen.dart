import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  var _page = 0;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AUTOSPOT', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              const Text(
                'Фотографируй машины. Собирай гараж. Соревнуйся в городе.',
                style: TextStyle(color: AppColors.mute, height: 1.4),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: GlassCard(
                  child: _page == 0 ? _intro() : _form(),
                ),
              ),
              const SizedBox(height: 18),
              OrangeButton(
                label: _page == 0 ? 'Дальше' : 'В гараж',
                icon: Icons.arrow_forward_rounded,
                onPressed: () async {
                  if (_page == 0) {
                    setState(() => _page = 1);
                    return;
                  }
                  await ref.read(appProvider.notifier).completeOnboarding(
                        _name.text,
                        _city.text,
                      );
                  if (context.mounted) context.go('/garage');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    const items = [
      ('📸', 'Сними кадр', 'Камера или галерея. ИИ определит марку, тюнинг и состояние.'),
      ('🏅', 'Получи XP', 'Редкость, обвес и качество кадра дают опыт и уровень.'),
      ('🏙', 'Город и дуэли', 'Рейтинг споттеров и сравнение гаражей по четырём метрикам.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.$1, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(item.$3, style: const TextStyle(color: AppColors.mute)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        const Spacer(),
        const Text(
          'Без ключа Vision API работает демо-распознавание. Настоящий ИИ включается в настройках.',
          style: TextStyle(color: AppColors.mute, fontSize: 12),
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Как тебя зовут на улицах?'),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Ник споттера'),
        ),
        const SizedBox(height: 16),
        const Text('Город'),
        const SizedBox(height: 8),
        TextField(
          controller: _city,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Москва, Казань...'),
        ),
        const Spacer(),
        const Text(
          'Город можно уточнить позже — GPS подхватит его при споте.',
          style: TextStyle(color: AppColors.mute, fontSize: 12),
        ),
      ],
    );
  }
}
