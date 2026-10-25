import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/mock_data.dart';
import '../../models/scan_result.dart';
import '../../services/fabricare_api_service.dart';
import '../../widgets/section_card.dart';
import 'ocr_label_screen.dart';
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const _views = ['front', 'back', 'close_up'];
  final _images = <String, ScanImage>{};
  final _quality = <String, Map<String, dynamic>>{};
  final _picker = ImagePicker();
  bool _busy = false;
  String _status = '';
  String _condition = 'new';
  String _useFrequency = 'weekly';
  String _washingFrequency = 'weekly';
  bool _purchaseDateKnown = false;
  DateTime? _purchaseDate;

  Map<String, dynamic> get _userInputs => {
        'condition': _condition,
        'use_frequency': _useFrequency,
        'washing_frequency': _washingFrequency,
        'purchase_date_known': _purchaseDateKnown,
        'purchase_date': _purchaseDateKnown && _purchaseDate != null
            ? _purchaseDate!.toIso8601String().split('T').first
            : null,
      };

  Future<void> _pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _purchaseDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now());
    if (date != null && mounted) setState(() => _purchaseDate = date);
  }

  Widget _historyInputs() => SectionCard(
      title: 'Garment history',
      icon: Icons.history,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButtonFormField<String>(
            initialValue: _condition,
            decoration: const InputDecoration(labelText: 'Garment condition'),
            items: const [
              DropdownMenuItem(value: 'new', child: Text('New')),
              DropdownMenuItem(
                  value: 'previously_used', child: Text('Previously used'))
            ],
            onChanged: _busy ? null : (v) => setState(() => _condition = v!)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
            initialValue: _useFrequency,
            decoration: const InputDecoration(labelText: 'Frequency of use'),
            items: const [
              DropdownMenuItem(value: 'rarely', child: Text('Rarely')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(
                  value: 'several_times_a_week',
                  child: Text('Several times a week')),
              DropdownMenuItem(value: 'daily', child: Text('Daily'))
            ],
            onChanged:
                _busy ? null : (v) => setState(() => _useFrequency = v!)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
            initialValue: _washingFrequency,
            decoration: const InputDecoration(labelText: 'Washing frequency'),
            items: const [
              DropdownMenuItem(value: 'rarely', child: Text('Rarely')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(
                  value: 'multiple_per_week',
                  child: Text('Multiple times per week'))
            ],
            onChanged:
                _busy ? null : (v) => setState(() => _washingFrequency = v!)),
        CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I know the purchase date'),
            value: _purchaseDateKnown,
            onChanged: _busy
                ? null
                : (v) => setState(() => _purchaseDateKnown = v ?? false)),
        if (_purchaseDateKnown)
          OutlinedButton.icon(
              onPressed: _busy ? null : _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(_purchaseDate == null
                  ? 'Select purchase date'
                  : _purchaseDate!.toIso8601String().split('T').first)),
        const SizedBox(height: 8),
        const Text(
            'Lifespan and six-month condition are rule-based estimates, not validated predictions.'),
      ]));

  Future<void> _pick(String view, ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      if (photo == null || !mounted) return;
      setState(() {
        _images[view] = ScanImage(view: view, path: photo.path);
        _quality.remove(view);
      });
    } catch (_) {
      if (mounted) {
        _message('Could not access the camera or gallery. Try again.');
      }
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _analyze() async {
    if (_busy || !_images.containsKey('front')) return;
    if (_condition == 'previously_used' &&
        _purchaseDateKnown &&
        _purchaseDate == null) {
      _message('Select the known purchase date or mark it unknown.');
      return;
    }
    final accountId = AppData.instance.activeUserId;
    setState(() {
      _busy = true;
      _status = 'Checking image quality...';
    });
    try {
      final images = [
        for (final view in _views)
          if (_images.containsKey(view)) _images[view]!
      ];
      final api = FabricCareApiService.instance;
      final quality = await api.checkQuality(images);
      if (!mounted) return;
      setState(() {
        for (final entry in quality) {
          _quality[entry['view'] as String] =
              Map<String, dynamic>.from(entry['quality'] as Map);
        }
      });
      final failures = quality
          .where((q) => (q['quality'] as Map)['passed'] != true)
          .toList();
      var override = false;
      if (failures.isNotEmpty) {
        override = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                      title: const Text('Review photo quality'),
                      content: Text(failures
                          .map((q) =>
                              "${q['view']}: ${(q['quality'] as Map)['reason']}")
                          .join('\n\n')),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Retake photos')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Continue anyway')),
                      ],
                    )) ??
            false;
        if (!override || !mounted) return;
      }
      setState(() => _status = 'Analyzing fabric and visible damage...');
      final response = await api.analyzeImages(images,
          allowLowQuality: override, userInputs: _userInputs);
      final result = await AppData.instance.addAnalysis(images, response,
          userInputs: _userInputs, expectedUserId: accountId);
      if (!mounted) return;
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ScanResultScreen(result: result)));
    } catch (e) {
      if (mounted) _message('Could not complete the scan. $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan a Garment'), actions: [
          IconButton(
              tooltip: 'Scan care label',
              onPressed: _busy
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const OcrLabelScreen())),
              icon: const Icon(Icons.qr_code_scanner)),
        ]),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
              const Text(
                  'Capture the front, then add the back and a close-up for a more complete assessment.'),
              const SizedBox(height: 12),
              const Text(
                  'Use even lighting without glare. Front/back: approximately 30–50 cm, keeping the garment in frame. Close-up: approximately 10–15 cm; keep it sharp. Adjust distance to fit your garment.'),
              const SizedBox(height: 16),
              for (final view in _views)
                SectionCard(
                    title:
                        '${view.replaceAll('_', ' ')} · ${view == 'front' ? 'Required' : 'Optional, encouraged'}',
                    icon: Icons.camera_alt_outlined,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_images[view] != null) ...[
                            Image.file(File(_images[view]!.path),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.contain),
                            const SizedBox(height: 8),
                          ],
                          if (_quality[view] != null)
                            Text(_quality[view]!['passed'] == true
                                ? 'Quality check passed'
                                : _quality[view]!['reason'] as String),
                          Wrap(spacing: 8, children: [
                            OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _pick(view, ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: Text(_images[view] == null
                                    ? 'Capture'
                                    : 'Retake')),
                            TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _pick(view, ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Gallery')),
                            if (view != 'front' && _images[view] != null)
                              TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() {
                                            _images.remove(view);
                                            _quality.remove(view);
                                          }),
                                  child: const Text('Remove')),
                          ]),
                        ])),
              _historyInputs(),
              if (_busy) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(_status),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                  onPressed:
                      !_busy && _images.containsKey('front') ? _analyze : null,
                  icon: const Icon(Icons.search),
                  label: const Text('Analyze garment')),
            ])),
      );
}
