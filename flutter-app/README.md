# Trading Bot Mobile (Flutter) — Starter v3

Ten pakiet jest **czysty**: po rozpakowaniu uruchom `setup.sh`, który:
- pobierze paczki,
- wygeneruje foldery `android/` i `ios/` (`flutter create .`),
- ustawi **iOS min 12.0** w Podfile,
- wygeneruje lokalizacje (PL/EN).

## Szybki start (macOS)
```bash
cd ~/Documents
unzip -q ~/Downloads/trading-bot-mobile-starter-v3.zip -d .
mv trading-bot-mobile-v3 flutter-app
cd flutter-app
bash setup.sh
# Android: podłącz telefon i...
flutter run -d <ID_telefonu>
```
> iPhone: Apple wymaga Xcode i podpisów. Otwórz `ios/Runner.xcworkspace` w Xcode i uruchom na **fizycznym iPhonie**.

## Konfiguracja w aplikacji
- Settings → API base: `https://trading-bot-api-thgl.onrender.com`
- Settings → API token: Twój token (przechowywany w SecureStorage)
- Przełącznik języka: PL/EN

## GitHub CI (opcjonalnie)
W folderze `.github/workflows/flutter-ci.yml` jest prosty workflow: `flutter analyze` + `flutter build apk --debug`.
