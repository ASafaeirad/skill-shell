"""Exercise lint scope and enforcement in an isolated git repository."""

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


LINT = Path(__file__).resolve().parents[1] / ".agents/skills/design-system/lint.py"


class DesignSystemLintTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Lint tests")
        self.git("config", "user.email", "lint@example.invalid")
        self.write("Panel.qml", "import QtQuick\nItem {}\n")
        self.git("add", ".")
        self.git("commit", "-m", "Initial fixture")

    def git(self, *args):
        subprocess.run(["git", *args], cwd=self.root, capture_output=True, check=True)

    def write(self, path, text):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    def run_lint(self, *args):
        return subprocess.run([sys.executable, str(LINT), *args], cwd=self.root,
                              capture_output=True, text=True)

    def test_clean_repository_still_reports_legacy_errors(self):
        self.write("Panel.qml", "StyledSwitch {}\n")
        self.git("add", ".")
        self.git("commit", "-m", "Existing legacy control")
        for args in [(), ("--all",)]:
            with self.subTest(args=args):
                result = self.run_lint(*args)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("Panel.qml:1: error: StyledSwitch is legacy", result.stdout)
        self.assertEqual(self.run_lint("--changed").stdout, "No changed QML files.\n")

    def test_untracked_files_with_spaces_and_ignored_files(self):
        self.write("New panel.qml", "StyledSlider {}\n")
        self.write(".gitignore", "Ignored.qml\n")
        self.write("Ignored.qml", "StyledSwitch {}\n")
        for args in [(), ("--changed",)]:
            with self.subTest(args=args):
                result = self.run_lint(*args)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("New panel.qml:1: error", result.stdout)
                self.assertNotIn("Ignored.qml", result.stdout)

    def test_explicit_file_checks_all_lines_and_normalizes_exemptions(self):
        self.write("Panel.qml", "StyledSwitch {}\n")
        self.write("modules/common/widgets/Wrapper.qml", "StyledSwitch {}\n")
        self.write("modules/common/m3/Wrapper.qml", "StyledSwitch {}\n")
        self.write("modules/common/Appearance.qml", 'Item { color: "#ffffff" }\n')
        self.assertEqual(self.run_lint("Panel.qml").returncode, 1)
        for path in ["modules/common/widgets/Wrapper.qml", "modules/common/m3/Wrapper.qml",
                     "modules/common/Appearance.qml"]:
            for spelling in ["./" + path, str(self.root / path)]:
                with self.subTest(path=spelling):
                    result = self.run_lint(spelling)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.write("OtherAppearance.qml", 'Item { color: "#ffffff" }\n')
        self.assertEqual(self.run_lint("OtherAppearance.qml").returncode, 1)

    def test_changed_scope_checks_local_and_committed_additions(self):
        self.git("checkout", "-b", "feature")
        self.write("Panel.qml", "import QtQuick\nStyledSwitch {}\n")
        self.git("add", ".")
        self.git("commit", "-m", "Add a control")
        self.write("Panel.qml", "import QtQuick\nStyledSwitch {}\nStyledSlider {}\n")
        result = self.run_lint("--changed", "--base", "main")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("Panel.qml:2: error", result.stdout)
        self.assertIn("Panel.qml:3: error", result.stdout)

    def test_heuristics_are_advisory_but_unqualified_imports_fail(self):
        self.write("modules/widgets/Plot.qml", "component Plot: Rectangle {}\n")
        result = self.run_lint()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("warning: inline component Plot", result.stdout)
        self.write("Panel.qml", "import qs.modules.common.m3\n")
        self.assertEqual(self.run_lint().returncode, 1)

    def test_invalid_file_arguments_fail_instead_of_skipping_checks(self):
        for path in ["Missing.qml", "NotQml.txt"]:
            with self.subTest(path=path):
                result = self.run_lint(path)
                self.assertEqual(result.returncode, 2)
                self.assertIn("not a QML file", result.stderr)

    def test_relative_file_argument_from_a_subdirectory(self):
        self.write("modules/Panel.qml", "StyledSwitch {}\n")
        result = subprocess.run([sys.executable, str(LINT), "Panel.qml"],
                                cwd=self.root / "modules", capture_output=True, text=True)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("modules/Panel.qml:1: error", result.stdout)


if __name__ == "__main__":
    unittest.main()
