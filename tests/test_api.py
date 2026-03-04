import unittest
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import app

class ApiTests(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_get_endpoint(self):
        response = self.app.get('/api/endpoint')
        self.assertEqual(response.status_code, 200)
        self.assertIn('expected_key', response.get_json())

    def test_post_endpoint(self):
        response = self.app.post('/api/endpoint', json={'key': 'value'})
        self.assertEqual(response.status_code, 201)
        self.assertIn('expected_key', response.get_json())

    def test_invalid_endpoint(self):
        response = self.app.get('/api/invalid_endpoint')
        self.assertEqual(response.status_code, 404)

if __name__ == '__main__':
    unittest.main()