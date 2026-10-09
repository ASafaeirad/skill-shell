#!/usr/bin/env python3
"""Design-system lint for repository QML.

Checks all tracked and untracked, non-ignored QML by default and reports:

  error    a hex colour literal (theme colours come from Appearance)
  error    qs.modules.common.m3 imported without `as M3`
  error    a legacy widget that has an M3 replacement outside the library
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
}
# Files that implement the design system itself may use the legacy names.
EXEMPT_LEGACY = ("modules/common/widgets/", "modules/common/m3/")

HEX = re.compile(r"[\"']#[0-9a-fA-F]{3,8}[\"']")
M3_IMPORT = re.compile(r"^\s*import\s+qs\.modules\.common\.m3\b(?!\s+as\s+M3\b)")
INLINE = re.compile(r"^\s*component\s+(\w+)\s*:\s*(Rectangle|RippleButton|MouseArea|Button)\b")
THIN = re.compile(r"^\s*(implicitHeight|height|implicitWidth|width)\s*:\s*1\s*$")
LEGACY_USE = re.compile(r"^\s*(" + "|".join(LEGACY) + r")\s*\{")


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
    text = Path(path).read_text().splitlines()
    for number, line in enumerate(text, 1):
        if only is not None and number not in only:
            continue
        if HEX.search(line) and path != "modules/common/Appearance.qml":
            findings.append(("error", number, "hex colour literal; use an Appearance.colors/m3colors token"))
        if M3_IMPORT.search(line):
            findings.append(("error", number, "import the design system as `import qs.modules.common.m3 as M3`"))
        m = INLINE.search(line)
        if m and path.startswith(("modules/widgets/", "modules/settings/")):
            findings.append(("warning", number, f"inline component {m.group(1)}: {m.group(2)} — check modules/common/m3/README.md for an M3 component first"))
        m = LEGACY_USE.search(line)
        if m and not path.startswith(EXEMPT_LEGACY):
            findings.append(("error", number, f"{m.group(1)} is legacy; use {LEGACY[m.group(1)]}"))
        if THIN.search(line) and any("Rectangle" in l for l in text[max(0, number - 6):number]):
            findings.append(("warning", number, "1px Rectangle; use M3.Divider"))
    return findings


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
