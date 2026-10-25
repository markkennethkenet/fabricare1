"""API contract tests use fake inference; production model files are never loaded."""
import io
import json
import importlib
import unittest
from unittest.mock import patch, MagicMock
import cv2
import numpy as np

class ApiContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Patch inference construction before importing the Flask application.
        with patch('joblib.load'), patch('ultralytics.YOLO'):
            cls.api = importlib.import_module('fabricare_api')
        cls.client = cls.api.app.test_client()

    def setUp(self):
        self.fabric = patch.object(self.api, 'classify_fabric', return_value={
            'fabric_type': 'future_fabric', 'confidence': 85,
            'probabilities': {'future_fabric': .85, 'other': .15}})
        self.damage = patch.object(self.api, 'detect_damage', return_value=[])
        self.fabric_mock = self.fabric.start()
        self.damage.start()
        self.addCleanup(self.fabric.stop)
        self.addCleanup(self.damage.stop)

    def photo(self, dark=False):
        image = np.zeros((100, 100, 3), dtype=np.uint8) if dark else np.random.default_rng(7).integers(50, 200, (100, 100, 3), dtype=np.uint8)
        return io.BytesIO(cv2.imencode('.png', image)[1].tobytes()), 'photo.png'

    def test_legacy_single_image_including_low_quality(self):
        response = self.client.post('/analyze', data={'image': self.photo(dark=True)})
        self.assertEqual(response.status_code, 200)
        body = response.get_json()
        self.assertEqual(body['fabric_type'], 'future_fabric')
        self.assertIn('estimated_lifespan', body)
        self.assertIn('care_recommendation', body)
        self.assertEqual(body['per_image'][0]['view'], 'front')
        self.assertTrue(body['quality_override'])

    def test_multiple_images_and_per_image_predictions(self):
        response = self.client.post('/analyze', data={'images': [self.photo(), self.photo()], 'views': '["front", "back"]'})
        self.assertEqual(response.status_code, 200)
        body = response.get_json()
        self.assertEqual(len(body['per_image']), 2)
        self.assertEqual(body['per_image'][1]['view'], 'back')
        self.assertEqual(body['per_image'][1]['fabric_type'], 'future_fabric')
        self.assertNotIn('path', body['per_image'][0])
        self.assertEqual(self.fabric_mock.call_count, 2)

    def test_quality_preflight_and_explicit_override(self):
        result = self.client.post('/quality', data={'images': [self.photo(True)], 'views': '["front"]'})
        self.assertEqual(result.status_code, 200)
        self.assertFalse(result.get_json()['per_image'][0]['quality']['passed'])
        self.fabric_mock.assert_not_called()
        response = self.client.post('/analyze', data={'images': [self.photo(True)], 'views': '["front"]'})
        self.assertEqual(response.status_code, 422)
        self.fabric_mock.assert_not_called()
        override = self.client.post('/analyze', data={'images': [self.photo(True)], 'views': '["front"]', 'allow_low_quality': 'true'})
        self.assertEqual(override.status_code, 200)

    def test_bad_inputs(self):
        self.assertEqual(self.client.post('/analyze').status_code, 400)
        self.assertEqual(self.client.post('/analyze', data={'image': (io.BytesIO(b'not an image'), 'bad.jpg')}).status_code, 400)
        self.assertEqual(self.client.post('/analyze', data={'images': [self.photo()], 'views': '["back"]'}).status_code, 400)
        self.assertEqual(self.client.post('/analyze', data={'images': [self.photo()], 'views': 'oops'}).status_code, 400)
        self.assertEqual(self.client.post('/analyze', data={'images': [self.photo(), self.photo()], 'views': '["front", "front"]'}).status_code, 400)

    def test_upload_limit_returns_json_413(self):
        with patch.dict(self.api.app.config, MAX_CONTENT_LENGTH=10):
            response = self.client.post('/analyze', data={'image': self.photo()})
        self.assertEqual(response.status_code, 413)
        self.assertIn('error', response.get_json())

    def test_readiness_requires_database_and_hides_connection_details(self):
        with patch.object(self.api, 'ping_database', return_value=True):
            response = self.client.get('/health/ready')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.get_json()['ready'])
        with patch.object(self.api, 'ping_database', side_effect=RuntimeError('private details')):
            response = self.client.get('/health/ready')
            health = self.client.get('/')
        self.assertEqual(response.status_code, 503)
        self.assertFalse(response.get_json()['ready'])
        self.assertNotIn('private', health.get_data(as_text=True))

    def test_browser_auth_preflight_allows_local_flutter_origin(self):
        response = self.client.options('/auth/register', headers={
            'Origin': 'http://localhost:50552',
            'Access-Control-Request-Method': 'POST',
            'Access-Control-Request-Headers': 'content-type',
        })
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers['Access-Control-Allow-Origin'], 'http://localhost:50552')
        self.assertIn('POST', response.headers['Access-Control-Allow-Methods'])

    def test_garment_inputs_are_validated_and_returned(self):
        inputs = {'condition': 'previously_used', 'use_frequency': 'daily',
                  'washing_frequency': 'weekly', 'purchase_date_known': False}
        response = self.client.post('/analyze', data={'image': self.photo(), 'user_inputs': json.dumps(inputs)})
        self.assertEqual(response.status_code, 200)
        body = response.get_json()
        self.assertEqual(body['user_inputs']['use_frequency'], 'daily')
        self.assertIn('projected_condition_after_6_months', body)
        self.assertIn('daily', body['usage_status'])
        bad = self.client.post('/analyze', data={'image': self.photo(), 'user_inputs': '{bad'})
        self.assertEqual(bad.status_code, 400)
        self.fabric_mock.reset_mock()
        missing_date = self.client.post('/analyze', data={'image': self.photo(), 'user_inputs':
            json.dumps({'condition': 'previously_used', 'purchase_date_known': True})})
        self.assertEqual(missing_date.status_code, 400)
        self.fabric_mock.assert_not_called()

    def test_detection_geometry_and_severity_independent_of_confidence(self):
        box = MagicMock()
        box.xyxy = [MagicMock()]
        box.xyxy[0].tolist.return_value = [10, 10, 20, 20]
        box.cls.item.return_value = 0
        box.conf.item.return_value = .99
        result = MagicMock(orig_shape=(100, 100), boxes=[box])
        with patch.object(self.api, 'damage_model') as model:
            model.predict.return_value = [result]
            model.names = {0: 'future_damage'}
            # detect_damage itself is not stubbed for this test.
            self.damage.stop()
            output = self.api.detect_damage('ignored', 1, 'back')[0]
        self.assertEqual(output['severity'], 'minor')
        self.assertAlmostEqual(output['area_ratio'], .01)
        self.assertEqual(output['bbox'], [.1, .1, .1, .1])
        self.assertEqual(output['view'], 'back')

if __name__ == '__main__':
    unittest.main()
