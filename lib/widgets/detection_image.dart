import 'package:flutter/material.dart';
import '../models/scan_result.dart';

/// Boxes are normalized to the exact displayed image frame (no cropping).
class DetectionImage extends StatelessWidget {
  final ScanResult scan;
  final int imageIndex;
  const DetectionImage(
      {super.key, required this.scan, required this.imageIndex});

  @override
  Widget build(BuildContext context) {
    final predictions = scan.analysis['per_image'] as List? ?? [];
    final metadata = imageIndex < predictions.length
        ? predictions[imageIndex] as Map
        : const {};
    final width = (metadata['width'] as num? ?? 1).toDouble();
    final height = (metadata['height'] as num? ?? 1).toDouble();
    final items = scan.damageDetection.items
        .where((i) => i.imageIndex == imageIndex && i.bbox.length == 4);
    return AspectRatio(
      aspectRatio: width / height,
      child: LayoutBuilder(
          builder: (context, constraints) =>
              Stack(fit: StackFit.expand, children: [
                Image.file(scan.images[imageIndex].file,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Text('Saved photo unavailable'))),
                for (final item in items)
                  Positioned(
                      left: item.bbox[0] * constraints.maxWidth,
                      top: item.bbox[1] * constraints.maxHeight,
                      width: item.bbox[2] * constraints.maxWidth,
                      height: item.bbox[3] * constraints.maxHeight,
                      child: IgnorePointer(
                          child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.error,
                                width: 2)),
                        alignment: Alignment.topLeft,
                        child: Text(item.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onError,
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                fontSize: 11)),
                      ))),
              ])),
    );
  }
}
