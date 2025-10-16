// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Trading Bot';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get settings => 'Settings';

  @override
  String get startBot => 'Start bot';

  @override
  String get stopBot => 'Stop bot';

  @override
  String get viewLogs => 'View logs';

  @override
  String get logs => 'Logs';

  @override
  String get error => 'Error';

  @override
  String get noCredentialsTitle => 'API connection not configured';

  @override
  String get noCredentialsBody =>
      'Open Settings and save API base URL and token to connect to your bot.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get connection => 'Connection';

  @override
  String get apiBaseUrl => 'API base URL';

  @override
  String get apiToken => 'API token';

  @override
  String get invalidUrl => 'Provide a valid URL starting with http(s)';

  @override
  String get requiredField => 'This field is required';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get clear => 'Clear';

  @override
  String get cleared => 'Cleared';

  @override
  String get language => 'Language';

  @override
  String get botRunning => 'Bot is running';

  @override
  String get botStopped => 'Bot is stopped';

  @override
  String get startedAt => 'Started at';
}
