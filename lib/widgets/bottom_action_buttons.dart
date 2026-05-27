import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class BottomActionButtons extends StatelessWidget {
  const BottomActionButtons({
    super.key,
    required this.onShare,
    required this.onApply,
    required this.isApplying,
  });

  final VoidCallback onShare;
  final VoidCallback onApply;
  final bool isApplying;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink,
        border: const Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: _SecondaryButton(
                  icon: Icons.ios_share_rounded,
                  onPressed: isApplying ? null : onShare,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isApplying ? null : onApply,
                  icon: Icon(
                    isApplying
                        ? Icons.hourglass_top_rounded
                        : Icons.bolt_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isApplying ? 'APPLYING' : 'APPLY WALLPAPER',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    textStyle: AppText.button(size: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.obsidian,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: AppColors.hairline),
      ),
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Icon(icon, color: AppColors.bone, size: 18),
          ),
        ),
      ),
    );
  }
}
