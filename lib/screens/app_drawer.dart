import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_constants.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_snackbar.dart';

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

  Future<void> _openInAppPage(BuildContext context, String url) async {
    Navigator.pop(context);

    final bool opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
    );

    if (!opened) {
      AppSnackbar.error('Unable to open this page. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 70, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 68,
                    width: 68,
                    child: Image.asset(
                      'assets/utils/icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Silly Smile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Stylish wallpapers for your device',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          /// MENU ITEMS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ModernTile(
                  icon: Icons.share_rounded,
                  title: 'Share App',
                  onTap: () async {
                    Navigator.pop(context);
                    await SharePlus.instance.share(
                      ShareParams(text: AppConstants.shareMessage),
                    );
                  },
                ),

                const SizedBox(height: 14),

                _ModernTile(
                  icon: Icons.star_rate_rounded,
                  title: 'Rate App',
                  onTap: () => _openRateApp(context),
                ),

                const SizedBox(height: 14),

                _ModernTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Privacy Policy',
                  onTap: () =>
                      _openInAppPage(context, AppConstants.privacyPolicyUrl),
                ),

                const SizedBox(height: 14),

                _ModernTile(
                  icon: Icons.article_outlined,
                  title: 'Terms & Conditions',
                  onTap: () => _openInAppPage(
                    context,
                    AppConstants.termsAndConditionsUrl,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          /// FOOTER
          Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Column(
              children: [
                Container(
                  height: 5,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

class _ModernTile extends StatelessWidget {
  const _ModernTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              /// ICON CONTAINER
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),

              const SizedBox(width: 16),

              /// TITLE
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              /// ARROW
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
