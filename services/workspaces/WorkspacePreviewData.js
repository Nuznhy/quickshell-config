.pragma library

function windows(clients) {
    const result = {};
    const seen = new Set();
    for (const client of clients) {
        const ws = client.workspace?.id;
        const address = "0x" + String(client.address || "").replace(/^0x/i, "").toLowerCase();
        if (!(ws > 0) || client.mapped === false || client.hidden === true
                || !/^0x[0-9a-f]+$/.test(address) || seen.has(address)
                || !Array.isArray(client.at) || !Array.isArray(client.size)
                || ![...client.at, ...client.size].every(Number.isFinite)
                || client.at.length !== 2 || client.size.length !== 2
                || client.size[0] <= 0 || client.size[1] <= 0) continue;
        seen.add(address);
        if (!result[ws]) result[ws] = [];
        result[ws].push({address: address, x: client.at[0], y: client.at[1],
            width: client.size[0], height: client.size[1], monitor: client.monitor,
            title: client.title || client.class || "Window", appId: client.class || client.initialClass || "",
            floating: !!client.floating, fullscreen: Number(client.fullscreen) > 0,
            rank: client.focusHistoryID >= 0 ? client.focusHistoryID : 10000});
    }
    return result;
}

function bounds(monitor, screen) {
    const scale = monitor?.scale > 0 ? monitor.scale : 1;
    const rotated = (Number(monitor?.lastIpcObject?.transform) || 0) % 2 === 1;
    return {
        x: monitor?.x || 0, y: monitor?.y || 0,
        width: Math.max(1, screen?.width || (rotated ? monitor?.height : monitor?.width) / scale || 1920),
        height: Math.max(1, screen?.height || (rotated ? monitor?.width : monitor?.height) / scale || 1080)
    };
}

function project(window, bounds, width, height) {
    return {x: (window.x - bounds.x) * width / bounds.width,
        y: (window.y - bounds.y) * height / bounds.height,
        width: window.width * width / bounds.width, height: window.height * height / bounds.height};
}
