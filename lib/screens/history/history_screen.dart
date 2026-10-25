import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fabric_thumb.dart';
import '../../widgets/section_card.dart';
import 'garment_profile_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return AnimatedBuilder(
      animation: data,
      builder: (context, _) {
        final history = data.history;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Scan History'),
            actions: [
              if (history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Clear history',
                  onPressed: () => _confirmClear(context),
                ),
            ],
          ),
          body: SafeArea(
            child: history.isEmpty
                ? Center(
                    child: Text(data.storageError ?? 'No scans yet.',
                        style: const TextStyle(color: AppColors.inkSoft)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = history[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => GarmentProfileScreen(result: r)),
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
                              FabricThumb(
                                  image: r.image,
                                  fabricType: r.fabricType,
                                  size: 56),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.garmentName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5)),
                                    const SizedBox(height: 3),
                                    Text(
                                        '${r.fabricType} · ${_fmtDate(r.dateScanned)}',
                                        style: const TextStyle(
                                            color: AppColors.inkSoft,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              SeverityBadge(label: r.healthRating),
                              IconButton(
                                  tooltip: 'Delete scan',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(context, r.id)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear scan history?'),
        content: const Text(
            'This will remove all saved scans for your account on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AppData.instance.clearHistory();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Could not clear history. Try again.')));
                }
              }
            },
            child:
                const Text('Clear', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Delete this scan?'),
                content: const Text(
                    'The saved scan and its photos will be removed.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'))
                ]));
    if (confirmed != true) return;
    try {
      await AppData.instance.deleteScan(id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete scan. Try again.')));
      }
    }
  }

  static String _fmtDate(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
