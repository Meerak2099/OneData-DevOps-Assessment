import unittest
from app.main import health_check

class TestHealthCheck(unittest.TestCase):

    def test_health_check(self):
        response = health_check()
        self.assertEqual(response, {"status": "healthy"})

    def test_health_check_empty(self):
        response = health_check()
        self.assertIsInstance(response, dict)

    def test_health_check_status_key(self):
        response = health_check()
        self.assertIn("status", response)

if __name__ == '__main__':
    unittest.main()