import QtQuick
import QtTest
import "components"

TestCase {
    name: "AudioPendingPresentation"
    width: 400; height: 200
    visible: true
    when: windowShown
    AudioDeviceDropdown {
        id: selector
        width: 300
        title: "OUTPUT"
        devices: [{name: "speaker", description: "Speakers"}]
        selectedName: "speaker"
    }
    AudioLevelControl { id: level; y: 100; width: 300; level: 45; muted: false }
    function test_pending_preserves_presentation() {
        wait(30);
        const height = selector.implicitHeight;
        const before = grabImage(level);
        selector.busy = true;
        level.busy = true;
        wait(180);
        compare(selector.selectedDescription, "Speakers");
        compare(selector.implicitHeight, height);
        // Blocking commands should not blank percentages or fade the section.
        verify(before.equals(grabImage(level)));
        selector.busy = false;
        level.busy = false;
    }
}
