.pragma library

// Window addresses are identities; application IDs only choose icons/badges.
function build(clients, resolveIcon) {
    const icons = {};
    const resolved = new Map();
    const seen = new Set();
    for (const client of clients) {
        const wsId = client.workspace?.id;
        if (!(wsId > 0) || !client.address || client.mapped === false) continue;
        const address = "0x" + String(client.address).replace(/^0x/i, "").toLowerCase();
        if (!/^0x[0-9a-f]+$/.test(address) || seen.has(address)) continue;
        seen.add(address);
        const key = JSON.stringify([client.class, client.initialClass]);
        if (!resolved.has(key)) resolved.set(key, resolveIcon(client.class, client.initialClass));
        const icon = resolved.get(key);
        if (!icons[wsId]) icons[wsId] = [];
        icons[wsId].push({
            appId: icon.appId,
            source: icon.source,
            address: address,
            addresses: [address]
        });
    }
    return icons;
}
