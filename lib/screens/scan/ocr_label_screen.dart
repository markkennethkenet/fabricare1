import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_card.dart';

class OcrLabelScreen extends StatefulWidget {
  const OcrLabelScreen({super.key});

  @override
  State<OcrLabelScreen> createState() => _OcrLabelScreenState();
}

class _OcrLabelScreenState extends State<OcrLabelScreen> {
  File? _image;
  bool _scanning = false;
  bool _done = false;
  final _picker = ImagePicker();

  // Mock OCR output — replace with a real text-recognition call later.
  final _mockLabelText = 'Machine wash cold\nDo not bleach\nTumble dry low\nIron low heat\nDo not dry clean';
  final _mockSymbols = const ['Machine wash, cold (30°C)', 'Do not bleach', 'Tumble dry, low heat', 'Iron, low heat', 'Do not dry clean'];

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _scanning = true;
      _done = false;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
      _scanning = false;
      _done = true;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Care Label')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: _image == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.label_outline_rounded, size: 56, color: AppColors.inkSoft),
                          SizedBox(height: 10),
                          Text('Capture the garment\'s care label', style: TextStyle(color: AppColors.inkSoft)),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_image!, fit: BoxFit.cover),
                        if (_scanning)
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Capture Label'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Upload'),
                  ),
                ),
              ],
            ),
            if (_done) ...[
              const SizedBox(height: 22),
              SectionCard(
                title: 'Detected Label Text',
                icon: Icons.text_snippet_outlined,
                child: Text(_mockLabelText, style: const TextStyle(fontSize: 13, height: 1.6)),
              ),
              SectionCard(
                title: 'Washing Symbols',
                icon: Icons.checklist_rtl_rounded,
                child: Column(
                  children: _mockSymbols
                      .map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.sage),
                                const SizedBox(width: 8),
                                Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SectionCard(
                title: 'Label vs. AI Recommendation',
                icon: Icons.compare_arrows_rounded,
                child: Text(
                  'Good news — the manufacturer\'s label matches our AI care recommendation for this fabric type. '
                  'Follow the label instructions above for best results.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
