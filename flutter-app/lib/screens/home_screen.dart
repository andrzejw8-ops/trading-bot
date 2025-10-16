import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/session.dart';
import '../api/api_client.dart';
import '../widgets/status_card.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onChangeLanguage});
  final void Function(Locale) onChangeLanguage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _baseUrl;
  String? _token;
  bool _loading = true;
  Map<String, dynamic>? _status;
  String? _error;

  Future<void> _loadAndFetch() async {
    setState(() { _loading = true; _error = null; });
    final session = SessionService();
    final (base, tok) = await session.load();
    _baseUrl = base; _token = tok;
    if (base == null || tok == null) {
      setState(() { _loading = false; _error = 'no-credentials'; });
      return;
    }
    try {
      final api = ApiClient(baseUrl: base, token: tok);
      final s = await api.status();
      setState(() { _status = s; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: t.changeLanguage,
            onPressed: () async {
              final current = Localizations.localeOf(context).languageCode;
              final next = current == 'en' ? const Locale('pl') : const Locale('en');
              widget.onChangeLanguage(next);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: t.settings,
            onPressed: () async {
              await Navigator.of(context).pushNamed(SettingsScreen.route);
              await _loadAndFetch();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAndFetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error == 'no-credentials')
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(t.noCredentialsTitle),
                  subtitle: Text(t.noCredentialsBody),
                  trailing: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed(SettingsScreen.route),
                    child: Text(t.openSettings),
                  ),
                ),
              )
            else if (_error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text(t.error),
                  subtitle: Text(_error!),
                ),
              )
            else if (_status != null)
              StatusCard(status: _status!),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(t.startBot),
                    onPressed: (_baseUrl == null || _token == null)
                        ? null
                        : () async {
                            try {
                              await ApiClient(baseUrl: _baseUrl!, token: _token!).start();
                              await _loadAndFetch();
                            } catch (e) {
                              _showSnack(context, e.toString());
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: Text(t.stopBot),
                    onPressed: (_baseUrl == null || _token == null)
                        ? null
                        : () async {
                            try {
                              await ApiClient(baseUrl: _baseUrl!, token: _token!).stop();
                              await _loadAndFetch();
                            } catch (e) {
                              _showSnack(context, e.toString());
                            }
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.list_alt),
              label: Text(t.viewLogs),
              onPressed: () => Navigator.of(context).pushNamed(LogsScreen.route),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
