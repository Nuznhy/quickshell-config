pragma Singleton
import QtQuick
import qs.kits as KitScripts
import qs.config as ConfigScripts
import qs.kits.default as Default
import qs.kits.minimal as Minimal
import qs.kits.rounded as Rounded
import qs.kits.windows7 as Windows7

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
    readonly property var definitions: ({
            default: defaultKit,
            minimal: minimalKit,
            rounded: roundedKit,
            windows7: windows7Kit
        })
    readonly property QtObject active: definitions[activeId] || defaultKit
    readonly property var tokens: Object.assign({}, defaultKit.baseTokens, active.tokens)
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
