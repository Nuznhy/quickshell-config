#!/usr/bin/env python3
"""Compatibility entry point; implementation lives in scripts/power/."""
from pathlib import Path
import runpy

if __name__ == '__main__':
    runpy.run_path(str(Path(__file__).resolve().parent / 'power/hyprlock-status.py'), run_name='__main__')
