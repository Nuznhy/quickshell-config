#!/usr/bin/env python3
"""Exercise Hypridle lock/power routing without changing the live session."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[2]
subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', str(root / 'tests/power'), '-v'], check=True)
