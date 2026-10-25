import 'package:flutter/material.dart';

import '../../models/scan_result.dart';
import '../../widgets/detection_image.dart';
import '../../widgets/section_card.dart';
import 'scan_screen.dart';

/// Displays assessment supplied by the backend; no local scoring rules.
class ScanResultScreen extends StatelessWidget {
  final ScanResult result;
  const ScanResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final damage = result.damageDetection.allItems;
    final perImage = result.analysis['per_image'] as List? ?? [];
    Map metadata(int index) =>
        index < perImage.length ? perImage[index] as Map : const {};
    return Scaffold(
      appBar: AppBar(title: const Text('FabriCare Result')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            for (var i = 0; i < result.images.length; i++) ...[
              Text(result.images[i].view.replaceAll('_', ' '),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DetectionImage(scan: result, imageIndex: i),
              if (metadata(i)['fabric_type'] != null)
                Text(
                    "${metadata(i)['fabric_type']} · ${(metadata(i)['confidence'] as num?)?.toStringAsFixed(1) ?? '?'}% confidence"),
              if (metadata(i)['quality'] != null)
                Text((metadata(i)['quality'] as Map)['passed'] == true
                    ? 'Image quality passed'
                    : "Quality warning: ${(metadata(i)['quality'] as Map)['reason']}"),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            SectionCard(
              title: 'Detected Fabric',
              icon: Icons.texture_outlined,
              child: Text(
                  '${result.fabricType} · ${result.confidencePercent}% confidence'),
            ),
            SectionCard(
              title: 'Damage Detection',
              icon: Icons.broken_image_outlined,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (damage.isEmpty)
                      const Text(
                          'No visible damage detected. Unphotographed damage may be missed.'),
                    for (final item in damage)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.label),
                        subtitle: Text(
                            '${item.view} · image ${item.imageIndex + 1} · ${item.confidencePercent}% confidence\n${item.severity ?? item.statusLabel} · ${(item.areaRatio * 100).toStringAsFixed(1)}% image area'),
                      ),
                  ]),
            ),
            if (result.hasHealthAssessment)
              SectionCard(
                  title: 'Fabric Health',
                  icon: Icons.favorite_outline,
                  child: Text(
                      '${result.healthScore}/100 · ${result.healthRating}\n${result.healthStatusNote}')),
            SectionCard(
                title: 'Remaining Lifespan Estimate',
                icon: Icons.hourglass_bottom,
                child: Text(
                    '${result.lifespanRange}\n${result.usageStatus}\nRule-based estimate, not a validated prediction.')),
            if (result.analysis['projected_condition_after_6_months'] != null)
              SectionCard(
                  title: 'Six Month Condition Estimate',
                  icon: Icons.timeline,
                  child: Text(
                      "${(result.analysis['projected_condition_after_6_months'] as Map)['health_score']}/100 · ${(result.analysis['projected_condition_after_6_months'] as Map)['condition_rating']}\nRule-based estimate, not a validated prediction.")),
            SectionCard(
                title: 'Care Recommendation',
                icon: Icons.local_laundry_service_outlined,
                child: Text(result.healthRecommendation ?? result.washMethod)),
            SectionCard(
                title: 'Care Details',
                icon: Icons.checkroom_outlined,
                child: Column(children: [
                  LabelRow(
                      icon: Icons.air, label: 'Dry', value: result.dryMethod),
                  LabelRow(
                      icon: Icons.iron, label: 'Iron', value: result.ironLevel),
                  LabelRow(
                      icon: Icons.block,
                      label: 'Bleach',
                      value: result.bleachWarning),
                  LabelRow(
                      icon: Icons.science,
                      label: 'Detergent',
                      value: result.detergentSuggestion),
                  LabelRow(
                      icon: Icons.inventory_2,
                      label: 'Storage',
                      value: result.storageTip),
                ])),
            for (final warning in result.riskWarnings)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(warning)),
            OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ScanScreen())),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan another garment')),
          ],
        ),
      ),
    );
  }
}
