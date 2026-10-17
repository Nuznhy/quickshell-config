#!/usr/bin/env python3
"""Start a locker based on compositor state, even after a stale Hyprlock exit."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def is_locked():
    result = subprocess.run(['hyprctl', '-j', 'locked'], capture_output=True,
                            text=True, check=True, timeout=2)
    state = json.loads(result.stdout).get('locked')
    if not isinstance(state, bool):
        raise RuntimeError('Hyprland did not report a valid session lock state.')
    return state


def launch(runtime, instance, timeout=10):
    # Serialize startup per compositor. Release the guard once the compositor
    # has the lock, rather than tying it to a process that may hang after unlock.
    key = hashlib.sha256(instance.encode()).hexdigest()[:16]
    with (runtime / f'quickshell-hyprlock-{key}.lock').open('a') as guard:
        try:
            fcntl.flock(guard, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        if is_locked():
            return

        # A leftover process is not evidence of a locked session. Do not signal
        # it: a locker can belong to another session or still be authenticating.
        log_path = runtime / f'quickshell-hyprlock-{key}.log'
        with log_path.open('a') as log:
            child = subprocess.Popen(['hyprlock'], stdin=subprocess.DEVNULL,
                                     stdout=log, stderr=subprocess.STDOUT,
                                     start_new_session=True, close_fds=True)
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if is_locked():
                return
            code = child.poll()
            if code is not None:
                if code == 0:  # A very fast lock/unlock can fall between polls.
                    return
                raise RuntimeError(f'Hyprlock exited with status {code}. See {log_path}.')
            time.sleep(.1)
        raise RuntimeError(f'Hyprlock did not lock within {timeout}s. See {log_path}.')


if __name__ == '__main__':
    try:
        runtime = os.environ.get('XDG_RUNTIME_DIR')
        instance = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
        if not runtime or not instance:
            raise RuntimeError('Run this launcher inside your Hyprland session.')
        launch(Path(runtime), instance)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
