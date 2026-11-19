import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/billing_service.dart';
import '../services/locale_service.dart';
import '../services/subscription_service.dart';

Future<bool?> showPaywallSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _PaywallSheet(),
  );
}

class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet();

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  bool _isLoading = false;

  Future<void> _purchase() async {
    if (BillingService.productDetails == null) {
      // Play Store product not configured yet — show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('sub.not_available'))),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      await BillingService.purchasePro();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('sub.purchase_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRedeemDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('sub.redeem')),
        content: TextField(
          controller: codeCtrl,
          decoration: InputDecoration(
            labelText: tr('sub.redeem_code'),
            hintText: 'XXXX-XXXX',
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final success = await SubscriptionService.redeemCode(code);
              if (mounted) {
                setState(() => _isLoading = false);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('sub.redeem_success'))),
                  );
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('sub.redeem_invalid'))),
                  );
                }
              }
            },
            child: Text(tr('sub.redeem_activate')),
          ),
        ],
      ),
    );
  }

  Future<void> _debugActivate() async {
    await SubscriptionService.setPro(
      'debug_token',
      DateTime.now().add(const Duration(days: 30)),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pro activated (debug)')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    try {
      await BillingService.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('sub.restore_done'))),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('sub.restore_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Crown icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  size: 32, color: Color(0xFFFFA000)),
            ),
            const SizedBox(height: 16),
            Text(
              tr('sub.pro'),
              style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr('sub.unlock_all'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            // Features list
            ..._features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(f.$1, size: 20, color: const Color(0xFFFFA000)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tr(f.$2),
                      style: GoogleFonts.inter(fontSize: 14,
                        color: theme.colorScheme.onSurface)),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            // Price + Subscribe button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000),
                  foregroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2))
                    : Text(
                        '${tr('sub.subscribe')} — ${BillingService.priceString}',
                        style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _restore,
              child: Text(
                tr('sub.restore'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _isLoading ? null : () => _showRedeemDialog(context),
              icon: Icon(Icons.card_giftcard_rounded, size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
              label: Text(
                tr('sub.redeem'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            // Free Pro for testing; must never reach a release build.
            if (kDebugMode)
              TextButton(
                onPressed: _isLoading ? null : _debugActivate,
                child: Text(
                  'Activate Pro (Debug)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _features = [
    (Icons.all_inclusive, 'sub.unlimited'),
    (Icons.hide_image_outlined, 'sub.no_watermark'),
    (Icons.qr_code_2_rounded, 'sub.qris'),
    (Icons.repeat_rounded, 'sub.recurring'),
    (Icons.currency_exchange_rounded, 'sub.multicurrency'),
    (Icons.numbers_rounded, 'sub.client_numbering'),
  ];
}
