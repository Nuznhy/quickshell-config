.pragma library

// Shared semantic names keep kit artwork independent of the shell's icon font.
const glyphs = {
    "settings": "󰒓",
    "equalizer": "",
    "appearance": "󰏘",
    "keyboard": "󰌌",
    "mouse": "󰍽",
    "phone": "󰏲",
    "display": "󰍹",
    "display-mirror": "󰍺",
    "television": "󰟴",
    "bluetooth": "󰂯",
    "bluetooth-connected": "󰂱",
    "bluetooth-disabled": "󰂲",
    "volume-high": "󰕾",
    "volume-muted": "󰖁",
    "microphone": "󰍬",
    "microphone-muted": "󰍭",
    "headphones": "󰋋",
    "network-wired": "󰈀",
    "network-wireless": "󰤨",
    "network-wireless-medium": "󰤥",
    "network-wireless-low": "󰤟",
    "network-offline": "󰤭",
    "vpn": "󰦝",
    "notifications": "󰂚",
    "notifications-disabled": "󰂛",
    "media": "󰎆",
    "play": "󰐊",
    "pause": "󰏤",
    "previous": "󰒮",
    "next": "󰒭",
    "power": "󰐥",
    "lock": "󰌾",
    "sleep": "󰒲",
    "reboot": "󰜉",
    "refresh": "󰑐",
    "folder": "󰉋",
    "wallpaper": "󰥶",
    "download": "󰇚",
    "trash": "󰆴",
    "application": "󰏗",
    "system-monitor": "󰍛",
    "system-info": "󰋽",
    "power-options": "󰚥",
    "calculator": "󰃬",
    "mail": "󰇮",
    "terminal": "󰆍",
    "folder-open": "󰝰",
    "computer": "󰇅",
    "disk": "󰋊",
    "search": "󰍉",
    "memory": "󰾆",
    "brightness": "󰃠",
    "info": "󰋽",
    "help": "󰋗",
    "warning": "󰀦",
    "error": "󰅚"
};
const names = Object.assign({}, ...Object.keys(glyphs).map(name => ({[glyphs[name]]: name})), {
    "": "power"
});

function name(text) {
    return names[text] || "";
}

function glyph(name) {
    return glyphs[name] || "";
}
