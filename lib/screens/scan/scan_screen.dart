import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/mock_data.dart';
import '../../services/fabric_classifier.dart';
import '../../theme/app_theme.dart';
import '../home/home_shell.dart';
import 'ocr_label_screen.dart';
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _AnalyzeState { idle, classifying, done }

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  _AnalyzeState _analyzing = _AnalyzeState.idle;
  String? _classifyStatus;
  final _picker = ImagePicker();

  bool get _modelReady => FabricClassifier.instance.isReady;

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _image = File(picked.path);
        _analyzing = _AnalyzeState.idle;
        _classifyStatus = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access camera/gallery on this device.')),
        );
      }
    }
  }

  void _retake() {
    setState(() {
      _image = null;
      _analyzing = _AnalyzeState.idle;
      _classifyStatus = null;
    });
  }

  String _formatFabricLabel(String label) {
    if (label.isEmpty) return label;
    return label[0].toUpperCase() + label.substring(1);
  }

  Future<void> _showError(String title, String message) async {
    if (!mounted) return;
    setState(() {
      _analyzing = _AnalyzeState.idle;
      _classifyStatus = null;
    });
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

  Future<void> _analyze() async {
    if (_image == null) return;

    final classifier = FabricClassifier.instance;
    if (!classifier.isReady) {
      final message = classifier.loadError != null
          ? 'The FabriCare API is not reachable.\n\n${classifier.loadError}\n\nStart fabricare_api.py on your computer first.'
          : 'The FabriCare API is not ready. Start fabricare_api.py and try again.';
      await _showError('API unavailable', message);
      return;
    }

    setState(() {
      _analyzing = _AnalyzeState.classifying;
      _classifyStatus = 'Running GLCM fabric classifier…';
    });

    try {
      final result = await classifier.classify(_image!);
      final scanResult = AppData.instance.buildScanResultFromClassification(
        image: _image!,
        fabricType: _formatFabricLabel(result.label),
        confidencePercent: result.confidencePercent.round(),
      );

      if (mounted) {
        setState(() => _analyzing = _AnalyzeState.done);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ScanResultScreen(result: scanResult)),
        );
      }
    } catch (e) {
      await _showError(
        'Classification failed',
        'Could not identify the fabric via the API.\n\n$e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnalyzing = _analyzing == _AnalyzeState.classifying;
    final canAnalyze = _image != null && _modelReady && !isAnalyzing;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _image != null
              ? Image.file(_image!, fit: BoxFit.cover)
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2B2B26), Color(0xFF15140F)],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.center_focus_weak_rounded, size: 72, color: Colors.white54),
                        SizedBox(height: 14),
                        Text(
                          'Tap the scan button to capture\na fabric photo',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Use clear, even lighting for best results',
                          style: TextStyle(color: Colors.white38, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),

          if (isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _classifyStatus ?? 'Analyzing…',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _glassCircle(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _glassPill(
                      icon: _modelReady ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      label: _modelReady ? 'API ready' : 'API offline',
                      onTap: _modelReady
                          ? null
                          : () => _showError(
                                'API unavailable',
                                FabricClassifier.instance.loadError != null
                                    ? 'The FabriCare API is not reachable.\n\n${FabricClassifier.instance.loadError}\n\nRun: python fabricare_api.py'
                                    : 'Start fabricare_api.py on your computer before scanning.',
                              ),
                    ),
                    const SizedBox(width: 8),
                    if (_image == null)
                      _glassPill(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Scan label',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OcrLabelScreen()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (_image != null && !_modelReady && !isAnalyzing)
            Positioned(
              left: 16,
              right: 16,
              bottom: 118,
              child: SafeArea(
                top: false,
                child: _qualityBanner(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.danger,
                  text: 'FabriCare API is offline. Start fabricare_api.py before scanning.',
                ),
              ),
            ),

          if (!isAnalyzing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Center(child: _bottomPill(canAnalyze: canAnalyze)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomPill({required bool canAnalyze}) {
    final children = _image == null
        ? [
            _pillButton(
              icon: Icons.home_rounded,
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeShell()),
                (route) => false,
              ),
            ),
            _pillButton(
              icon: Icons.center_focus_strong_rounded,
              highlighted: true,
              onTap: () => _pick(ImageSource.camera),
            ),
            _pillButton(
              icon: Icons.photo_library_outlined,
              onTap: () => _pick(ImageSource.gallery),
            ),
          ]
        : [
            _pillButton(icon: Icons.refresh_rounded, onTap: _retake),
            _pillButton(
              icon: Icons.search_rounded,
              highlighted: canAnalyze,
              onTap: canAnalyze ? _analyze : (_modelReady ? null : _analyze),
            ),
            _pillButton(
              icon: Icons.home_rounded,
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeShell()),
                (route) => false,
              ),
            ),
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(width: 18),
          ],
        ],
      ),
    );
  }

  Widget _pillButton({required IconData icon, required VoidCallback? onTap, bool highlighted = false}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted ? AppColors.mustard : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 24,
          color: onTap == null
              ? AppColors.inkSoft.withValues(alpha: 0.4)
              : (highlighted ? AppColors.ink : AppColors.ink.withValues(alpha: 0.8)),
        ),
      ),
    );
  }

  Widget _glassCircle({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _glassPill({required IconData icon, required String label, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _qualityBanner({required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
