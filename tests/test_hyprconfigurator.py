import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "hyprconfigurator", Path(__file__).parents[1] / "scripts/hyprland/hyprconfigurator.py")
configurator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(configurator)


class DeviceResetTest(unittest.TestCase):
    def test_touchpad_is_enabled_before_its_last_override_disappears(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "overrides.lua"
            name = "asup1207:00-093a:3012-touchpad"
            key = f"device:{name}:enabled"
            disabled = configurator.generate_config_line(key, "false")
            config.write_text(disabled)

            def enable(command, **kwargs):
                # The compositor must receive the enable while the old block exists.
                self.assertEqual(config.read_text(), disabled)
                self.assertEqual(command, ["hyprctl", "eval",
                    configurator.generate_config_line(key, "true").strip()])

            with patch.object(subprocess, "run", side_effect=enable) as run:
                configurator.edit_hyprland_config(str(config), [], [key])
                run.assert_called_once()
            self.assertEqual(config.read_text(), "")

    def test_reset_recovers_a_touchpad_whose_override_is_already_gone(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "overrides.lua"
            with patch.object(subprocess, "run") as run:
                configurator.edit_hyprland_config(
                    str(config), [], ["device:test-touchpad:enabled"])
                run.assert_called_once()

    def test_other_resets_do_not_change_device_enabled_state(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "overrides.lua"
            with patch.object(subprocess, "run") as run:
                configurator.edit_hyprland_config(str(config), [],
                    ["animations:enabled", "device:test-touchpad:sensitivity"])
                run.assert_not_called()

    def test_failed_enable_keeps_the_override_for_a_retry(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "overrides.lua"
            key = "device:test-touchpad:enabled"
            disabled = configurator.generate_config_line(key, "false")
            config.write_text(disabled)
            with patch.object(subprocess, "run", side_effect=
                    subprocess.CalledProcessError(1, "hyprctl")):
                configurator.edit_hyprland_config(str(config), [], [key])
            self.assertEqual(config.read_text(), disabled)
            self.assertEqual(list(Path(directory).iterdir()), [config])


if __name__ == "__main__":
    unittest.main()
