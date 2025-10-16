import 'package:flutter/material.dart';
import '../services/session.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onChangeLanguage});
  static const route = '/settings';
  final void Function(Locale locale)? onChangeLanguage;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _baseCtrl = TextEditingController(text: 'https://trading-bot-api-thgl.onrender.com');
  final _tokenCtrl = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (base, tok) = await SessionService().load();
    if (base != null) _baseCtrl.text = base;
    if (tok != null) _tokenCtrl.text = tok;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.connection, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _baseCtrl,
                decoration: InputDecoration(labelText: t.apiBaseUrl, hintText: 'https://...'),
                keyboardType: TextInputType.url,
                validator: (v) => (v == null || !v.startsWith('http')) ? t.invalidUrl : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tokenCtrl,
                decoration: InputDecoration(labelText: t.apiToken),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? t.requiredField : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton.icon(
                  icon: _loading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.save),
                  label: Text(t.save),
                  onPressed: _loading ? null : () async {
                    if (!_form.currentState!.validate()) return;
                    setState(() => _loading = true);
                    await SessionService().save(baseUrl: _baseCtrl.text.trim(), token: _tokenCtrl.text.trim());
                    setState(() => _loading = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.saved)));
                  },
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(t.clear),
                  onPressed: () async {
                    await SessionService().clear();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cleared)));
                    await _load();
                  },
                )
              ]),

              const Divider(height: 32),
              Text(t.language, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                ChoiceChip(
                  label: const Text('English'),
                  selected: Localizations.localeOf(context).languageCode == 'en',
                  onSelected: (_) => widget.onChangeLanguage?.call(const Locale('en')),
                ),
                ChoiceChip(
                  label: const Text('Polski'),
                  selected: Localizations.localeOf(context).languageCode == 'pl',
                  onSelected: (_) => widget.onChangeLanguage?.call(const Locale('pl')),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
