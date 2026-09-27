#!/usr/bin/env python3
"""Focus a notification sender after its default action has had time to run."""
import json
from pathlib import Path
import re
import subprocess
import sys
import time


def normalize(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())


def choose_window(clients, aliases):
    names = {normalize(name) for name in aliases if name}
    names.update(normalize(re.sub(r"\.desktop$", "", name, flags=re.IGNORECASE))
                 for name in aliases if name)
    names.discard("")
    matches = [client for client in clients
               if client.get("mapped", True) and not client.get("hidden", False)
               and re.fullmatch(r"0x[0-9a-fA-F]+", client.get("address", ""))
               and any(normalize(client.get(field) or "") in names
                       for field in ("class", "initialClass"))]
    # Keep the specific window opened by the app action, otherwise use its MRU window.
    def rank(client):
        value = client.get("focusHistoryID", -1)
        return value if isinstance(value, int) and value >= 0 else float("inf")
    return min(matches, key=rank)["address"] if matches else None


def main(aliases):
    if not any(normalize(name) for name in aliases):
        return
    time.sleep(0.2)  # Let the popup's focus grab close and the application handle its action.
    for _ in range(12):
        try:
            result = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True,
                                    text=True, timeout=1, check=True)
            clients = json.loads(result.stdout)
            address = choose_window(clients, aliases) if isinstance(clients, list) else None
            if address:
                subprocess.run(["bash", str(Path(__file__).with_name("focus-window.sh")), address],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3)
                return
        except (OSError, ValueError, subprocess.SubprocessError):
            return
        time.sleep(0.15)


if __name__ == "__main__":
    main(sys.argv[1:])
