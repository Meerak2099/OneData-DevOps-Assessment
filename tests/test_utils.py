import unittest

def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

class TestUtils(unittest.TestCase):

    def test_add(self):
        self.assertEqual(add(1, 2), 3)
        self.assertEqual(add(-1, 1), 0)
        self.assertEqual(add(-1, -1), -2)

    def test_subtract(self):
        self.assertEqual(subtract(2, 1), 1)
        self.assertEqual(subtract(1, 1), 0)
        self.assertEqual(subtract(-1, -1), 0)

    def test_add_negative(self):
        self.assertEqual(add(-5, -5), -10)
        self.assertEqual(add(5, -3), 2)