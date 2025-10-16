import 'package:flutter/material.dart';
import '../services/session.dart';
import '../api/api_client.dart';
import '../l10n/app_localizations.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  static const route = '/logs';

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<dynamic>? _logs;
  String? _error;

  Future<void> _fetch() async {
    setState(() { _error = null; _logs = null; });
    final (base, tok) = await SessionService().load();
    if (base == null || tok == null) { setState((){ _error = 'no-credentials'; }); return; }
    try {
      final api = ApiClient(baseUrl: base, token: tok);
      final data = await api.logs(limit: 200);
      setState(() { _logs = data; });
    } catch (e) { setState(() { _error = e.toString(); }); }
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.logs)),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _error != null
            ? ListView(children: [ListTile(title: Text(_error!))])
            : (_logs == null)
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _logs!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final line = _logs![i];
                      return ListTile(
                        dense: true,
                        title: Text('$line'),
                      );
                    },
                  ),
      ),
    );
  }
}
