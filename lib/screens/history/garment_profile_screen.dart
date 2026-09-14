import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/scan_result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fabric_thumb.dart';
import '../../widgets/section_card.dart';

class GarmentProfileScreen extends StatefulWidget {
  final ScanResult result;
  const GarmentProfileScreen({super.key, required this.result});

  @override
  State<GarmentProfileScreen> createState() => _GarmentProfileScreenState();
}

class _GarmentProfileScreenState extends State<GarmentProfileScreen> {
  late final TextEditingController _notes = TextEditingController(text: widget.result.notes);

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      appBar: AppBar(title: const Text('Garment Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: FabricThumb(image: r.image, fabricType: r.fabricType, size: 120, radius: 24),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(r.garmentName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Scanned ${_fmtDate(r.dateScanned)}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
            ),
            const SizedBox(height: 22),
            SectionCard(
              title: 'Overview',
              icon: Icons.info_outline_rounded,
              child: Column(
                children: [
                  LabelRow(icon: Icons.texture_outlined, label: 'Fabric', value: '${r.fabricType} (${r.confidencePercent}%)'),
                  if (r.hasHealthAssessment)
                    LabelRow(icon: Icons.favorite_outline_rounded, label: 'Health', value: '${r.healthScore}/100 · ${r.healthRating}'),
                  LabelRow(icon: Icons.hourglass_bottom_rounded, label: 'Lifespan', value: r.lifespanRange),
                  LabelRow(icon: Icons.local_laundry_service_outlined, label: 'Laundry', value: r.laundryMode),
                ],
              ),
            ),
            SectionCard(
              title: 'Saved Care Recommendation',
              icon: Icons.bookmark_outline_rounded,
              child: Column(
                children: [
                  LabelRow(icon: Icons.local_laundry_service_outlined, label: 'Wash', value: r.washMethod),
                  LabelRow(icon: Icons.air_rounded, label: 'Dry', value: r.dryMethod),
                  LabelRow(icon: Icons.iron_outlined, label: 'Iron', value: r.ironLevel),
                ],
              ),
            ),
            SectionCard(
              title: 'Notes',
              icon: Icons.edit_note_rounded,
              child: TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Add a note about this garment…'),
                onChanged: (v) => AppData.instance.updateNotes(r.id, v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
