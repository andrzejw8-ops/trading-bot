import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.status});
  final Map<String, dynamic> status;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final running = (status['running'] as bool?) ?? false;
    final version = (status['version'] as String?) ?? '—';
    final startedAt = (status['started_at'] as String?) ?? '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(running ? Icons.check_circle : Icons.cancel,
                    color: running ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(running ? t.botRunning : t.botStopped,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Chip(label: Text('v$version')),
              ],
            ),
            const SizedBox(height: 8),
            Text('${t.startedAt}: $startedAt'),
          ],
        ),
      ),
    );
  }
}
