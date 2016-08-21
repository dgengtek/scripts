#!/bin/env python3
import unittest
import __init__
class TestMethods(unittest.TestCase):
    def setUp(self):
        pass
    def tearDown(self):
        pass
    def test_one(self):
        self.assertEqual(True,True)
    def test_two(self):
        self.assertEqual(True,True)
    def suite():
        suite = unittest.TestSuite()
        suite.addTest(TestMethods())
        #suite.addTest(TestCase1())
        #suite.addTest(TestCase2())
        return suite

if __name__ == "__main__":
    unittest.main()
