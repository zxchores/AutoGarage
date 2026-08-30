import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/city.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _key;

  @override
  void initState() {
    super.initState();
    final app = ref.read(appProvider);
    _name = TextEditingController(text: app.profile?.name ?? '');
    _city = TextEditingController(text: cityLabel(app.profile?.city ?? ''));
    _key = TextEditingController(text: app.apiKey ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text('Профиль', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Ник'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Город',
              hintText: 'Красноярск, красноярск или Krasnoyarsk',
            ),
          ),
          const SizedBox(height: 12),
          OrangeButton(
            label: 'Сохранить профиль',
            onPressed: () async {
              await ref.read(appProvider.notifier).updateProfile(
                    name: _name.text,
                    city: _city.text,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Профиль сохранён')),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          const Text('Распознавание', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'ИИ уже встроен и работает онлайн сам. Свой ключ Gemini или OpenAI можно добавить, если хочешь запасной канал.',
            style: TextStyle(color: AppColors.mute, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _key,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'API-ключ'),
          ),
          const SizedBox(height: 12),
          OrangeButton(
            label: 'Сохранить ключ',
            onPressed: () async {
              await ref.read(appProvider.notifier).saveApiKey(_key.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ключ сохранён')),
                );
              }
            },
          ),
          const SizedBox(height: 28),
          const Text('Аккаунт', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await ref.read(appProvider.notifier).logout();
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
