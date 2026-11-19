"""Offline regression tests for generated Boost module metadata."""

import copy
import json
import unittest
from unittest.mock import patch

import generate_metadata as gm


class MetadataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.roots = gm.selected_modules()
        cls.manifest = json.loads(gm.MANIFEST.read_text(encoding="utf-8"))

    def test_embedded_matches_manifest(self):
        gm.validate(self.manifest, self.roots)
        gm.embed(self.manifest, check=True)

    def test_missing_dependency_rejected(self):
        data = copy.deepcopy(self.manifest)
        data["modules"]["pfr"]["dependencies"] = ["missing"]
        with self.assertRaisesRegex(ValueError, "Missing or self-referential"):
            gm.validate(data, self.roots)

    def test_invalid_sha_rejected(self):
        data = copy.deepcopy(self.manifest)
        data["modules"]["pfr"]["sha"] = "main"
        with self.assertRaisesRegex(ValueError, "pinned SHA"):
            gm.validate(data, self.roots)

    def test_cycle_rejected(self):
        data = copy.deepcopy(self.manifest)
        data["modules"]["config"]["dependencies"] = ["assert"]
        with self.assertRaisesRegex(ValueError, "Cyclic"):
            gm.validate(data, self.roots)

    def test_upstream_closure(self):
        a, b = "a" * 40, "b" * 40
        tree = {"tree": [
            {"path": "libs/a", "type": "commit", "sha": a},
            {"path": "libs/b", "type": "commit", "sha": b},
        ]}
        config = '[submodule "a"]\npath = libs/a\nurl = ../a.git\n'
        config += '[submodule "b"]\npath = libs/b\nurl = ../b.git\n'

        def fake(url):
            if "git/trees" in url:
                return json.dumps(tree)
            if url.endswith("/.gitmodules"):
                return config
            if "/a/" in url:
                return "target_link_libraries(boost_a INTERFACE Boost::b)\n# Boost::missing\n"
            if "/b/" in url:
                return "add_library(Boost::b ALIAS boost_b)\n"
            raise AssertionError(url)

        with patch.object(gm, "download", side_effect=fake):
            result = gm.upstream_manifest(["a"])
        self.assertEqual(set(result["modules"]), {"a", "b"})
        self.assertEqual(result["modules"]["a"]["dependencies"], ["b"])
        self.assertEqual(result["modules"]["b"]["sha"], b)


if __name__ == "__main__":
    unittest.main()
