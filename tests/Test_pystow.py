#!/bin/env python3
import unittest
import __init__
import tools.pystow as pystow
class TestMethods(unittest.TestCase):
    def setUp(self):
        pass

    def test_parse_home(self):
        f = pystow.parse_home
        import os
        home = "~/test/path/to/destination"
        path = os.getenv("HOME")
        expected = path + home[1:]
        actual = f(home)
        self.assertEqual(expected, actual)

    def test_package_filtering(self):
        pkgs=["test",".git","one","two","hello"]
        exclude=[".git","hello"]
        actual = list(pystow.filter_packages(pkgs, exclude))
        expected = ["test","one","two"]
        self.assertListEqual(actual, expected)

    def test_empty_packages(self):
        with self.assertRaises(RuntimeError):
            list(pystow.filter_packages())
        with self.assertRaises(RuntimeError):
            list(pystow.filter_packages(pkgs=[]))

    def test_building_args(self):
        pass

    def test_parsing_path(self):
        import os

        paths = [
                "~",
                "~/test",
                "path/relative",
                ]
        home_path = os.getenv("HOME")
        expected = [
                home_path,
                home_path + "/test",
                os.path.realpath("path/relative"),
                ]
        self.assertEqual(len(paths),len(expected))
        for i,p in enumerate(paths):
            actual = pystow.build_path(p, check_valid=False)
            expect = expected[i]
            msg = "Parsing of {} failed, got {}".format(p,expect)
            self.assertEqual(actual, expect, msg)

    def test_parsing_path_invalid(self):
        paths = [
                "~/thisdoesnotexist",
                "/~invalid",
                "~~",
                "invalidpath/",
                ]
        for p in paths:
            self.assertRaises(NotADirectoryError, pystow.build_path, p)


if __name__ == "__main__":
    unittest.main()
