import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/damage_detection.dart';
import '../../models/scan_result.dart';
import '../../services/damage_detector.dart';
import '../../services/health_score_calculator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/damage_card.dart';
import '../../widgets/fabric_thumb.dart';
import '../../widgets/section_card.dart';
import '../home/home_shell.dart';
import 'scan_screen.dart';

class ScanResultScreen extends StatefulWidget {
  final ScanResult result;

  const ScanResultScreen({super.key, required this.result});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late ScanResult _result;
  DamageDetectionResult? _damage;
  Set<String> _confirmed = {};
  bool _isAnalyzingDamage = false;
  bool _healthCalculated = false;
  final _damageSectionKey = GlobalKey();
  final _healthSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _result = widget.result;
    _damage = _result.damageDetection;
    _confirmed = Set.from(_result.confirmedDamageIds);
    _healthCalculated = _result.hasHealthAssessment;

    if (_damage != null && _confirmed.isEmpty) {
      _confirmed = _damage!.defaultConfirmedIds;
    }
  }

  bool get _damageModelReady => DamageDetector.instance.isReady;

  Future<void> _showError(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _analyzeDamage() async {
    if (_result.image == null || _isAnalyzingDamage) return;

    if (!_damageModelReady) {
      final detector = DamageDetector.instance;
      final message = detector.loadError != null
          ? 'The FabriCare API is not reachable.\n\n${detector.loadError}'
          : 'Damage detection runs through the FabriCare API. Start fabricare_api.py first.';
      await _showError('API unavailable', message);
      return;
    }

    setState(() {
      _isAnalyzingDamage = true;
      _healthCalculated = false;
    });

    try {
      final detection = await DamageDetector.instance.analyze(_result.image!);
      if (!mounted) return;

      setState(() {
        _damage = detection;
        _confirmed = detection.defaultConfirmedIds;
        _isAnalyzingDamage = false;
      });

      _scrollTo(_damageSectionKey);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzingDamage = false);
      await _showError('Damage analysis failed', e.toString());
    }
  }

  void _toggleConfirmed(String id) {
    setState(() {
      if (_confirmed.contains(id)) {
        _confirmed.remove(id);
      } else {
        _confirmed.add(id);
      }
      _healthCalculated = false;
    });
  }

  void _calculateHealthScore() {
    if (_damage == null) return;

    final assessment = HealthScoreCalculator.calculate(
      scan: _result,
      damage: _damage!,
      confirmedIds: _confirmed,
    );

    final updated = _result.copyWith(
      damageDetection: _damage,
      confirmedDamageIds: _confirmed,
      healthScore: assessment.healthScore,
      lifespanRange: assessment.lifespanRange,
      careWarning: assessment.careWarning,
      healthRecommendation: assessment.recommendation,
    );

    AppData.instance.updateScanResult(updated);

    setState(() {
      _result = updated;
      _healthCalculated = true;
    });

    _scrollTo(_healthSectionKey);
  }

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _retakePhoto() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FabriCare Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Back to Home',
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeShell()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _FlowStepper(
              currentStep: _healthCalculated
                  ? 4
                  : (_isAnalyzingDamage
                      ? 2
                      : (_damage != null ? 3 : 1)),
            ),
            const SizedBox(height: 18),

            // 1. Fabric image
            Center(
              child: FabricThumb(
                image: _result.image,
                fabricType: _result.fabricType,
                size: 160,
                radius: 20,
              ),
            ),
            const SizedBox(height: 20),

            // 2. Fabric identification
            SectionCard(
              title: 'Detected Fabric',
              icon: Icons.texture_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _result.fabricType,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.coral),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Confidence: ${_result.confidencePercent}%',
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _retakePhoto,
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Retake Photo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_result.image != null && !_isAnalyzingDamage)
                              ? _analyzeDamage
                              : null,
                          icon: _isAnalyzingDamage
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(
                                  _damageModelReady ? Icons.search_rounded : Icons.error_outline_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _damage == null
                                ? (_damageModelReady ? 'Analyze Damage' : 'API offline')
                                : 'Re-analyze',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isAnalyzingDamage)
              SectionCard(
                title: 'Running YOLO Damage Model',
                icon: Icons.memory_rounded,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'YOLO model is analyzing ${_result.fabricType.toLowerCase()} fabric via API…',
                        style: const TextStyle(fontSize: 13.5, color: AppColors.inkSoft, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Damage detection section
            if (_damage != null && !_isAnalyzingDamage) ...[
              SectionCard(
                key: _damageSectionKey,
                title: 'Fabric Damage Detection',
                icon: Icons.broken_image_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConfidenceLegend(),
                    const SizedBox(height: 14),
                    DamageCard.fromItem(
                      item: _damage!.stain,
                      confirmed: _confirmed.contains('stain'),
                      onConfirmToggle: _damage!.stain.isConfirmable
                          ? () => _toggleConfirmed('stain')
                          : null,
                    ),
                    DamageCard.fromItem(
                      item: _damage!.pilling,
                      confirmed: _confirmed.contains('pilling'),
                      onConfirmToggle: _damage!.pilling.isConfirmable
                          ? () => _toggleConfirmed('pilling')
                          : null,
                    ),
                    DamageCard.fiberDamage(
                      hole: _damage!.hole,
                      needlemark: _damage!.needlemark,
                      holeConfirmed: _confirmed.contains('hole'),
                      needlemarkConfirmed: _confirmed.contains('needlemark'),
                      onHoleToggle: _damage!.hole.isConfirmable
                          ? () => _toggleConfirmed('hole')
                          : null,
                      onNeedlemarkToggle: _damage!.needlemark.isConfirmable
                          ? () => _toggleConfirmed('needlemark')
                          : null,
                    ),
                  ],
                ),
              ),

              // 4. User confirmation checklist
              SectionCard(
                title: 'Confirm Detected Damages',
                icon: Icons.fact_check_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please confirm the detected damages before calculating the fabric health score.',
                      style: TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    for (final item in _damage!.allItems)
                      _ConfirmationCheckbox(
                        label: item.label,
                        subtitle: '${item.statusLabel}${item.status != DamageStatus.notDetected ? ', ${item.confidencePercent}%' : ''}',
                        checked: _confirmed.contains(item.id),
                        enabled: item.isConfirmable,
                        onChanged: item.isConfirmable ? () => _toggleConfirmed(item.id) : null,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _calculateHealthScore,
                      icon: const Icon(Icons.favorite_rounded, size: 18),
                      label: const Text('Calculate Fabric Health Score'),
                    ),
                  ],
                ),
              ),
            ],

            // 5–8. Health score, condition, lifespan, care (after confirmation)
            if (_healthCalculated && _result.hasHealthAssessment) ...[
              SectionCard(
                key: _healthSectionKey,
                title: 'Fabric Health Score',
                icon: Icons.favorite_rounded,
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _result.healthScore! / 100,
                            strokeWidth: 6,
                            backgroundColor: AppColors.border,
                            color: severityColor(_result.healthRating),
                          ),
                          Text(
                            '${_result.healthScore}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_result.healthScore}/100',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          SeverityBadge(label: _result.healthRating),
                          const SizedBox(height: 6),
                          Text(
                            _result.healthStatusNote,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SectionCard(
                title: 'Condition Rating',
                icon: Icons.grade_outlined,
                child: Row(
                  children: [
                    SeverityBadge(label: _result.healthRating),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _confirmed.isEmpty
                            ? 'No damages confirmed — fabric is in good shape.'
                            : 'Based on ${_confirmed.length} confirmed condition${_confirmed.length == 1 ? '' : 's'}.',
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),

              SectionCard(
                title: 'Estimated Remaining Lifespan',
                icon: Icons.hourglass_bottom_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _result.lifespanRange,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result.usageStatus,
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),

              if (_result.careWarning != null)
                SectionCard(
                  title: 'Care Warning',
                  icon: Icons.warning_amber_rounded,
                  child: Text(
                    _result.careWarning!,
                    style: const TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ),

              SectionCard(
                title: 'Recommendation',
                icon: Icons.lightbulb_outline_rounded,
                child: Text(
                  _result.healthRecommendation ?? _result.washMethod,
                  style: const TextStyle(fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w600),
                ),
              ),

              SectionCard(
                title: 'Care Details',
                icon: Icons.local_laundry_service_outlined,
                child: Column(
                  children: [
                    LabelRow(icon: Icons.local_laundry_service_outlined, label: 'Wash', value: _result.washMethod),
                    LabelRow(icon: Icons.air_rounded, label: 'Dry', value: _result.dryMethod),
                    LabelRow(icon: Icons.iron_outlined, label: 'Iron', value: _result.ironLevel),
                    LabelRow(icon: Icons.block_rounded, label: 'Bleach', value: _result.bleachWarning),
                    LabelRow(icon: Icons.science_outlined, label: 'Detergent', value: _result.detergentSuggestion),
                    LabelRow(icon: Icons.inventory_2_outlined, label: 'Storage', value: _result.storageTip),
                  ],
                ),
              ),

              if (_result.riskWarnings.isNotEmpty)
                SectionCard(
                  title: 'Care Risk Warnings',
                  icon: Icons.error_outline_rounded,
                  child: Column(
                    children: _result.riskWarnings
                        .map(
                          (w) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                                const SizedBox(width: 8),
                                Expanded(child: Text(w, style: const TextStyle(fontSize: 12.5, height: 1.35))),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],

            if (!_healthCalculated && _damage == null && !_isAnalyzingDamage)
              SectionCard(
                title: 'Next Step',
                icon: Icons.arrow_downward_rounded,
                child: Text(
                  _damageModelReady
                      ? 'Fabric identified successfully. Tap Analyze Damage to review YOLO detection results before calculating health score.'
                      : 'Fabric identified successfully. Damage detection requires the FabriCare API — start fabricare_api.py on your computer.',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.45),
                ),
              ),

            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeShell()),
                (route) => false,
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(_healthCalculated ? 'Saved to Scan History' : 'Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowStepper extends StatelessWidget {
  final int currentStep;

  const _FlowStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Fabric ID', 'Damage', 'Confirm', 'Health'];
    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i + 1 <= currentStep ? AppColors.coral : AppColors.surfaceMuted,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: i + 1 <= currentStep ? Colors.white : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i + 1 == currentStep ? FontWeight.w700 : FontWeight.w500,
                    color: i + 1 <= currentStep ? AppColors.ink : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (i != steps.length - 1)
            Container(
              width: 12,
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
              color: i + 1 < currentStep ? AppColors.coral : AppColors.border,
            ),
        ],
      ],
    );
  }
}

class _ConfidenceLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confidence rules', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          SizedBox(height: 6),
          Text('80% and above = Detected', style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
          Text('60%–79% = Possible / Needs confirmation', style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
          Text('Below 60% = Not detected', style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _ConfirmationCheckbox extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool checked;
  final bool enabled;
  final VoidCallback? onChanged;

  const _ConfirmationCheckbox({
    required this.label,
    required this.subtitle,
    required this.checked,
    required this.enabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onChanged : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: checked ? AppColors.sage : AppColors.inkSoft,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
