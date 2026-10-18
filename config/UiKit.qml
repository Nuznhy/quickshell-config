pragma Singleton
import QtQuick
import qs.kits as KitScripts
import qs.config as ConfigScripts
import qs.kits.default as Default
import qs.kits.minimal as Minimal
import qs.kits.rounded as Rounded
import qs.kits.windows7 as Windows7
import qs.kits.windowsxp as WindowsXP

QtObject {
    id: root
    // Gallery and tests only. Never writes to Theme or saves preferences.
    property string previewKit: ""
    readonly property var kits: KitScripts.Registry.kits
    readonly property string activeId: KitScripts.Registry.normalize(previewKit || Theme.uiKit)
    readonly property QtObject defaultKit: Default.Kit {}
    readonly property QtObject minimalKit: Minimal.Kit {}
    readonly property QtObject roundedKit: Rounded.Kit {}
    readonly property QtObject windows7Kit: Windows7.Kit {}
    readonly property QtObject windowsxpKit: WindowsXP.Kit {}
    readonly property var definitions: ({
            default: defaultKit,
            minimal: minimalKit,
            rounded: roundedKit,
            windows7: windows7Kit,
            windowsxp: windowsxpKit
        })
    readonly property QtObject active: definitions[activeId] || defaultKit
    readonly property var tokens: Object.assign({}, defaultKit.baseTokens, active.tokens)
    function iconSource(name, pixelSize) {
        const icon = active.icons[name] || defaultKit.icons[name];
        if (!icon)
            return "";
        if (typeof icon === "string")
            return icon;
        const sizes = Object.keys(icon).map(Number).filter(size => size > 0).sort((a, b) => a - b);
        const size = sizes.find(size => size >= pixelSize) || sizes[sizes.length - 1];
        return icon[size] || "";
    }
    function resolvePalette(base, mode, kitId) {
        const kit = kitId === undefined ? active : definitions[kitId] || defaultKit;
        const shared = kit.palette || {};
        const variant = (kit.palettes || {})[mode] || {};
        const result = {};
        for (const role of ConfigScripts.Palettes.roles) {
            result[role] = variant[role] !== undefined && variant[role] !== null ? variant[role] : shared[role] !== undefined && shared[role] !== null ? shared[role] : base[role];
        }
        return result;
    }
    function visual(slot) {
        return active[slot] || defaultKit[slot];
    }
}
