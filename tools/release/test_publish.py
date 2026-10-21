"""Publication failures must never expose an incomplete release."""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import publish


class PublishTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        previous = Path.cwd()
        os.chdir(self.directory.name)
        self.addCleanup(os.chdir, previous)
        Path("dist").mkdir()
        for name in [
            "android.apk",
            "ios.ipa",
            "linux.tar.gz",
            "macos.zip",
            "windows.zip",
        ]:
            (Path("dist") / name).touch()
        env = patch.dict(os.environ, RELEASE_TAG="v1.0.0", GH_REPO="example/repo")
        env.start()
        self.addCleanup(env.stop)

    def test_new_release_is_published_only_after_upload(self):
        with patch.object(publish, "gh", side_effect=["[[]]", "", "", ""]) as gh:
            publish.main()
        self.assertEqual(
            [c.args[:2] for c in gh.call_args_list],
            [
                ("api", "--paginate"),
                ("release", "create"),
                ("release", "upload"),
                ("release", "edit"),
            ],
        )
        self.assertIn("--draft", gh.call_args_list[1].args)
        self.assertIn("--draft=false", gh.call_args_list[-1].args)

    def test_existing_draft_is_resumed(self):
        releases = json.dumps([[{"tag_name": "v1.0.0", "draft": True}]])
        with patch.object(publish, "gh", side_effect=[releases, "", ""]) as gh:
            publish.main()
        self.assertEqual(gh.call_count, 3)
        self.assertEqual(gh.call_args_list[1].args[:2], ("release", "upload"))

    def test_published_release_is_not_modified(self):
        releases = json.dumps([[{"tag_name": "v1.0.0", "draft": False}]])
        with patch.object(publish, "gh", return_value=releases) as gh:
            with self.assertRaises(SystemExit):
                publish.main()
        self.assertEqual(gh.call_count, 1)

    def test_upload_failure_leaves_draft(self):
        with patch.object(
            publish,
            "gh",
            side_effect=["[[]]", "", subprocess.CalledProcessError(1, "gh")],
        ) as gh:
            with self.assertRaises(subprocess.CalledProcessError):
                publish.main()
        self.assertFalse(
            any(c.args[:2] == ("release", "edit") for c in gh.call_args_list)
        )

    def test_api_failure_does_not_attempt_creation(self):
        with patch.object(
            publish, "gh", side_effect=subprocess.CalledProcessError(1, "gh")
        ) as gh:
            with self.assertRaises(subprocess.CalledProcessError):
                publish.main()
        self.assertEqual(gh.call_count, 1)

    def test_incomplete_artifacts_are_not_published(self):
        Path("dist/android.apk").unlink()
        with patch.object(publish, "gh", side_effect=["[[]]", ""]) as gh:
            with self.assertRaises(SystemExit):
                publish.main()
        self.assertFalse(
            any(c.args[:2] == ("release", "edit") for c in gh.call_args_list)
        )


if __name__ == "__main__":
    unittest.main()
