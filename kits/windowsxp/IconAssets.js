.pragma library

// URLs resolve beside this kit, including in isolated gallery/test fixtures.
function sources() {
    const icons = {};
    const sizes = {
        "settings": [16, 32, 48],
        "volume-high": [16, 32, 48],
        "volume-muted": [16, 32, 48],
        "lock": [16, 24, 32, 48],
        "equalizer": [16, 32, 48],
        "power-options": [16, 32, 48],
        "system-info": [16, 32, 48],
        "keyboard": [16, 32, 48],
        "mouse": [16, 32, 48],
        "display": [16, 32, 48],
        "phone": [16, 32, 48],
        "bluetooth": [16, 32, 48],
        "info": [16, 32, 48],
        "power": [16, 24, 32, 48],
        "help": [16, 24, 32, 48],
        "warning": [16, 32, 48],
        "error": [16, 32, 48],
        "notifications": [16, 32, 48],
        "notifications-disabled": [16, 32, 48],
        "media": [16, 32, 48],
        "calculator": [16, 32, 48],
        "mail": [16, 32, 48],
        "network-wired": [16, 32, 48],
        "network-wireless": [16, 32, 48],
        "display-mirror": [16, 32, 48],
        "refresh": [16, 32, 48],
        "appearance": [16, 32, 48],
        "system-monitor": [16, 32, 48],
        "terminal": [16, 32, 48],
        "download": [16, 32, 48],
        "folder": [16, 24, 32, 48],
        "folder-open": [16, 32, 48],
        "trash": [16, 32, 48],
        "search": [16, 24, 32, 48],
        "computer": [16, 24, 32, 48],
        "disk": [16, 32, 48],
        "wallpaper": [16, 32],
    };
    for (const name of Object.keys(sizes)) {
        icons[name] = {};
        for (const size of sizes[name]) {
            icons[name][size] = Qt.resolvedUrl("icons/" + size + "/" + name + ".png").toString();
        }
    }
    return icons;
}
