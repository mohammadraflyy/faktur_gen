import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/locale_service.dart';

/// Sticky bottom bar: running total plus the screen's one primary action.
class TotalBar extends StatelessWidget {
  final ValueListenable<double> total;
  final NumberFormat currency;
  final String actionLabel;
  final VoidCallback onAction;
  final bool busy;

  const TotalBar({
    super.key,
    required this.total,
    required this.currency,
    required this.actionLabel,
    required this.onAction,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('common.total'), style: theme.textTheme.bodySmall),
                    ValueListenableBuilder<double>(
                      valueListenable: total,
                      builder: (_, value, child) => AnimatedSwitcher(
                        duration: fade,
                        child: Text(
                          currency.format(value),
                          key: ValueKey(value),
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: busy ? null : onAction,
                child: busy
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(tr('common.generating')),
                        ],
                      )
                    : Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
