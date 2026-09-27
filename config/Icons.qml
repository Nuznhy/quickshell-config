pragma Singleton
import QtQuick
import Quickshell

QtObject {
    function resolveWindow(windowClass, initialClass) {
        const names = [...new Set([windowClass, initialClass].filter(name => !!name))];
        const apps = DesktopEntries.applications.values;
        const entries = [];

        for (const name of names) {
            const lower = name.toLowerCase().replace(/\.desktop$/, "");
            const entry = DesktopEntries.byId(name)
                || apps.find(app => app.id.toLowerCase() === lower
                    || app.startupClass.toLowerCase() === lower);
            if (entry && !entries.includes(entry)) entries.push(entry);
        }

        for (const name of names) {
            const entry = DesktopEntries.heuristicLookup(name);
            if (entry && !entries.includes(entry)) entries.push(entry);
        }

        const appId = entries[0]?.id || (initialClass || windowClass || "unknown").toLowerCase();

        const candidates = entries.map(entry => entry.icon)
            .concat(names, names.map(name => name.toLowerCase()));

        for (const name of candidates) {
            if (!name) continue;
            const source = Quickshell.iconPath(name, true);
            if (source) return { appId: appId, source: source };
        }

        const generic = Quickshell.iconPath("application-x-executable", true)
            || Quickshell.iconPath("application-default-icon", true);

        return { appId: appId, source: generic };
    }
}
