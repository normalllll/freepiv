import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'logic.dart';
import 'page.dart';
import 'widgets.dart';

class FanboxAccountSettings extends ConsumerWidget {
  const FanboxAccountSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(fanboxSessionProvider);
    final operation = ref.watch(fanboxOperationProvider('account'));
    final connected = session.asData?.value != null;
    final t = context.t.fanbox;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(connected ? t.accountConnected : context.t.settings.account.notSignedIn),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: session.isLoading || operation.isLoading
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: CloseButton(onPressed: () => Navigator.pop(dialogContext)),
                              ),
                              Flexible(child: FanboxLoginPanel(onSignedIn: () => Navigator.pop(dialogContext))),
                            ],
                          ),
                        ),
                      ),
                    ),
              child: Text(connected ? t.updateSession : t.login),
            ),
            if (connected)
              TextButton(
                onPressed: operation.isLoading
                    ? null
                    : () => ref.read(fanboxOperationProvider('account').notifier).run(() => ref.read(fanboxSessionProvider.notifier).signOut()),
                child: Text(t.logout),
              ),
          ],
        ),
        SizedBox(height: 40, child: operation.hasError ? Text(fanboxError(context, operation.error!)) : null),
      ],
    );
  }
}
