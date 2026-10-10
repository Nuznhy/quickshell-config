"""Run the real calendar with a fake reader and isolated preferences."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
from design_test_support import install_design


class RuntimeTests(unittest.TestCase):
    def test_dates_navigation_and_privacy_lifecycle(self):
        with tempfile.TemporaryDirectory(prefix='qs-calendar-test-') as directory:
            base = Path(directory)
            for folder in ['services', 'components', 'config', 'scripts', 'runtime']:
                (base / folder).mkdir(mode=0o700)
            for name in ['services/CalendarEvents.qml', 'services/CalendarFeed.qml',
                         'components/CalendarPanel.qml', 'components/CalendarSettingsPanel.qml']:
                shutil.copyfile(ROOT / name, base / name)
            (base / 'services/qmldir').write_text('singleton CalendarFeed 1.0 CalendarFeed.qml\nCalendarEvents 1.0 CalendarEvents.qml\n')
            (base / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\n')
            (base / 'config/Theme.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property string fontFamily: "sans-serif" }\n')
            install_design(base)
            (base / 'scripts/ical-calendar.py').write_text('''import json, sys, time
time.sleep(0.3)
if sys.argv[1] == 'manage':
    request = json.load(sys.stdin)
    valid = request['action'] == 'forget' or request.get('url') == 'https://example.test/private-ui-token/basic.ics'
    print(json.dumps({'ok': valid, 'error': '' if valid else 'Invalid test request'}))
    sys.exit(0)
print(json.dumps({'events': [{'title': sys.argv[2], 'calendar': 'Test', 'allDay': True,
                            'startDay': sys.argv[2], 'endDay': sys.argv[3]}], 'error': ''}))
''')
            (base / 'shell.qml').write_text('''import QtQuick
import Quickshell
import "services"
import "components"
ShellRoot {
    id: root
    property int phase: 0
    property int ticks: 0
    property var retainedModel
    property real retainedHeight: 0
    property int retainedGeneration: 0
    property var reader: panel.children.find(child => child.objectName === "calendar-events")
    CalendarSettingsPanel { id: settings; width: 500; active: true }
    CalendarPanel { id: panel; width: 688; active: true; today: new Date(2026, 9, 10) }
    function findItem(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = findItem(child, name);
            if (found) return found;
        }
        return null;
    }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            root.ticks++;
            if (root.ticks > 140) { console.log("CALENDAR_TEST_FAILED timeout phase " + root.phase); Qt.quit(); return; }
            try {
                if (!CalendarFeed.ready) return;
                if (root.phase === 0) {
                    if (CalendarFeed.enabled || root.reader.events.length) throw new Error("opt-in default");
                    settings.active = true;
                    const input = root.findItem(settings, "calendar-feed-url");
                    if (input.echoMode !== TextInput.Password || input.passwordMaskDelay !== 0) throw new Error("input not masked");
                    input.text = "https://example.test/private-ui-token/basic.ics";
                    root.findItem(settings, "calendar-feed-save").clicked();
                    if (input.text.length) throw new Error("save retained input");
                    root.phase = 1;
                } else if (root.phase === 1 && !CalendarFeed.busy && CalendarFeed.enabled && !root.reader.loading) {
                    if (root.reader.errorMessage || root.reader.events.length !== 1) throw new Error("load: " + root.reader.errorMessage);
                    if (root.reader.eventsOn(panel.today).length !== 1) throw new Error("agenda date");
                    // Exclusive all-day end, midnight boundaries and zero-duration events.
                    root.reader.events = [
                        {allDay: true, startDay: "2026-10-10", endDay: "2026-10-12"},
                        {allDay: false, start: new Date(2026, 9, 10, 23).getTime(), end: new Date(2026, 9, 11).getTime()},
                        {allDay: false, start: new Date(2026, 9, 11, 12).getTime(), end: new Date(2026, 9, 11, 12).getTime()}
                    ].map(event => Object.assign({title: "Test", calendar: "Test"}, event));
                    if (root.reader.eventsOn(new Date(2026, 9, 10)).length !== 2 ||
                        root.reader.eventsOn(new Date(2026, 9, 11)).length !== 2 ||
                        root.reader.eventsOn(new Date(2026, 9, 12)).length !== 0) throw new Error("date boundaries");
                    root.phase = 7;
                } else if (root.phase === 7 && panel.renderedAgenda.indexOf("2026-10-10") === 0 && root.findItem(panel, "calendar-event-list").count === 2) {
                    const list = root.findItem(panel, "calendar-event-list");
                    if (list.count !== 2) throw new Error("initial day model");
                    root.retainedModel = list.model;
                    root.retainedHeight = panel.implicitHeight;
                    root.retainedGeneration = root.reader.generation;
                    panel.selectedDate = new Date(2026, 9, 11);
                    panel.selectedDate = new Date(2026, 9, 12);
                    panel.selectedDate = new Date(2026, 9, 11);
                    root.phase = 8;
                } else if (root.phase === 8 && panel.renderedAgenda.indexOf("2026-10-11") === 0) {
                    const list = root.findItem(panel, "calendar-event-list");
                    if (list.count !== 2 || list.model !== root.retainedModel) throw new Error("day model rebuilt");
                    if (panel.implicitHeight !== root.retainedHeight) throw new Error("day change resized popup");
                    if (root.reader.generation !== root.retainedGeneration) throw new Error("day change refetched month");
                    panel.changeMonth(1);
                    root.phase = 2;
                } else if (root.phase === 2 && root.reader.loading) {
                    panel.changeMonth(1);
                    root.phase = 3;
                } else if (root.phase === 3 && !root.reader.loading) {
                    if (root.reader.events.length !== 1 || root.reader.events[0].title !== Qt.formatDate(root.reader.firstDate, "yyyy-MM-dd")) throw new Error("stale navigation result");
                    panel.active = false;
                    if (root.reader.events.length) throw new Error("close retained events");
                    panel.active = true;
                    root.phase = 4;
                } else if (root.phase === 4 && root.reader.loading) {
                    CalendarFeed.enabled = false;
                    if (root.reader.events.length) throw new Error("disable retained events");
                    root.phase = 5;
                } else if (root.phase === 5 && !root.reader.loading) {
                    if (root.reader.events.length || root.reader.active) throw new Error("late result after disable");
                    const input = root.findItem(settings, "calendar-feed-url");
                    input.text = "unsaved-private-text";
                    settings.active = false;
                    panel.active = false;
                    if (input.text.length) throw new Error("close retained input");
                    panel.active = true;
                    root.findItem(settings, "calendar-feed-remove").clicked();
                    root.phase = 6;
                } else if (root.phase === 6 && !CalendarFeed.busy) {
                    if (CalendarFeed.enabled || CalendarFeed.failed || CalendarFeed.pendingUrl.length) throw new Error("remove failed");
                    console.log("CALENDAR_TEST_OK"); Qt.quit();
                }
            } catch (error) { console.log("CALENDAR_TEST_FAILED " + error); Qt.quit(); }
        }
    }
}
''')
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
                       XDG_RUNTIME_DIR=str(base / 'runtime'), XDG_STATE_HOME=str(base / 'state'),
                       XDG_CONFIG_HOME=str(base / 'user-config'), XDG_CACHE_HOME=str(base / 'cache'),
                       HYPRLAND_INSTANCE_SIGNATURE='')
            result = subprocess.run(['quickshell', '--path', str(base)], env=env,
                                    capture_output=True, text=True, timeout=12)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn('CALENDAR_TEST_OK', output)
            self.assertNotIn('CALENDAR_TEST_FAILED', output)
            self.assertNotIn('private-ui-token', output)
            for path in (base / 'state').rglob('*'):
                if path.is_file():
                    self.assertNotIn('private-ui-token', path.read_text())
            for error in ['ReferenceError', 'TypeError', 'Unable to assign', 'Binding loop', 'Cannot assign']:
                self.assertNotIn(error, output)


if __name__ == '__main__':
    unittest.main()
