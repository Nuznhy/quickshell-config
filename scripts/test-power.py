#!/usr/bin/env python3
"""Exercise power routing and lock authentication using mocks only."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', str(root / 'tests/power'), '-v'], check=True)
with tempfile.TemporaryDirectory(prefix='qs-lock-test-') as directory:
    target = Path(directory)
    (target / 'runtime').mkdir(mode=0o700)
    (target / 'FakePam.qml').write_text('''import QtQuick
QtObject {
    property string config
    property bool active: false
    property bool responseRequired: false
    property bool responseVisible: false
    property bool startAllowed: true
    property string message: "Password"
    property string lastResponse: ""
    signal pamMessage()
    signal completed(int result)
    function start() { active = startAllowed; return startAllowed; }
    function respond(response) { lastResponse = response; responseRequired = false; }
}
''')
    source = (root / 'modules/lock/shell.qml').read_text().replace('PamContext {', 'FakePam {')
    start = source.index('    WlSessionLock {')
    end = source.index('    IpcHandler {', start)
    source = source[:start] + '    QtObject { id: lock; property bool locked: true; property bool secure: true }\n' + source[end:]
    source = source.rsplit('}', 1)[0] + '''
    Timer {
        interval: 100; running: true
        onTriggered: {
            function check(condition, message) { if (!condition) throw new Error(message); }
            root.submit("test password");
            check(pam.active && root.hasPendingResponse, "authentication started");
            pam.responseRequired = true;
            pam.pamMessage();
            check(pam.lastResponse === "test password", "PAM received response");
            check(root.pendingResponse === "" && !root.hasPendingResponse, "pending credential cleared");
            pam.active = false;
            pam.completed(PamResult.Failed);
            check(lock.locked && root.errorMessage.length > 0, "failure remains locked");
            pam.completed(PamResult.Error);
            check(lock.locked, "PAM error remains locked");
            pam.startAllowed = false;
            root.submit("another response");
            check(root.pendingResponse === "" && !root.hasPendingResponse && lock.locked, "failed start clears credential without unlocking");
            pam.completed(PamResult.Success);
            check(!lock.locked, "only success unlocks");
            console.log("PASS: lock authentication state transitions");
        }
    }
    Timer { interval: 3000; running: true; onTriggered: Qt.quit() }
}
'''
    (target / 'shell.qml').write_text(source)
    result = subprocess.run(['quickshell', '-p', str(target)], capture_output=True, text=True, timeout=8,
                            env=dict(os.environ, QT_QPA_PLATFORM='offscreen', XDG_RUNTIME_DIR=str(target / 'runtime'), XDG_STATE_HOME=str(target / 'state')))
    output = result.stdout + result.stderr
    if result.returncode or 'PASS: lock authentication state transitions' not in output:
        raise RuntimeError(output)
    print('PASS: lock authentication state transitions (mock PAM and compositor)')
