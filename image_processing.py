"""Image quality and per-image detection deduplication; no training involved."""
import cv2
from assessment import CONFIG


def quality_for(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blur = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    brightness = float(gray.mean())
    policy = CONFIG['quality']
    reasons = []
    if blur < policy['minimum_blur_score']:
        reasons.append('Image is blurry, hold steady')
    if brightness < policy['minimum_brightness']:
        reasons.append('Too dark, move to better light')
    if brightness > policy['maximum_brightness']:
        reasons.append('Too bright, avoid direct glare')
    return {'blur_score': round(blur, 2), 'brightness': round(brightness, 2),
            'passed': not reasons, 'reason': '. '.join(reasons)}


def box_iou(a, b):
    x = max(a[0], b[0])
    y = max(a[1], b[1])
    width = max(0, min(a[0] + a[2], b[0] + b[2]) - x)
    height = max(0, min(a[1] + a[3], b[1] + b[3]) - y)
    intersection = width * height
    union = a[2] * a[3] + b[2] * b[3] - intersection
    return intersection / union if union > 0 else 0


def merge_detections(detections):
    """NMS: keep highest confidence same-type box per overlapping region in ONE image.

    Different views/images are never merged: 2D coordinates cannot establish
    cross-view identity. Scores may therefore count the same physical defect twice.
    """
    kept = []
    for detection in sorted(detections, key=lambda d: d['confidence'], reverse=True):
        duplicate = any(detection['image_index'] == old['image_index']
                        and detection['type'] == old['type']
                        and box_iou(detection['bbox'], old['bbox']) >= CONFIG['detection']['merge_iou']
                        for old in kept)
        if not duplicate:
            kept.append(detection)
    return sorted(kept, key=lambda d: (d['image_index'], d['id']))


def aggregate_fabrics(predictions):
    """Average per-class probabilities equally across supplied images.

    If a classifier has no predict_proba, each image supplies a one-hot vote.
    Labels come from model/config metadata, never a fixed client class list.
    """
    labels = sorted({label for prediction in predictions for label in prediction['probabilities']})
    averages = {label: sum(p['probabilities'].get(label, 0) for p in predictions) / len(predictions)
                for label in labels}
    winner = max(averages, key=averages.get)
    return {'fabric_type': winner, 'fabric_confidence': round(averages[winner] * 100, 2),
            'fabric_probabilities': averages}
