import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "camera_privacy", Path(__file__).parents[1] / "scripts/camera/privacy.py")
privacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(privacy)


class CameraPrivacyTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        for name in ("USB", "VIDEO"):
            path = self.root / name
            path.mkdir()
            patcher = patch.object(privacy, name, path)
            patcher.start()
            self.addCleanup(patcher.stop)
        for name in ("RULE", "PROBE"):
            patcher = patch.object(privacy, name, self.root / name)
            patcher.start()
            self.addCleanup(patcher.stop)
        self.video = self.interface("1-1:1.0", "0e")
        self.stream = self.interface("1-1:1.1", "0e")
        self.audio = self.interface("1-1:1.2", "01")

    def interface(self, name, kind):
        path = privacy.USB / name
        path.mkdir()
        (path / "bInterfaceClass").write_text(kind)
        (path / "authorized").write_text("1")
        return path

    def test_block_and_restore_preserve_audio_and_probe_after_authorization(self):
        probes = []
        original_write = Path.write_text

        def write(path, text, *args, **kwargs):
            if path == privacy.PROBE:
                self.assertTrue(all((p / "authorized").read_text() == "1"
                                    for p in (self.video, self.stream)))
                probes.append(text)
            return original_write(path, text, *args, **kwargs)

        with patch.object(privacy.os, "geteuid", return_value=0), \
                patch.object(privacy.subprocess, "run") as run, \
                patch.object(Path, "write_text", write):
            privacy.set_blocked(True)
            self.assertTrue(privacy.status()["blocked"])
            self.assertEqual((self.audio / "authorized").read_text(), "1")
            self.assertIn('ATTR{bInterfaceClass}=="0e"', privacy.RULE.read_text())
            privacy.set_blocked(False)
            self.assertFalse(privacy.RULE.exists())
            self.assertFalse(privacy.status()["blocked"])
            self.assertEqual(probes, [self.video.name, self.stream.name])
            self.assertEqual(run.call_count, 2)

    def test_partial_block_does_not_report_blocked(self):
        privacy.RULE.write_text(privacy.RULE_TEXT)
        (self.video / "authorized").write_text("0")
        self.assertFalse(privacy.status()["blocked"])

    def test_unsupported_camera_prevents_claiming_global_block(self):
        device = privacy.VIDEO / "video0"
        device.mkdir()
        (device / "device").symlink_to(self.root / "non-usb-camera")
        self.assertFalse(privacy.status()["available"])
        self.assertFalse(privacy.status()["blocked"])

    def test_mutations_require_root(self):
        with patch.object(privacy.os, "geteuid", return_value=1000):
            with self.assertRaises(PermissionError):
                privacy.set_blocked(True)
        self.assertFalse(privacy.RULE.exists())

    def test_disconnected_blocked_camera_can_be_unblocked(self):
        for interface in (self.video, self.stream):
            for child in interface.iterdir():
                child.unlink()
            interface.rmdir()
        privacy.RULE.write_text(privacy.RULE_TEXT)
        self.assertEqual(privacy.status(), {"blocked": True, "available": True})
        with patch.object(privacy.os, "geteuid", return_value=0), \
                patch.object(privacy.subprocess, "run"):
            privacy.set_blocked(False)
        self.assertFalse(privacy.RULE.exists())


if __name__ == "__main__":
    unittest.main()
