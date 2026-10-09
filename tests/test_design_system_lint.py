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

    def test_property_values_inline_bases_and_enum_references(self):
        self.write("Panel.qml", """Item {
    sourceComponent: StyledSlider { configuration: StyledSlider.Configuration.M }
    sourceComponent: StyledProgressBar { }
    component QuickSlider: StyledSlider { }
    configuration: StyledSlider.Configuration.M
    property Component nested: QtWidgets.StyledSlider { }
    sourceComponent: StyledSlider
        /* another line */ { }
}
""")
        result = self.run_lint()
        self.assertEqual(result.returncode, 1, result.stderr)
        for number in (2, 3, 4, 5, 6, 7):
            self.assertIn(f"Panel.qml:{number}: error:", result.stdout)
        self.assertEqual(result.stdout.count(" is legacy;"), 7)

    def test_comments_strings_and_identifier_boundaries(self):
        self.write("Panel.qml", r'''// StyledSlider {} and "#ffffff"
/* sourceComponent: StyledProgressBar {}
component Quick: StyledSlider {} */
Item {
    property string quoted: "StyledSlider {} and StyledSlider.Configuration.M"
    property string escaped: "\"StyledProgressBar {}\""
    property string single: 'DialogButton {}'
    property string template: `WindowDialog {}
StyledSlider.Configuration.M`
    property string longer: "not a type"
    NotStyledSlider {}
    StyledSliderExtra {}
}
''')
        result = self.run_lint()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn(" is legacy;", result.stdout)

    def test_legacy_coverage_for_retired_and_phase_five_controls(self):
        controls = ["ButtonGroup", "GroupButton", "SelectionGroupButton", "ConfigSelectionArray",
                    "Toolbar", "ToolbarButton", "IconToolbarButton", "ToolbarTextField", "DialogButton", "RippleButtonWithIcon", "WindowDialogSeparator",
                    "DialogListItem", "MaterialTextArea", "StyledTextArea", "WindowDialog",
                    "OverlayDialog", "OverlayDialogCard", "WindowDialogTitle",
                    "WindowDialogParagraph", "WindowDialogSectionHeader", "WindowDialogButtonRow",
                    "WindowDialogSlider", "MenuButton", "StyledComboBox", "FilterableComboBox",
                    "SecondaryTabBar", "SecondaryTabButton", "ToolbarTabBar", "ToolbarTabButton"]
        self.write("Panel.qml", "\n".join(f"sourceComponent: {control} {{ }}" for control in controls))
        result = self.run_lint()
        self.assertEqual(result.returncode, 1, result.stderr)
        for control in controls:
            self.assertIn(f"{control} is legacy; use M3.", result.stdout)

    def test_implementation_exempts_all_legacy_forms_and_restyles(self):
        sample = """sourceComponent: StyledSlider { configuration: StyledSlider.Configuration.M }
component QuickSlider: StyledSlider {}
RippleButton { colBackground: palette.primary; contentItem: Rectangle {} }
Button { background: Item {} }
"""
        for directory in ("modules/common/m3", "modules/common/widgets"):
            self.write(f"{directory}/Implementation.qml", sample)
        result = self.run_lint()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("warning:", result.stdout)

    def test_shared_names_allow_only_the_supported_m3_qualification(self):
        self.write("Panel.qml", """import qs.modules.common.m3 as M3
M3.ButtonGroup {}
M3.Toolbar {}
M3.ToolbarTextField {}
ButtonGroup {}
Toolbar {}
ToolbarTextField {}
Other.Toolbar {}
M3.StyledSlider {}
""")
        result = self.run_lint()
        self.assertEqual(result.returncode, 1, result.stderr)
        for number in (2, 3, 4):
            self.assertNotIn(f"Panel.qml:{number}: error:", result.stdout)
        for number in (5, 6, 7, 8, 9):
            self.assertIn(f"Panel.qml:{number}: error:", result.stdout)

    def test_actual_panel_control_restyles_are_advisory(self):
        self.write("modules/widgets/Player.qml", """RippleButton {
    buttonRadius: player.isPlaying ? rounding.normal : size / 2
    colBackground: player.isPlaying ? palette.primary : palette.secondaryContainer
    contentItem: MaterialSymbol { text: "play_arrow" }
}
""")
        self.write("modules/widgets/Workspaces.qml", """Button {
    background: Item { Rectangle { color: palette.primary } }
}
""")
        result = self.run_lint()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Player.qml:2: warning: restyled RippleButton", result.stdout)
        self.assertIn("Workspaces.qml:2: warning: restyled Button", result.stdout)

    def test_plain_controls_m3_controls_and_nested_drawings_are_not_restyles(self):
        self.write("modules/widgets/Panel.qml", """Item {
    RippleButton { onClicked: controller.open() }
    Button { Rectangle { property color colBackground: palette.primary } }
    M3.Button { content: Rectangle { color: palette.primary } }
    // RippleButton { contentItem: Item {} }
    property string sample: "Button { background: Item {} }"
    Rectangle { color: palette.primary; radius: rounding.small }
}
""")
        result = self.run_lint()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("restyled", result.stdout)

    def test_m3_panel_restyles_and_changed_properties_are_reviewed(self):
        self.write("modules/widgets/Panel.qml", "M3.Button {\n    text: \"Open\"\n}\n")
        self.git("add", ".")
        self.git("commit", "-m", "Existing M3 control")
        self.write("modules/widgets/Panel.qml", "M3.Button {\n    text: \"Open\"\n    background: Rectangle {}\n}\n")
        for args in [(), ("--changed",)]:
            result = self.run_lint(*args)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Panel.qml:3: warning: restyled M3.Button", result.stdout)

    def test_changed_scan_uses_full_multiline_context(self):
        self.write("Panel.qml", """/*
StyledSlider {}
*/
Item {}
""")
        self.git("add", ".")
        self.git("commit", "-m", "Multiline comment fixture")
        self.write("Panel.qml", """/*
StyledProgressBar {}
*/
Item { sourceComponent: StyledSlider {} }
""")
        result = self.run_lint("--changed")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertNotIn("StyledProgressBar is legacy", result.stdout)
        self.assertIn("Panel.qml:4: error: StyledSlider", result.stdout)


if __name__ == "__main__":
    unittest.main()
