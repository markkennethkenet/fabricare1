import unittest
from unittest.mock import patch

import database


class DatabaseTlsTests(unittest.TestCase):
    def test_hosted_connection_verifies_certificate_and_hostname(self):
        with patch.multiple(database.DbConfig, host='mysql.example.aivencloud.com',
                            ssl_ca='/configured/ca.pem', ssl_ca_pem=''), \
                patch.object(database.mysql.connector, 'connect') as connect:
            database._connect()
        options = connect.call_args.kwargs
        self.assertEqual(options['ssl_ca'], '/configured/ca.pem')
        self.assertTrue(options['ssl_verify_cert'])
        self.assertTrue(options['ssl_verify_identity'])
        self.assertFalse(options['ssl_disabled'])

    def test_aiven_without_ca_fails_before_network_connection(self):
        with patch.multiple(database.DbConfig, host='mysql.example.aivencloud.com',
                            ssl_ca='', ssl_ca_pem=''), \
                patch.object(database.mysql.connector, 'connect') as connect:
            with self.assertRaisesRegex(ValueError, 'TLS verification'):
                database._connect()
        connect.assert_not_called()

    def test_local_connection_without_ca_preserves_existing_configuration(self):
        with patch.multiple(database.DbConfig, host='127.0.0.1', ssl_ca='', ssl_ca_pem=''), \
                patch.object(database.mysql.connector, 'connect') as connect:
            database._connect(use_database=False)
        self.assertNotIn('ssl_ca', connect.call_args.kwargs)
        self.assertNotIn('database', connect.call_args.kwargs)


if __name__ == '__main__':
    unittest.main()
