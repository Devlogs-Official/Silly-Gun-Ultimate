import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';

class BottomActionButtons extends StatelessWidget {
  const BottomActionButtons({
    super.key,
    required this.onShare,
    required this.onApply,
    required this.isApplying,
    this.applyLabel = 'APPLY WALLPAPER',
    this.busyLabel = 'APPLYING',
    this.applyIcon = Icons.bolt_rounded,
  });

  final VoidCallback onShare;
  final VoidCallback onApply;
  final bool isApplying;
  final String applyLabel;
  final String busyLabel;
  final IconData applyIcon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.ink,
        border: Border(top: BorderSide(color: palette.hairline)),
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
                    isApplying ? Icons.hourglass_top_rounded : applyIcon,
                    size: 16,
                  ),
                  label: Text(isApplying ? busyLabel : applyLabel),
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
    final palette = context.palette;
    return Material(
      color: palette.obsidian,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: BorderSide(color: palette.hairline),
      ),
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Center(child: Icon(icon, color: palette.bone, size: 18)),
        ),
      ),
    );
  }
}
