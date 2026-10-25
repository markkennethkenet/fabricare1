import unittest
import numpy as np
from image_processing import quality_for, merge_detections, aggregate_fabrics

class ImageProcessingTests(unittest.TestCase):
    def test_quality_dark_bright_blurry_and_clear(self):
        self.assertIn('Too dark', quality_for(np.zeros((50, 50, 3), dtype=np.uint8))['reason'])
        self.assertIn('Too bright', quality_for(np.full((50, 50, 3), 255, dtype=np.uint8))['reason'])
        self.assertIn('blurry', quality_for(np.full((50, 50, 3), 120, dtype=np.uint8))['reason'])
        image = np.random.default_rng(7).integers(50, 200, (100, 100, 3), dtype=np.uint8)
        self.assertTrue(quality_for(image)['passed'])

    def test_merge_same_image_only(self):
        def item(id, kind='future_class', image=0, bbox=None, confidence=90):
            return {'id': id, 'type': kind, 'image_index': image, 'view': 'front',
                    'bbox': bbox or [.1, .1, .2, .2], 'confidence': confidence}
        detections = [item('0:0'), item('0:1', confidence=80), item('1:0', image=1),
                      item('0:2', kind='other'), item('0:3', bbox=[.7, .7, .1, .1])]
        merged = merge_detections(detections)
        self.assertEqual({d['id'] for d in merged}, {'0:0', '1:0', '0:2', '0:3'})
        self.assertEqual(merge_detections([]), [])

    def test_probability_aggregation_and_vote_fallback(self):
        result = aggregate_fabrics([{'probabilities': {'a': .8, 'b': .2}},
                                   {'probabilities': {'a': .4, 'b': .6}}])
        self.assertEqual(result['fabric_type'], 'a')
        self.assertEqual(result['fabric_confidence'], 60)
        voted = aggregate_fabrics([{'probabilities': {'new_class': 1}},
                                  {'probabilities': {'new_class': 1}}, {'probabilities': {'other': 1}}])
        self.assertEqual(voted['fabric_type'], 'new_class')
        self.assertAlmostEqual(voted['fabric_confidence'], 66.67)

if __name__ == '__main__':
    unittest.main()
