import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/session.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/logs_screen.dart';

class TradingBotApp extends StatefulWidget {
  const TradingBotApp({super.key});

  @override
  State<TradingBotApp> createState() => _TradingBotAppState();
}

class _TradingBotAppState extends State<TradingBotApp> {
  Locale _locale = const Locale('en');

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trading Bot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('pl')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: HomeScreen(onChangeLanguage: _setLocale),
      routes: {
        SettingsScreen.route: (_) => SettingsScreen(onChangeLanguage: _setLocale),
        LogsScreen.route: (_) => const LogsScreen(),
      },
    );
  }
}
