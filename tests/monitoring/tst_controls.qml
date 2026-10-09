import QtQuick
import QtTest
import "config"
import "services"
import "components"
import "modules/bar/widgets"
Rectangle {
    width: 900; height: 760
    color: Theme.bg
    MonitoringSettings { id: settings; x: 20; y: 20; width: 600 }
    MonitoringCenter { id: center; x: 20; y: 80; width: 580; height: implicitHeight; visible: false }
    MonitoringWidget { id: widget; x: 20; y: 20; visible: false }
    TestCase {
        name: "MonitoringControls"
        when: windowShown
        function init() {
            settings.visible = true; settings.active = false;
            center.visible = false; widget.visible = false;
            Theme.verticalBar = false;
            Monitoring.modes = {"cpu.load":"long","ram.usage":"long"};
            Monitoring.cpuSensor = "";
            wait(30);
        }
        function test_per_metric_modes() {
            mouseClick(findChild(settings,"monitoring-cpu.load-short"));
            compare(Monitoring.mode("cpu.load"),"short");
            compare(Monitoring.mode("ram.usage"),"long");
            mouseClick(findChild(settings,"monitoring-cpu.load-off"));
            compare(Monitoring.mode("cpu.load"),"off");
            mouseClick(findChild(settings,"monitoring-cpu.power-long"));
            compare(Monitoring.mode("cpu.power"),"long");
        }
        function test_settings_lifecycle_and_sensor() {
            settings.active = true; compare(SystemStats.panels, 1);
            settings.active = false; compare(SystemStats.panels, 0);
            Monitoring.cpuSensor = "missing";
            const combo = findChild(settings,"monitoring-temperature-source");
            tryCompare(combo,"currentIndex",2);
            compare(combo.wheelEnabled,false);
            grabImage(settings.parent).save("/tmp/quickshell-monitoring-settings.png");
        }
        function test_horizontal_vertical_and_clicks() {
            settings.visible=false; widget.visible=true;
            const initial = widget.width;
            verify(initial > 90);
            mouseClick(widget,10,10,Qt.RightButton);
            compare(SystemStats.launches,1);
            verify(!widget.dropdownOpen);
            mouseClick(widget,10,10,Qt.LeftButton);
            verify(widget.dropdownOpen);
            Monitoring.setMode("cpu.load","short"); wait(30);
            verify(widget.width < initial);
            Theme.verticalBar=true; wait(30);
            verify(widget.width <= 64);
            verify(widget.height > 80);
            Theme.verticalBar=false; wait(30);
            verify(widget.width > 90);
            Theme.verticalBar=true; wait(30);
            verify(widget.width <= 64);
            grabImage(widget.parent).save("/tmp/quickshell-monitoring-vertical.png");
        }
        function test_no_metrics_keeps_trigger() {
            Monitoring.modes={}; settings.visible=false; widget.visible=true; wait(30);
            verify(widget.width > 0); verify(widget.height >= 42);
        }
        function test_sensor_membership_changes() {
            const original = SystemStats.metrics;
            SystemStats.metrics = original.concat([{id: "gpu.hotplug.load", label: "GPU", unit: "%", value: 10, maximum: 100, available: true}]);
            Monitoring.setMode("gpu.hotplug.load", "long");
            wait(30);
            verify(findChild(center, "monitoring-graph-gpu.hotplug.load") !== null);
            verify(findChild(widget, "monitoring-cell-gpu.hotplug.load") !== null);
            SystemStats.metrics = original;
            wait(30);
            compare(findChild(center, "monitoring-graph-gpu.hotplug.load"), null);
            compare(findChild(widget, "monitoring-cell-gpu.hotplug.load"), null);
        }
        function test_samples_preserve_cards_and_bar_cells() {
            settings.visible = false; center.visible = true; widget.visible = true;
            wait(30);
            const card = findChild(center, "monitoring-graph-cpu.load");
            const cell = findChild(widget, "monitoring-cell-cpu.load");
            verify(card !== null); verify(cell !== null);
            const height = center.implicitHeight;
            for (let sample = 0; sample < 3; sample++) {
                SystemStats.metrics = SystemStats.metrics.map(entry =>
                    entry.id === "cpu.load" ? Object.assign({}, entry, {value: 51 + sample}) : entry);
                SystemStats.history = {"cpu.load": [{time: Date.now(), value: 51 + sample}]};
                wait(30);
                compare(findChild(center, "monitoring-graph-cpu.load"), card);
                compare(findChild(widget, "monitoring-cell-cpu.load"), cell);
                compare(card.metric.value, 51 + sample);
                compare(cell.metric.value, 51 + sample);
                compare(center.implicitHeight, height);
            }
        }
        function test_graphs_include_non_bar_metrics() {
            settings.visible=false; center.visible=true;
            const history={}, now=Date.now();
            for (const entry of SystemStats.metrics) {
                if (!entry.available) continue;
                const samples=[];
                for(let i=0;i<301;i++) samples.push({time:now-600000+i*2000,value:i>120 && i<130?null:(entry.maximum||100)*(0.25+0.2*Math.sin(i/9))});
                history[entry.id]=samples;
            }
            SystemStats.history=history;
            wait(100);
            verify(findChild(center, "monitoring-graph-cpu.power") !== null);
            verify(center.implicitHeight > 300);
            grabImage(center.parent).save("/tmp/quickshell-monitoring-graphs.png");
            center.width=320; wait(30);
            compare(center.width,320);
            center.width=580;
        }
    }
}
