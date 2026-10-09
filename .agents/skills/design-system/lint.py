#!/usr/bin/env python3
"""Design-system lint for repository QML.

Checks all tracked and untracked, non-ignored QML by default and reports:

  error    a hex colour literal (theme colours come from Appearance)
  error    qs.modules.common.m3 imported without `as M3`
  error    a legacy type construction, inline base or enum outside the library
  warning  a directly restyled panel RippleButton, Button or M3 component
  warning  an inline `component X: Rectangle/RippleButton/...` in a panel,
           which is usually an M3 component being reinvented
  warning  a 1px Rectangle, which is usually a Divider

Usage:  lint.py [--all | --changed] [--base main] [files...]
  --all      explicitly select the default whole-repository (or whole-file) scan
  --changed  only lines added since the merge base, including local changes
  files      limit the scan to these files
Exit status is 1 when there are errors, so it can gate a commit.
"""

import argparse
import bisect
import re
import subprocess
import sys
from pathlib import Path

LEGACY = {
    "StyledSwitch": "M3.Switch",
    "StyledSlider": "M3.Slider",
    "StyledRadioButton": "M3.RadioButton",
    "MaterialTextField": "M3.TextField",
    "StyledProgressBar": "M3.LinearProgressIndicator",
    "StyledIndeterminateProgressBar": "M3.LinearProgressIndicator { indeterminate: true }",
    "CircularProgress": "M3.CircularProgressIndicator",
    "MaterialLoadingIndicator": "M3.LoadingIndicator",
    "FloatingActionButton": "M3.Fab",
    "StyledToolTip": "M3.Tooltip (or IconButton's tooltip property)",
    "NavigationRailTabs": "M3.NavigationRail",
    "ButtonGroup": "M3.ButtonGroup",
    "GroupButton": "M3.Button in M3.ButtonGroup",
    "SelectionGroupButton": "M3.ButtonGroup with segmented options",
    "ConfigSelectionArray": "M3.ButtonGroup with configKey",
    "Toolbar": "M3.Toolbar",
    "ToolbarButton": "M3.Button or M3.IconButton in M3.Toolbar",
    "IconToolbarButton": "M3.IconButton in M3.Toolbar",
    "ToolbarTextField": "M3.ToolbarTextField",
    "DialogButton": 'M3.Button { variant: "text" }',
    "RippleButtonWithIcon": "M3.Button or M3.IconButton",
    "WindowDialogSeparator": "M3.Divider",
    "DialogListItem": "M3.ListItem",
    "MaterialTextArea": "M3.TextArea",
    "StyledTextArea": "M3.TextArea",
    "WindowDialog": "M3.Dialog",
    "OverlayDialog": "M3.DialogOverlay",
    "OverlayDialogCard": "M3.DialogCard",
    "WindowDialogTitle": "M3.DialogTitle",
    "WindowDialogParagraph": "M3.DialogParagraph",
    "WindowDialogSectionHeader": "M3.DialogSectionHeader",
    "WindowDialogButtonRow": "M3.DialogButtonRow",
    "WindowDialogSlider": "M3.Slider with M3.DialogSectionHeader",
    "MenuButton": "M3.MenuItem",
    "StyledComboBox": "M3.ExposedDropdownMenu",
    "FilterableComboBox": "M3.FilterableExposedDropdownMenu",
    "SecondaryTabBar": "M3.Tabs",
    "SecondaryTabButton": "M3.Tab",
    "ToolbarTabBar": 'M3.Tabs { variant: "compact" }',
    "ToolbarTabButton": 'M3.Tab { variant: "compact" }',

}
# Files that implement the design system itself may use the legacy names.
EXEMPT_LEGACY = ("modules/common/widgets/", "modules/common/m3/")
# These retired unqualified names also name supported M3 components. Do not
# exempt misspellings like M3.StyledSlider, which are still legacy names.
SHARED_M3_NAMES = {"ButtonGroup", "Toolbar", "ToolbarTextField"}

HEX = re.compile(r"[\"']#[0-9a-fA-F]{3,8}[\"']")
M3_IMPORT = re.compile(r"^\s*import\s+qs\.modules\.common\.m3\b(?!\s+as\s+M3\b)")
INLINE = re.compile(r"^\s*component\s+(\w+)\s*:\s*(Rectangle|RippleButton|MouseArea|Button)\b")
THIN = re.compile(r"^\s*(implicitHeight|height|implicitWidth|width)\s*:\s*1\s*$")
LEGACY_USE = re.compile(r"\b(" + "|".join(LEGACY) + r")\b\s*(?:\{|(?=\.\s*[A-Z]))")
# Keep offsets/newlines intact so multiline QML reports the original source line.
LEXICAL = re.compile(r"//[^\n]*|/\*[\s\S]*?\*/|\"(?:\\[\s\S]|[^\"\\])*\"|'(?:\\[\s\S]|[^'\\])*'|`(?:\\[\s\S]|[^`\\])*`")
CONTROL = re.compile(r"(?<![\w.])(M3\.\w+|(?:[A-Z]\w*\.)?(?:RippleButton|Button))\s*\{")
RESTYLE = re.compile(r"\b(background|contentItem|colBackground\w*|colRipple\w*|buttonRadius\w*)\s*:")


def masked_source(source, strings=True):
    """Mask comments, and optionally string literals, without changing positions."""
    def mask(match):
        value = match.group()
        if not strings and not value.startswith(("//", "/*")):
            return value
        return re.sub(r"[^\n]", " ", value)
    return LEXICAL.sub(mask, source)


def restyled_controls(code):
    """Find direct styling properties in panel controls, ignoring nested drawings."""
    for match in CONTROL.finditer(code):
        start = match.end()
        depth = 1
        cursor = start
        direct = []
        for brace in re.finditer(r"[{}]", code[start:]):
            position = start + brace.start()
            if depth == 1:
                direct.extend(cursor + style.start() for style in RESTYLE.finditer(code[cursor:position]))
            if brace.group() == "{":
                depth += 1
            else:
                depth -= 1
            cursor = position + 1
            if depth == 0:
                break
        if direct:
            yield match, direct



def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=False).stdout


def added_lines(base, files):
    """Map file -> set of added line numbers (None = every line)."""
    merge_base = git("merge-base", base, "HEAD").strip() or base
    out = {}
    # -c keeps the a/ and b/ prefixes this parses, whatever diff.mnemonicPrefix
    # or diff.noprefix are set to in the user's git config.
    diff = git("-c", "diff.mnemonicPrefix=false", "-c", "diff.noprefix=false",
               "diff", "-U0", merge_base, "--", *(files or ["*.qml"]))
    current = None
    for line in diff.splitlines():
        if line.startswith("+++ "):
            path = line[4:]
            current = path[2:] if path.startswith("b/") else None
            if current:
                out.setdefault(current, set())
        elif line.startswith("@@") and current:
            m = re.search(r"\+(\d+)(?:,(\d+))?", line)
            start, count = int(m.group(1)), int(m.group(2) or 1)
            out[current].update(range(start, start + count))
    for path in git("ls-files", "-z", "--others", "--exclude-standard", "--", *(files or ["*.qml"])).split("\0"):
        if not path:
            continue
        out[path] = None
    return {p: lines for p, lines in out.items() if p.endswith(".qml") and Path(p).exists()}


def lint(path, only):
    findings = []
    source = Path(path).read_text()
    code = masked_source(source)
    comment_free = masked_source(source, strings=False)
    lines = code.splitlines()
    offsets = [match.start() for match in re.finditer("\n", source)]

    def report(level, offset, message):
        number = bisect.bisect_left(offsets, offset) + 1
        if only is None or number in only:
            findings.append((level, number, message))

    if path != "modules/common/Appearance.qml":
        for match in HEX.finditer(comment_free):
            report("error", match.start(), "hex colour literal; use an Appearance.colors/m3colors token")
    if not path.startswith(EXEMPT_LEGACY):
        for match in LEGACY_USE.finditer(code):
            name = match.group(1)
            if name in SHARED_M3_NAMES and re.search(r"\bM3\s*\.\s*$", code[:match.start()]):
                continue
            report("error", match.start(), f"{name} is legacy; use {LEGACY[name]}")
    if path.startswith(("modules/widgets/", "modules/settings/")):
        for match, properties in restyled_controls(code):
            # In changed mode, locate an added styling property even when the
            # enclosing control's declaration is unchanged.
            eligible = [offset for offset in properties
                        if only is None or bisect.bisect_left(offsets, offset) + 1 in only]
            if eligible:
                report("warning", eligible[0], f"restyled {match.group(1)}; review for an M3.Button/IconButton variant or content API")

    offset = 0
    for number, line in enumerate(lines, 1):
        if M3_IMPORT.search(line):
            report("error", offset, "import the design system as `import qs.modules.common.m3 as M3`")
        match = INLINE.search(line)
        if match and path.startswith(("modules/widgets/", "modules/settings/")):
            report("warning", offset, f"inline component {match.group(1)}: {match.group(2)} — check modules/common/m3/README.md for an M3 component first")
        if THIN.search(line) and any("Rectangle" in nearby for nearby in lines[max(0, number - 6):number]):
            report("warning", offset, "1px Rectangle; use M3.Divider")
        offset += len(line) + 1
    return sorted(findings, key=lambda finding: finding[1])


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base", default="main")
    scope = parser.add_mutually_exclusive_group()
    scope.add_argument("--all", action="store_true")
    scope.add_argument("--changed", action="store_true")
    parser.add_argument("files", nargs="*")
    args = parser.parse_args()
    requested = [Path(f).resolve() for f in args.files]

    root = git("rev-parse", "--show-toplevel").strip()
    if root:
        import os
        os.chdir(root)

    # Canonical repo-relative paths keep exemptions consistent for absolute paths
    # and spellings such as ./modules/common/m3/Switch.qml.
    args.files = []
    for path in requested:
        if not path.is_file() or path.suffix != ".qml":
            parser.error(f"not a QML file: {path}")
        try:
            args.files.append(path.relative_to(Path.cwd()).as_posix())
        except ValueError:
            parser.error(f"file is outside the repository: {path}")
    if args.changed:
        targets = added_lines(args.base, args.files)
    else:
        paths = args.files or git("ls-files", "-z", "--cached", "--others",
                                  "--exclude-standard", "--", "*.qml").split("\0")
        targets = {p: None for p in paths if p.endswith(".qml") and Path(p).is_file()}

    errors = 0
    for path in sorted(targets):
        for level, number, message in lint(path, targets[path]):
            errors += level == "error"
            print(f"{path}:{number}: {level}: {message}")
    if not targets:
        print("No changed QML files." if args.changed else "No QML files.")
    else:
        print(f"Checked {len(targets)} QML files; {errors} errors.")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
