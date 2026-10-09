#!/usr/bin/env python3
"""Live, click-through preview smoke test; never switches or focuses workspaces."""
from pathlib import Path
from design_test_support import install_design
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='qs-preview-native-') as directory:
    base=Path(directory)
    for name in ['components','services','config']:
        (base/name).mkdir()
    for name in ['WorkspacePreview.qml','WorkspacePreviewContent.qml','PopupPlacement.js']:
        shutil.copyfile(root/'components'/name,base/'components'/name)
    for name in ['Workspaces.qml','WorkspaceWindows.js','WorkspacePreviewData.js']:
        shutil.copyfile(root/'services'/name,base/'services'/name)
    shutil.copyfile(root/'config/Icons.qml',base/'config/Icons.qml')
    (base/'services/qmldir').write_text('singleton Workspaces 1.0 Workspaces.qml\n')
    (base/'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\nsingleton Icons 1.0 Icons.qml\nsingleton Settings 1.0 Settings.qml\n')
    (base/'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property string barPosition: "top"
 property string fontFamily: "sans-serif"
 property color bg: "#191724"
 property color surface: "#1f1d2e"
 property color text: "#e0def4"
 property color iris: "#c4a7e7"
 property color highlightMed: "#403d52"
 function wallpaperFor(name) {return "";}
}
''')
    (base/'config/Settings.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property int popupPadding: 12; property int workspaceInterval: 500 }\n')
    install_design(base)
    (base/'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Wayland
import "config"
import "services"
import "components"
ShellRoot {
 property int elapsed: 0
 property int phase: 0
 property int testWorkspace: -1
 function fail(message) { console.error("PREVIEW_FAILED: " + message); Qt.quit(); }
 function captureCount(item) {
  if (!item) return 0;
  let count = item.objectName?.startsWith("workspace-preview-capture-") && item.hasContent ? 1 : 0;
  for (const child of item.children || []) count += captureCount(child);
  return count;
 }
 PanelWindow {
  id: panel
  signal closeAllPopups
  visible: true
  anchors {top:true;left:true}
  implicitWidth:420; implicitHeight:42
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}
  color:"transparent"
  Item {id: anchor; x:20; width:100; height:42}
  WorkspacePreview {id: preview; barWindow:panel}
 }
 Timer {
  interval:50; running:true; repeat:true
  onTriggered: {
   elapsed += 50;
   if (elapsed > 10000) {fail("timeout: phase=" + phase + ", opened=" + preview.opened + ", captures=" + captureCount(preview.previewItem));return;}
   if (phase===0 && Workspaces.occupiedWorkspaceIds.length) {
    testWorkspace=Workspaces.occupiedWorkspaceIds.find(id=>id!==Workspaces.activeWorkspaceId) || Workspaces.occupiedWorkspaceIds[0];
    preview.request(testWorkspace,anchor,""); phase=1;
   } else if (phase===1 && captureCount(preview.previewItem)>0) {
    console.log("PREVIEW_CAPTURED: " + captureCount(preview.previewItem));
    const address=Workspaces.getWsWindows(testWorkspace)[0].address;
    preview.request(testWorkspace,anchor,address);
    if (preview.previewItem.selectedWindow?.address!==address) {fail("highlight target");return;}
    preview.close(); phase=2;
   } else if (phase===2) {
    if (preview.previewItem!==null) {fail("captures not released");return;}
    Theme.barPosition="left";
    preview.request(testWorkspace,anchor,""); phase=3;
   } else if (phase===3 && captureCount(preview.previewItem)>0) {
    preview.leave(testWorkspace); phase=4;
   } else if (phase===4 && !preview.opened) {
    console.log("PREVIEW_OK: native capture, highlight, close and reopen"); Qt.quit();
   }
  }
 }
}
''')
    env=dict(os.environ, QT_QPA_PLATFORM='wayland', XDG_STATE_HOME=str(base/'state'), XDG_CACHE_HOME=str(base/'cache'))
    result=subprocess.run(['quickshell','--path',str(base)],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=18)
    print(result.stdout)
    assert 'PREVIEW_OK:' in result.stdout and 'PREVIEW_FAILED:' not in result.stdout, result.stdout
    for error in ['TypeError','ReferenceError','Binding loop','Failed to load configuration','Unable to assign']:
        assert error not in result.stdout, result.stdout
