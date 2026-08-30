import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme.dart';
import '../data/auth.dart';
import '../state/app_controller.dart';
import 'widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _code = TextEditingController();
  var _mode = 0; // 0 register, 1 login, 2 totp setup, 3 totp login
  var _busy = false;
  UserAccount? _pending;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    _confirm.dispose();
    _name.dispose();
    _city.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              Text(
                _mode == 0
                    ? 'Регистрация с паролем и 2FA. Камера сама найдёт машину.'
                    : _mode == 1
                        ? 'Войди логином, паролем и кодом из приложения-аутентификатора.'
                        : 'Отсканируй QR в Google Authenticator, Authy или другом TOTP.',
                style: const TextStyle(color: AppColors.mute, height: 1.4),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GlassCard(
                  child: switch (_mode) {
                    0 => _registerForm(),
                    1 => _loginForm(),
                    2 => _totpSetup(),
                    _ => _totpConfirm(),
                  },
                ),
              ),
              const SizedBox(height: 16),
              OrangeButton(
                label: switch (_mode) {
                  0 => 'Создать аккаунт',
                  1 => 'Продолжить',
                  2 => 'Подтвердить 2FA',
                  _ => 'Войти',
                },
                busy: _busy,
                icon: Icons.arrow_forward_rounded,
                onPressed: () => _run(_submit),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _mode = _mode == 0 ? 1 : 0;
                          _code.clear();
                          _pending = null;
                        });
                      },
                child: Text(_mode == 0 || _mode == 2
                    ? 'Уже есть аккаунт? Войти'
                    : 'Нет аккаунта? Регистрация'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final controller = ref.read(appProvider.notifier);
    if (_mode == 0) {
      if (_password.text != _confirm.text) {
        throw AuthException('Пароли не совпадают');
      }
      _pending = await controller.startRegister(
        login: _login.text,
        password: _password.text,
        name: _name.text,
        city: _city.text,
      );
      _code.clear();
      setState(() => _mode = 2);
      return;
    }
    if (_mode == 1) {
      await controller.startLogin(login: _login.text, password: _password.text);
      _code.clear();
      setState(() => _mode = 3);
      return;
    }
    if (_mode == 2) {
      await controller.confirmRegister(_code.text);
    } else {
      await controller.confirmLogin(_code.text);
    }
    if (mounted) context.go('/garage');
  }

  Widget _registerForm() {
    return ListView(
      children: [
        const Text('Регистрация', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextField(
          controller: _login,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Логин'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Пароль'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _confirm,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Повтори пароль'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Ник на улицах'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _city,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Город',
            hintText: 'Красноярск',
          ),
        ),
      ],
    );
  }

  Widget _loginForm() {
    return ListView(
      children: [
        const Text('Вход', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextField(
          controller: _login,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Логин'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Пароль'),
        ),
      ],
    );
  }

  Widget _totpSetup() {
    final account = _pending;
    if (account == null) {
      return const Text('Нет черновика аккаунта');
    }
    return ListView(
      children: [
        const Text('Двухфакторка', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: QrImageView(
              data: account.otpauthUri,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          account.totpSecret,
          textAlign: TextAlign.center,
          style: const TextStyle(
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: account.totpSecret));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Секрет скопирован')),
              );
            }
          },
          child: const Text('Скопировать секрет'),
        ),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Код из приложения'),
        ),
      ],
    );
  }

  Widget _totpConfirm() {
    return ListView(
      children: [
        const Text('Код 2FA', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Text(
          'Введи 6 цифр из аутентификатора.',
          style: TextStyle(color: AppColors.mute),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Код'),
        ),
      ],
    );
  }
}
