import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fabric Care Guide')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: AppData.tips.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final tip = AppData.tips[i];
            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                backgroundColor: AppColors.surface,
                collapsedBackgroundColor: AppColors.surface,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle),
                  child: Icon(tip.icon, size: 18, color: AppColors.coral),
                ),
                title: Text(tip.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: tip.points
                    .map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(Icons.circle, size: 5, color: AppColors.inkSoft),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(p, style: const TextStyle(fontSize: 13, height: 1.45))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
