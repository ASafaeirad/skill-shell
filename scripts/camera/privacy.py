#!/usr/bin/python3
"""Block USB video interfaces, including active streams and reconnected cameras.

Mutations require root through pkexec. The udev rule persists across reboot.
Only video interfaces are changed; microphones on composite devices stay usable.
"""

import json
import os
from pathlib import Path
import subprocess
import sys

USB = Path("/sys/bus/usb/devices")
VIDEO = Path("/sys/class/video4linux")
PROBE = Path("/sys/bus/usb/drivers_probe")
RULE = Path("/etc/udev/rules.d/70-skill-camera-privacy.rules")
RULE_TEXT = ('ACTION=="add|change", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", '
             'ATTR{bInterfaceClass}=="0e", ATTR{authorized}="0"\n')


def interfaces():
    return sorted(p for p in USB.glob("*:*")
                  if (p / "bInterfaceClass").read_text().strip() == "0e")


def status():
    cameras = interfaces()
    # Do not claim all cameras are blocked if a non-USB camera is present.
    supported = {p.resolve() for p in cameras}
    unsupported = any((p / "device").resolve() not in supported
                      for p in VIDEO.glob("video*"))
    blocked = RULE.exists() and all(
        (p / "authorized").read_text().strip() == "0" for p in cameras)
    return {"blocked": blocked and not unsupported,
            "available": (bool(cameras) or RULE.exists()) and not unsupported}


def set_blocked(blocked):
    if os.geteuid() != 0:
        raise PermissionError("Administrator authentication is required")
    if not status()["available"]:
        raise RuntimeError("Camera privacy supports USB video cameras only")
    if blocked:
        RULE.write_text(RULE_TEXT)
    else:
        RULE.unlink(missing_ok=True)
    subprocess.run(["/usr/bin/udevadm", "control", "--reload-rules"], check=True)
    cameras = interfaces()
    for camera in cameras:
        (camera / "authorized").write_text("0" if blocked else "1")
    if not blocked:
        # Multi-interface drivers need every interface authorized before probing.
        for camera in cameras:
            PROBE.write_text(camera.name)
    if status()["blocked"] != blocked:
        raise RuntimeError("Camera access could not be changed completely")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("status", "block", "unblock"):
        raise ValueError("Usage: privacy.py status|block|unblock")
    if sys.argv[1] != "status":
        set_blocked(sys.argv[1] == "block")
    print(json.dumps(status()))


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
