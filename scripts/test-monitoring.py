#!/usr/bin/env python3
"""Isolated monitoring backend, QML controls, history, and persistence checks."""
from pathlib import Path
from design_test_support import install_design
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
subprocess.run(['python3','-m','unittest','discover','-s',str(ROOT / 'tests/monitoring'),'-v'], check=True)
with tempfile.TemporaryDirectory(prefix='qs-monitoring-') as directory:
    base = Path(directory)
    for name in ['config','services','components','scripts','modules/bar/widgets','runtime']:
        (base / name).mkdir(parents=True, mode=0o700)
    for name in ['NotificationButton.qml','MonitoringSettings.qml','MonitoringGraph.qml','MonitoringCenter.qml']:
        shutil.copyfile(ROOT / 'components' / name, base / 'components' / name)
    widget_source = (ROOT / 'modules/bar/widgets/MonitoringWidget.qml').read_text()
    # qmltestrunner cannot load Quickshell's executable-only plugin; exercise
    # geometry/controls with a plain trigger, then test native services below.
    (base / 'modules/bar/widgets/MonitoringWidget.qml').write_text(widget_source.replace('import Quickshell\n', '').replace('barWindow: root.QsWindow.window', 'barWindow: null'))
    (base / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\nsingleton Settings 1.0 Settings.qml\nsingleton Monitoring 1.0 Monitoring.qml\nsingleton BarLayout 1.0 BarLayout.qml\n')
    (base / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property bool verticalBar: false
 property int fontSize: 14
 property string fontFamily: "JetBrainsMono Nerd Font"
 property string barFontFamily: fontFamily
 property color bg: "#191724"
 property color text: "#e0def4"
 property color subtle: "#908caa"
 property color love: "#eb6f92"
 property color surface: "#1f1d2e"
 property color overlay: "#26233a"
 property color iris: "#c4a7e7"
 property color highlightMed: "#403d52"
}
''')
    (base / 'config/Settings.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property int barHeight: 42; property int widgetSpacing: 12; property int statsInterval: 2000 }\n')
    (base / 'config/BarLayout.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property bool ready: true; property bool monitoringEnabled: true; function isEnabled(id) { return monitoringEnabled; } }\n')
    (base / 'config/Monitoring.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property bool ready: true
 property var modes: ({"cpu.load":"long", "ram.usage":"long"})
 property string cpuSensor: ""
 property string errorMessage: ""
 function mode(id) { return modes[id] || "off"; }
 function setMode(id, mode) { const next = Object.assign({},modes); next[id] = mode; modes = next; }
 function setCpuSensor(value) { cpuSensor = value; }
}
''')
    (base / 'services/qmldir').write_text('singleton SystemStats 1.0 SystemStats.qml\n')
    # Keep production presentation functions, but avoid native processes in UI tests.
    production = (ROOT / 'services/SystemStats.qml').read_text()
    functions = production[production.index('    function metric('):production.index('    function accept(')]
    (base / 'services/SystemStats.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property int panels: 0
 property int launches: 0
 property string errorMessage: ""
 property string launchError: ""
 property var temperatureSources: [{id:"cpu-sensor",label:"CPU package",value:62}]
 property var metrics: [
  {id:"cpu.load",label:"CPU load",unit:"%",value:35,maximum:100,available:true},
  {id:"ram.usage",label:"RAM",unit:"B",value:17179869184,total:68719476736,maximum:68719476736,available:true},
  {id:"cpu.temperature",label:"CPU temperature",unit:"°C",value:62,maximum:100,available:true},
  {id:"cpu.power",label:"CPU package power",unit:"W",value:null,available:false,reason:"Permission restricted"},
  {id:"gpu.test.load",label:"RTX 4090 · load",unit:"%",value:40,maximum:100,available:true},
  {id:"gpu.test.temperature",label:"RTX 4090 · temperature",unit:"°C",value:43,maximum:100,available:true},
  {id:"gpu.test.power",label:"RTX 4090 · power",unit:"W",value:125,maximum:450,available:true}
 ]
 property var history: ({})
 function openBtop() { launches++; }
''' + functions + '\n}\n')
    (base / 'components/DropdownWidget.qml').write_text('''import QtQuick
Item {
 id: root
 property var barWindow: null
 property int popupWidth: 200
 property bool sizeToContent: false
 property bool showStem: true
 property bool rightClickEnabled: false
 property bool dropdownOpen: false
 property Component popupContent
 default property alias iconContent: content.data
 signal rightClicked
 Item { id: content; anchors.fill: parent }
 MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: mouse => { if (mouse.button === Qt.RightButton) root.rightClicked(); else root.dropdownOpen = !root.dropdownOpen; }
 }
}
''')
    shutil.copyfile(ROOT / 'tests/monitoring/tst_controls.qml', base / 'tst_controls.qml')
    install_design(base)
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               XDG_RUNTIME_DIR=str(base / 'runtime'), XDG_STATE_HOME=str(base / 'state'), XDG_CACHE_HOME=str(base / 'cache'))
    subprocess.run(['/usr/lib/qt6/bin/qmltestrunner','-input',str(base)],env=env,check=True)
    # Real singleton + worker protocol, with an isolated deterministic collector.
    shutil.copyfile(ROOT / 'services/SystemStats.qml', base / 'services/SystemStats.qml')
    shutil.copyfile(ROOT / 'config/Monitoring.qml', base / 'config/Monitoring.qml')
    (base / 'scripts/monitoring.py').write_text('''import json,time
while True:
 print(json.dumps(dict(timestamp=time.time()*1000,metrics=[dict(id="cpu.load",label="CPU load",unit="%",value=42,maximum=100,available=True),dict(id="ram.usage",label="RAM",unit="B",value=50,total=100,maximum=100,available=True)],temperatureSources=[])),flush=True)
 time.sleep(.1)
''')
    (base / 'scripts/monitoring-terminal.py').write_text('import json\nprint(json.dumps({"error":"test launch response"}))\n')
    (base / 'shell.qml').write_text('''import QtQuick
import Quickshell
import "config"
import "services"
ShellRoot {
 property int elapsed: 0
 property bool started: false
 function fail(message) { console.error("MONITORING_FAILED: " + message); Qt.quit(); }
 Timer {
  interval: 50; running: true; repeat: true
  onTriggered: {
   elapsed += 50;
   if (elapsed > 7000) { fail("timeout " + SystemStats.errorMessage); return; }
   if (!Monitoring.ready || !SystemStats.metrics.length) return;
   const phase = Quickshell.env("QS_MONITOR_PHASE");
   if (!started) {
    started = true;
    if (SystemStats.cpuUsage !== 42 || SystemStats.memUsage !== 50) { fail("legacy values"); return; }
    if (phase === "write") {
     Monitoring.setMode("cpu.load","short"); Monitoring.setMode("gpu.missing.power","long"); Monitoring.setCpuSensor("saved-sensor");
     SystemStats.openBtop();
     const now = Date.now();
     for (let i=0; i<400; ++i) SystemStats.accept({timestamp:now-800000+i*2000, metrics:[{id:"cpu.load",unit:"%",available:i%10!==0,value:i%10===0?null:42}],temperatureSources:[]});
     const points=SystemStats.history["cpu.load"];
     if (points.length > 301 || points[0].time < now-602000 || !points.some(p=>p.value===null)) { fail("history bounds or missing gaps"); return; }
    } else if (phase === "read") {
     if (Monitoring.mode("cpu.load")!=="short" || Monitoring.mode("gpu.missing.power")!=="long" || Monitoring.cpuSensor!=="saved-sensor") { fail("persistence"); return; }
    } else if (phase === "corrupt") {
     if (!Monitoring.errorMessage || Monitoring.mode("cpu.load")!=="long") { fail("corrupt fallback"); return; }
     Monitoring.setMode("cpu.load","short");
    } else if (phase === "failure") { Monitoring.setMode("cpu.load","short"); }
   }
   if (elapsed < 1200) return;
   if (phase === "write" && SystemStats.launchError!=="test launch response") { fail("launch response"); return; }
   if (phase === "failure" && !Monitoring.errorMessage.includes("could not save")) { fail("write failure"); return; }
   if (phase !== "failure" && Monitoring.errorMessage) { fail(Monitoring.errorMessage); return; }
   console.log("MONITORING_OK: " + phase); Qt.quit();
  }
 }
}
''')
    def phase(name):
        result = subprocess.run(['quickshell','--path',str(base)], env=dict(env,QS_MONITOR_PHASE=name),
                                stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=12)
        assert 'MONITORING_OK: ' + name in result.stdout and 'MONITORING_FAILED' not in result.stdout, result.stdout
        for error in ['ReferenceError','TypeError','Binding loop','Failed to load configuration','Unable to assign','Cannot assign']:
            assert error not in result.stdout, result.stdout
        print('PASS: monitoring native worker / ' + name, flush=True)
    phase('write')
    phase('read')
    saved, = (base / 'state').rglob('monitoring.json')
    saved.write_text('{invalid')
    phase('corrupt')
    saved.unlink()
    saved.mkdir()
    phase('failure')
    # Exercise the production DropdownWidget and native popup lifecycle too.
    for name in ['DropdownWidget.qml','PopupReveal.qml','PopupPlacement.js','BarHoverIndicator.qml']:
        shutil.copyfile(ROOT / 'components' / name, base / 'components' / name)
    (base / 'modules/bar/widgets/MonitoringWidget.qml').write_text(widget_source)
    theme = (base / 'config/Theme.qml').read_text().replace(' property bool verticalBar: false', ' property string barPosition: "top"\n property int sideBarWidth: 64\n property bool verticalBar: barPosition === "left" || barPosition === "right"')
    (base / 'config/Theme.qml').write_text(theme)
    config = (base / 'config/Settings.qml').read_text().replace('property int barHeight:', 'property int popupPadding: 12; property int barHeight:')
    (base / 'config/Settings.qml').write_text(config)
    saved.rmdir()
    (base / 'shell.qml').write_text('''import QtQuick
import Quickshell
import "config"
import "services"
import "modules/bar/widgets"
ShellRoot {
 property int step: 0
 FloatingWindow {
  id: window
  signal closeAllPopups
  visible: true
  implicitWidth: 700; implicitHeight: 180
  color: Theme.bg
  MonitoringWidget { id: widget; x:20; y:20; focusGrabEnabled: false }
 }
 Timer {
  interval: 350; running:true; repeat:true
  onTriggered: {
   if (!Monitoring.ready || SystemStats.metrics.length < 2) return;
   step++;
   if (step===1) widget.dropdownOpen=true;
   if (step===2) {
    if (!widget.dropdownOpen || widget.width < 80) { console.error("MONITORING_FAILED native open"); Qt.quit(); }
    window.closeAllPopups();
   }
   if (step===3) { Theme.barPosition="left"; widget.dropdownOpen=true; }
   if (step===4) {
    if (!widget.dropdownOpen || widget.width>64 || widget.height<90) { console.error("MONITORING_FAILED vertical"); Qt.quit(); }
    widget.dropdownOpen=false; Theme.barPosition="bottom";
   }
   if (step===5) widget.dropdownOpen=true;
   if (step===6) {
    if (!widget.dropdownOpen || widget.width<80) { console.error("MONITORING_FAILED reopen"); Qt.quit(); }
    widget.dropdownOpen=false; Theme.barPosition="right";
   }
   if (step===7) { widget.dropdownOpen=true; Theme.fontSize=28; }
   if (step===8) {
    if (!widget.dropdownOpen || widget.width>64) { console.error("MONITORING_FAILED right edge"); Qt.quit(); }
    console.log("MONITORING_OK: native popup"); Qt.quit();
   }
  }
 }
}
''')
    phase('native popup')
