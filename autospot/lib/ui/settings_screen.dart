import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/city.dart';
import '../core/theme.dart';
import '../core/version.dart';
import '../state/app_controller.dart';
import 'garage_screen.dart';
import 'widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _clan;
  late final TextEditingController _key;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final app = ref.read(appProvider);
    _name = TextEditingController(text: app.profile?.name ?? '');
    _city = TextEditingController(text: cityLabel(app.profile?.city ?? ''));
    _clan = TextEditingController(text: app.profile?.clan ?? '');
    _key = TextEditingController(text: app.apiKey ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _clan.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Версия $appVersion', style: const TextStyle(color: AppColors.mute)),
          const SizedBox(height: 8),
          ref.watch(updateCheckProvider).when(
                data: (u) => u == null
                    ? const Text('У тебя свежая сборка')
                    : OrangeButton(
                        label: 'Скачать ${u.version}',
                        icon: Icons.system_update_alt,
                        onPressed: () => launchUrl(
                          Uri.parse(u.apkUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                loading: () => const Text('Проверяю обновление…'),
                error: (_, _) => const SizedBox.shrink(),
              ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 10),
          TextField(
            controller: _clan,
            decoration: const InputDecoration(
              labelText: 'Клан / экипаж',
              hintText: 'Одно имя — один клан',
            ),
          ),
          const SizedBox(height: 12),
          OrangeButton(
            label: 'Сохранить профиль',
            onPressed: () async {
              await ref.read(appProvider.notifier).updateProfile(
                    name: _name.text,
                    city: _city.text,
                    clan: _clan.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Профиль сохранён')),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          const Text('Вид', style: TextStyle(fontWeight: FontWeight.w800)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Светлая тема'),
            value: app.lightTheme,
            onChanged: (v) =>
                ref.read(appProvider.notifier).setTheme(light: v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Крупный шрифт'),
            value: app.largeText,
            onChanged: (v) =>
                ref.read(appProvider.notifier).setTheme(large: v),
          ),
          const SizedBox(height: 12),
          const Text('Облако', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Гараж без фото можно забрать на другом телефоне тем же логином, паролем и 2FA.',
            style: TextStyle(color: AppColors.mute, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 8),
          OrangeButton(
            label: _busy ? 'Пишу…' : 'Сохранить в облако',
            busy: _busy,
            onPressed: () async {
              setState(() => _busy = true);
              try {
                await ref.read(appProvider.notifier).backupCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Облако обновлено')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(appProvider.notifier).restoreCloud();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Гараж восстановлен')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: const Text('Восстановить с облака'),
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
          const SizedBox(height: 6),
          const Text(
            'Логин живёт на телефоне. Облако хранит хеш пароля, 2FA и гараж без фото. В рейтинг города уходит ник, город, XP и клан.',
            style: TextStyle(color: AppColors.mute, fontSize: 13, height: 1.35),
          ),
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
