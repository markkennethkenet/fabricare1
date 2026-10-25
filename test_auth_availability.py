"""Account routes must report database outages without leaking credentials."""
import unittest
from unittest.mock import patch

from flask import Flask
from mysql.connector import Error

from auth_routes import auth_bp


class AuthAvailabilityTests(unittest.TestCase):
    def setUp(self):
        app = Flask(__name__)
        app.register_blueprint(auth_bp)
        self.client = app.test_client()

    def test_database_outage_returns_safe_json_for_login_and_register(self):
        for route in ('login', 'register'):
            with self.subTest(route=route), patch(
                'auth_routes.get_connection',
                side_effect=Error('private database connection details', errno=2003),
            ):
                response = self.client.post('/auth/' + route, json={
                    'full_name': 'Test User', 'email': 'test@example.com',
                    'password': 'test-password',
                })
                self.assertEqual(response.status_code, 503)
                self.assertIn('Account service', response.get_json()['error'])
                self.assertNotIn('private', response.get_data(as_text=True))

    def test_missing_fields_still_return_validation_error(self):
        for route in ('login', 'register'):
            response = self.client.post('/auth/' + route, json={})
            self.assertEqual(response.status_code, 400)


if __name__ == '__main__':
    unittest.main()
