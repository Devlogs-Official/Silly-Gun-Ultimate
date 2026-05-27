import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_constants.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_palette.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_typography.dart';
import 'settings_screen.dart';

class ModernDrawer extends StatelessWidget {
  const ModernDrawer({super.key});

  Future<void> _openRateApp(BuildContext context) async {
    Navigator.pop(context);

    final Uri deepLink = Uri.parse(AppConstants.playStoreDeepLink);
    final Uri webUrl = Uri.parse(AppConstants.playStoreUrl);

    final bool openedStore = await launchUrl(
      deepLink,
      mode: LaunchMode.externalApplication,
    );

    if (!openedStore) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _openWebPage(BuildContext context, String url) async {
    Navigator.pop(context);
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppBrowserView,
      );
      if (!ok) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      AppSnackbar.error('Unable to open this page. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Drawer(
      backgroundColor: palette.ink,
      width: MediaQuery.sizeOf(context).width * 0.84,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(2),
          bottomRight: Radius.circular(2),
        ),
        side: BorderSide(color: palette.hairline),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                                width: 22, height: 2, color: AppColors.crimson),
                            const SizedBox(width: 10),
                            Text('MENU · 01', style: AppText.eyebrow()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'SILLY',
                          style:
                              AppText.display(size: 44, height: 0.88, color: palette.bone),
                        ),
                        Text(
                          'SMILE.',
                          style: AppText.display(
                            size: 44,
                            height: 0.88,
                            color: AppColors.crimson,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: palette.obsidian,
                      foregroundColor: palette.bone,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                        side: BorderSide(color: palette.hairline),
                      ),
                      minimumSize: const Size(42, 42),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _DrawerTile(
                    index: '01',
                    icon: Icons.tune_rounded,
                    label: 'SETTINGS',
                    onTap: () => _openSettings(context),
                  ),
                  _DrawerTile(
                    index: '02',
                    icon: Icons.share_rounded,
                    label: 'SHARE APP',
                    onTap: () async {
                      Navigator.pop(context);
                      await SharePlus.instance.share(
                        ShareParams(text: AppConstants.shareMessage),
                      );
                    },
                  ),
                  _DrawerTile(
                    index: '03',
                    icon: Icons.star_rate_rounded,
                    label: 'RATE ON STORE',
                    onTap: () => _openRateApp(context),
                  ),
                  _DrawerTile(
                    index: '04',
                    icon: Icons.shield_outlined,
                    label: 'PRIVACY POLICY',
                    onTap: () =>
                        _openWebPage(context, AppConstants.privacyPolicyUrl),
                  ),
                  _DrawerTile(
                    index: '05',
                    icon: Icons.article_outlined,
                    label: 'TERMS & CONDITIONS',
                    onTap: () => _openWebPage(
                      context,
                      AppConstants.termsAndConditionsUrl,
                    ),
                    isLast: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
              child: Row(
                children: [
                  Container(width: 22, height: 2, color: AppColors.crimson),
                  const SizedBox(width: 10),
                  Text(
                    'VERSION ${AppConstants.appVersion}',
                    style: AppText.mono(size: 10, color: palette.smoke),
                  ),
                  const Spacer(),
                  Text(
                    '© DEVLOGS',
                    style: AppText.mono(size: 10, color: palette.smoke),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  final String index;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : palette.hairline,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                index,
                style: AppText.mono(size: 11, color: AppColors.crimson),
              ),
            ),
            Icon(icon, color: palette.bone, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppText.button(color: palette.bone, size: 14),
              ),
            ),
            Icon(
              Icons.arrow_outward_rounded,
              color: palette.ash,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
