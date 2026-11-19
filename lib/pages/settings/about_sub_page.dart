import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/locale_service.dart';
import '../../services/updater_service.dart';

class AboutSubPage extends StatelessWidget {
  const AboutSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('about.title'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: 40, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Faktura',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('about.subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('about.version')
                .replaceAll('{version}', UpdaterService.currentAppVersion),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 32),
          _infoTile(theme,
              icon: Icons.description_outlined,
              title: tr('about.features'),
              subtitle: tr('about.features_desc')),
          _infoTile(theme,
              icon: Icons.print_outlined,
              title: tr('about.print'),
              subtitle: tr('about.print_desc')),
          _infoTile(theme,
              icon: Icons.backup_outlined,
              title: tr('about.data'),
              subtitle: tr('about.data_desc')),
          _infoTile(theme,
              icon: Icons.palette_outlined,
              title: tr('about.theme'),
              subtitle: tr('about.theme_desc')),
          const SizedBox(height: 24),
          Text(
            tr('about.made_with'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(ThemeData theme,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 18,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
