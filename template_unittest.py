#!/bin/env python3
import unittest
class TestMethods(unittest.TestCase):
    def test_one(self):
        self.assertEqual(True,True)
    def test_two(self):
        self.assertEqual(True,True)

if __name__ == "__main__":
    unittest.main()
