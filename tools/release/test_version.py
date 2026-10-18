import tempfile
import unittest
from pathlib import Path

from configure_signing import property_escape
from version import validate


class VersionTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for path in ["app/pubspec.yaml", "tools/6mwt_data_visualizer/pubspec.yaml"]:
            file = self.root / path
            file.parent.mkdir(parents=True)
            file.write_text("name: example\nversion: 1.2.3+7\n")

    def test_valid_tag_and_dry_run(self):
        self.assertEqual(validate(self.root, "v1.2.3"), ("1.2.3", "7"))
        self.assertEqual(validate(self.root), ("1.2.3", "7"))

    def test_invalid_or_mismatched_tag(self):
        for tag in [
            "v1.2.4",
            "1.2.3",
            "v01.2.3",
            "v1.2.3-beta",
            "v1.2.3+7",
            "v1.2.3\n",
        ]:
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                validate(self.root, tag)

    def test_different_packages_including_build_number(self):
        for value in ["1.2.4+7", "1.2.3+8"]:
            (self.root / "app/pubspec.yaml").write_text(f"version: {value}\n")
            with self.assertRaises(ValueError):
                validate(self.root)

    def test_missing_duplicate_or_invalid_version(self):
        for value in [
            "",
            "version: 1.2.3",
            "version: 1.2.3+0",
            "version: 1.2.3+01",
            "version: 1.2.3+7\nversion: 1.2.3+7",
        ]:
            (self.root / "app/pubspec.yaml").write_text(value)
            with self.subTest(value=value), self.assertRaises(ValueError):
                validate(self.root)

    def test_java_properties_escaping(self):
        self.assertEqual(property_escape(" a:b=c\\d\nü"), r"\ a\:b\=c\\d\n\u00fc")
        self.assertEqual(property_escape("😀"), r"\ud83d\ude00")


if __name__ == "__main__":
    unittest.main()
