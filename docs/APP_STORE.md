# Публикация AutoSpot в App Store

IPA из `autospot/releases/` — unsigned sideload-сборка. В App Store / TestFlight её так не залить: нужна подпись командой Apple Developer.

## Что уже готово в проекте

- Bundle ID: `com.zxchores.autospot`
- Имя: AutoSpot
- iOS 15+
- Тексты доступа: камера, фото, геолокация
- `ITSAppUsesNonExemptEncryption` = false

## 1. Аккаунт

1. [Apple Developer](https://developer.apple.com/programs/) — оплатите программу.
2. App Store Connect → новое приложение: **AutoSpot**, bundle `com.zxchores.autospot`.
3. Политика: [`docs/PRIVACY.md`](PRIVACY.md).

## 2. Подпись на Mac

```bash
cd autospot
flutter pub get
open ios/Runner.xcworkspace
```

В Xcode: Team, автоматическая подпись, тот же bundle id.

```bash
flutter build ipa --release
```

Файл: `build/ios/ipa/autospot.ipa`. Загрузка через Transporter или Xcode Organizer.

## 3. Sideload без аккаунта разработчика

Unsigned IPA: [AutoSpot-1.4.0-ios.ipa](https://github.com/zxchores/AutoGarage/raw/main/autospot/releases/AutoSpot-1.4.0-ios.ipa)

Поставить можно через [AltStore](https://altstore.io), Sideloadly или TrollStore. Свой Apple ID переподпишет приложение на 7 дней (бесплатно) или на год (платный Developer).
