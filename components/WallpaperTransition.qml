pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    clip: true
    property url source
    property string mode: "dark"
    property bool ready: true
    // Fade, zoom, then wipes from left/right/top/bottom.
    property int style: 0
    property int duration: 650
    property size pixelSize: Qt.size(width, height)
    property color backgroundColor: "black"
    readonly property bool hasContent: frontIndex >= 0 || pendingIndex >= 0
    property string displayedSource: ""
    property string errorMessage: ""
    property bool transitioning: false
    property real progress: 0
    property int frontIndex: -1
    property int pendingIndex: -1
    property string pendingSource: ""
    property string previousMode: mode
    property bool animatePending: false
    property bool clearing: false
    property int activeStyle: 0
    property bool completed: false

    function bufferFor(index) { return index === 0 ? first : second; }
    function schedule() { if (completed) Qt.callLater(updateTarget); }
    function updateTarget() {
        if (!ready) return;
        const target = source.toString();
        const modeChanged = previousMode !== mode;
        previousMode = mode;
        // Settle the in-flight transition before accepting the latest request.
        // This bounds memory to two image buffers even during rapid toggling.
        if (transitioning) finish();
        if (pendingIndex >= 0) bufferFor(pendingIndex).imageSource = "";
        pendingIndex = -1;
        pendingSource = "";
        errorMessage = "";
        if (target === displayedSource) return;
        animatePending = modeChanged && frontIndex >= 0;
        activeStyle = style;
        progress = 0;
        clearing = target === "";
        if (clearing) {
            if (animatePending) { transitioning = true; reveal.start(); }
            else finish();
            return;
        }
        pendingSource = target;
        pendingIndex = frontIndex === 0 ? 1 : 0;
        bufferFor(pendingIndex).imageSource = target;
        imageChanged(pendingIndex, bufferFor(pendingIndex).imageStatus);
    }
    function imageChanged(index, status) {
        if (index < 0 || index !== pendingIndex || transitioning) return;
        const image = bufferFor(index);
        if (status === Image.Ready) {
            if (animatePending) { transitioning = true; reveal.start(); }
            else finish();
        } else if (status === Image.Error) {
            errorMessage = "Could not load wallpaper: " + pendingSource;
            console.warn(errorMessage);
            pendingIndex = -1;
            image.imageSource = "";
            // Retain the last decoded image when a saved file is unavailable.
        }
    }
    function finish() {
        reveal.stop();
        const oldFront = frontIndex;
        frontIndex = clearing ? -1 : pendingIndex;
        displayedSource = clearing ? "" : pendingSource;
        pendingIndex = -1;
        transitioning = false;
        progress = 0;
        if (oldFront >= 0 && oldFront !== frontIndex) bufferFor(oldFront).imageSource = "";
    }
    onSourceChanged: schedule()
    onModeChanged: schedule()
    onReadyChanged: schedule()
    Component.onCompleted: { completed = true; schedule(); }

    NumberAnimation {
        id: reveal
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.duration
        easing.type: Easing.InOutCubic
        onFinished: root.finish()
    }

    component Layer: Item {
        id: buffer
        required property int index
        readonly property bool incoming: root.transitioning && root.pendingIndex === index
        property alias imageSource: image.source
        property alias imageStatus: image.status
        anchors.fill: parent
        visible: root.frontIndex === index || incoming
        z: incoming ? 1 : 0
        opacity: root.clearing && root.transitioning ? 1 - root.progress
            : incoming && root.activeStyle < 2 ? root.progress : 1
        scale: incoming && root.activeStyle === 1 ? 1.06 - 0.06 * root.progress : 1
        // Fade the image and its opaque background as one surface.
        layer.enabled: opacity > 0 && opacity < 1
        Item {
            id: viewport
            clip: true
            width: buffer.incoming && (root.activeStyle === 2 || root.activeStyle === 3) ? root.width * root.progress : root.width
            height: buffer.incoming && (root.activeStyle === 4 || root.activeStyle === 5) ? root.height * root.progress : root.height
            x: buffer.incoming && root.activeStyle === 3 ? root.width - width : 0
            y: buffer.incoming && root.activeStyle === 5 ? root.height - height : 0
            Rectangle { anchors.fill: parent; color: root.backgroundColor }
            Image {
                id: image
                x: -viewport.x; y: -viewport.y
                width: root.width; height: root.height
                asynchronous: true
                cache: false
                fillMode: Image.PreserveAspectCrop
                sourceSize: root.pixelSize
                onStatusChanged: root.imageChanged(buffer.index, status)
            }
        }
    }
    Layer { id: first; index: 0 }
    Layer { id: second; index: 1 }
}
