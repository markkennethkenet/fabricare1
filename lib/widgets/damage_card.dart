import 'package:flutter/material.dart';

import '../models/damage_detection.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

/// Card for a single damage type (Stain, Pilling) or grouped fiber damage.
class DamageCard extends StatelessWidget {
  final String title;
  final List<DamageCardLine> lines;
  final bool confirmed;
  final VoidCallback? onConfirmToggle;
  final bool showConfirmToggle;
  final Widget? child;

  const DamageCard({
    super.key,
    required this.title,
    required this.lines,
    this.confirmed = false,
    this.onConfirmToggle,
    this.showConfirmToggle = true,
    this.child,
  });

  factory DamageCard.fromItem({
    required DamageItem item,
    required bool confirmed,
    required VoidCallback? onConfirmToggle,
  }) {
    return DamageCard(
      title: item.label,
      lines: [
        DamageCardLine(label: 'Status', value: item.statusDisplay, emphasize: true),
        if (item.status != DamageStatus.notDetected) ...[
          DamageCardLine(label: 'Confidence', value: '${item.confidencePercent}%'),
          if (item.severity != null)
            DamageCardLine(label: 'Severity', value: item.severity!, badge: true),
        ],
      ],
      confirmed: confirmed,
      onConfirmToggle: onConfirmToggle,
      showConfirmToggle: item.isConfirmable,
    );
  }

  factory DamageCard.fiberDamage({
    required DamageItem hole,
    required DamageItem needlemark,
    required bool holeConfirmed,
    required bool needlemarkConfirmed,
    VoidCallback? onHoleToggle,
    VoidCallback? onNeedlemarkToggle,
  }) {
    final maxConf = [hole.confidencePercent, needlemark.confidencePercent].reduce((a, b) => a > b ? a : b);
    final primarySeverity = hole.status != DamageStatus.notDetected
        ? hole.severity
        : needlemark.severity;

    return DamageCard(
      title: 'Fiber Damage',
      lines: [
        DamageCardLine(
          label: 'Hole',
          value: hole.statusLabel,
          emphasize: hole.status == DamageStatus.detected,
        ),
        DamageCardLine(
          label: 'Needlemark',
          value: needlemark.statusLabel,
          emphasize: needlemark.status == DamageStatus.detected,
        ),
        if (maxConf >= 60) DamageCardLine(label: 'Confidence', value: '$maxConf%'),
        if (primarySeverity != null)
          DamageCardLine(label: 'Severity', value: primarySeverity, badge: true),
      ],
      confirmed: holeConfirmed || needlemarkConfirmed,
      showConfirmToggle: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hole.isConfirmable)
            _ConfirmRow(
              label: 'Hole',
              checked: holeConfirmed,
              onChanged: onHoleToggle,
            ),
          if (needlemark.isConfirmable)
            _ConfirmRow(
              label: 'Needlemark',
              checked: needlemarkConfirmed,
              onChanged: onNeedlemarkToggle,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: confirmed ? AppColors.sage.withValues(alpha: 0.5) : AppColors.border,
          width: confirmed ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          for (final line in lines) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      line.label,
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: line.badge
                        ? SeverityBadge(label: line.value)
                        : Text(
                            line.value,
                            style: TextStyle(
                              fontWeight: line.emphasize ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 13.5,
                              color: line.emphasize ? AppColors.ink : AppColors.inkSoft,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 8),
            child!,
          ],
          if (showConfirmToggle && onConfirmToggle != null) ...[
            const SizedBox(height: 12),
            _ConfirmRow(
              label: confirmed ? 'Confirmed' : 'Confirm this damage',
              checked: confirmed,
              onChanged: onConfirmToggle,
            ),
          ],
        ],
      ),
    );
  }
}

class DamageCardLine {
  final String label;
  final String value;
  final bool emphasize;
  final bool badge;

  const DamageCardLine({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.badge = false,
  });
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback? onChanged;

  const _ConfirmRow({
    required this.label,
    required this.checked,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 22,
              color: checked ? AppColors.sage : AppColors.inkSoft,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: checked ? FontWeight.w700 : FontWeight.w500,
                  color: checked ? AppColors.ink : AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
