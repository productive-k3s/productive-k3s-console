from __future__ import annotations

import os
import io
import contextlib
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from scripts import materials


class MaterialsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(__file__).resolve().parents[1]
        self.lock, self.raw = materials.load_lock(self.root / "materials.lock.yaml")

    def test_repository_lock_is_valid(self) -> None:
        self.assertEqual(materials.validate_lock(self.lock), [])

    def test_validation_reports_contract_failures(self) -> None:
        payload = {"apiVersion": "wrong", "kind": "Wrong", "metadata": {}, "spec": {"materials": "bad"}}
        errors = materials.validate_lock(payload)
        self.assertIn("unsupported apiVersion", errors)
        self.assertIn("kind must be MaterialsLock", errors)
        self.assertIn("spec.materials must be an array", errors)

    def test_validation_reports_missing_root_fields(self) -> None:
        self.assertEqual(
            materials.validate_lock({}),
            ["missing root fields: apiVersion, kind, metadata, spec"],
        )

    def test_validation_reports_missing_and_duplicate_materials(self) -> None:
        payload = {
            "apiVersion": "materials.productive-k3s.io/v1alpha1",
            "kind": "MaterialsLock",
            "metadata": {},
            "spec": {
                "materials": [
                    {"id": "same", "pinPolicy": "exact-digest"},
                    {"id": "same", "pinPolicy": "exact-checksum"},
                    "bad",
                ]
            },
        }
        errors = materials.validate_lock(payload)
        self.assertTrue(any("missing fields" in error for error in errors))
        self.assertIn("same requires digest", errors)
        self.assertIn("same requires checksums", errors)
        self.assertIn("duplicate material id: same", errors)
        self.assertIn("spec.materials[2] must be an object", errors)

    def test_render_bom_is_reproducible_with_source_date_epoch(self) -> None:
        with mock.patch.dict(os.environ, {"SOURCE_DATE_EPOCH": "0"}):
            bom = materials.render_bom(self.lock, self.raw, "abc123")
        self.assertEqual(bom["generatedAt"], "1970-01-01T00:00:00Z")
        self.assertEqual(bom["sourceRevision"], "abc123")
        self.assertEqual(len(bom["materials"]), 8)

    def test_load_lock_rejects_non_object(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "materials.lock.yaml"
            path.write_text("- invalid\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "root must be an object"):
                materials.load_lock(path)

    def test_git_revision_uses_repository(self) -> None:
        revision = materials.git_revision(self.root)
        self.assertRegex(revision, r"^[0-9a-f]{40}$")

    def test_generated_at_defaults_to_current_utc_time(self) -> None:
        with mock.patch.dict(os.environ, {}, clear=True):
            self.assertRegex(materials.generated_at(), r"^\d{4}-\d{2}-\d{2}T.*Z$")

    def test_main_validates_and_renders(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "bom.json"
            with mock.patch(
                "sys.argv",
                ["materials.py", "validate", "--lock", str(self.root / "materials.lock.yaml")],
            ), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(materials.main(), 0)
            with mock.patch(
                "sys.argv",
                [
                    "materials.py",
                    "render",
                    "--lock",
                    str(self.root / "materials.lock.yaml"),
                    "--output",
                    str(output),
                    "--source-revision",
                    "abc123",
                ],
            ), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(materials.main(), 0)
            self.assertEqual(
                materials.json.loads(output.read_text(encoding="utf-8"))["sourceRevision"],
                "abc123",
            )

    def test_main_reports_invalid_lock(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "materials.lock.yaml"
            path.write_text("{}\n", encoding="utf-8")
            with mock.patch(
                "sys.argv", ["materials.py", "validate", "--lock", str(path)]
            ), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(materials.main(), 1)


if __name__ == "__main__":
    unittest.main()
