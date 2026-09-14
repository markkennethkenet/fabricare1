import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fabric_thumb.dart';
import '../history/garment_profile_screen.dart';
import '../scan/scan_screen.dart';
import '../tips/tips_screen.dart';
import '../history/history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return AnimatedBuilder(
      animation: data,
      builder: (context, _) {
        final recent = data.history.take(2).toList();
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Row(
                children: [
                  const Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Fabri', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                      TextSpan(text: 'Care', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.coral)),
                    ]),
                  ),
                  const Spacer(),
                  _circleIcon(Icons.help_outline_rounded),
                  const SizedBox(width: 8),
                  _circleIcon(Icons.person_outline_rounded),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Welcome back, Mark', style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.center_focus_strong_rounded,
                      label: 'Scan Fabric',
                      sub: 'Identify material & condition',
                      bg: AppColors.mustard.withValues(alpha: 0.25),
                      iconColor: AppColors.mustard,
                      onTap: () => _goTo(context, const ScanScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.menu_book_rounded,
                      label: 'Care Guide',
                      sub: 'Tips for every fabric type',
                      bg: AppColors.sage.withValues(alpha: 0.18),
                      iconColor: AppColors.sage,
                      onTap: () => _goTo(context, const TipsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FeatureTile(
                icon: Icons.history_rounded,
                label: 'Scan History',
                sub: 'Review your past scans',
                bg: AppColors.coral.withValues(alpha: 0.12),
                iconColor: AppColors.coral,
                wide: true,
                onTap: () => _goTo(context, const HistoryScreen()),
              ),
              const SizedBox(height: 26),
              const Text('Quick Fabric Tip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.coral),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use clear, even lighting when scanning — it improves fabric type and condition accuracy.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.8), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Scans', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  TextButton(
                    onPressed: () => _goTo(context, const HistoryScreen()),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (recent.isEmpty)
                const Text('No scans yet — try scanning a garment.', style: TextStyle(color: AppColors.inkSoft)),
              ...recent.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => GarmentProfileScreen(result: r)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            FabricThumb(image: r.image, fabricType: r.fabricType),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.garmentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  const SizedBox(height: 2),
                                  Text(
                                    r.hasHealthAssessment
                                        ? '${r.fabricType} · Health ${r.healthScore}/100'
                                        : '${r.fabricType} · ${r.confidencePercent}% confidence',
                                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  static void _goTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  static Widget _circleIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: AppColors.ink),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color bg;
  final Color iconColor;
  final bool wide;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.bg,
    required this.iconColor,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: wide
            ? Row(
                children: [
                  _iconCircle(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(sub, style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconCircle(),
                  const SizedBox(height: 12),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: AppColors.inkSoft, fontSize: 11), maxLines: 2),
                ],
              ),
      ),
    );
  }

  Widget _iconCircle() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}
