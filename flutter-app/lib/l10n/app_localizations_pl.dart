// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Trading Bot';

  @override
  String get changeLanguage => 'Zmień język';

  @override
  String get settings => 'Ustawienia';

  @override
  String get startBot => 'Start bota';

  @override
  String get stopBot => 'Stop bota';

  @override
  String get viewLogs => 'Zobacz logi';

  @override
  String get logs => 'Logi';

  @override
  String get error => 'Błąd';

  @override
  String get noCredentialsTitle => 'Brak konfiguracji połączenia API';

  @override
  String get noCredentialsBody =>
      'Otwórz Ustawienia i zapisz adres API oraz token, aby połączyć się z botem.';

  @override
  String get openSettings => 'Otwórz ustawienia';

  @override
  String get connection => 'Połączenie';

  @override
  String get apiBaseUrl => 'Adres bazowy API';

  @override
  String get apiToken => 'Token API';

  @override
  String get invalidUrl =>
      'Podaj prawidłowy adres URL zaczynający się od http(s)';

  @override
  String get requiredField => 'To pole jest wymagane';

  @override
  String get save => 'Zapisz';

  @override
  String get saved => 'Zapisano';

  @override
  String get clear => 'Wyczyść';

  @override
  String get cleared => 'Wyczyszczono';

  @override
  String get language => 'Język';

  @override
  String get botRunning => 'Bot działa';

  @override
  String get botStopped => 'Bot zatrzymany';

  @override
  String get startedAt => 'Start o';
}
