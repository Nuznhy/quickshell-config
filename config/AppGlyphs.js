.pragma library

// Match desktop IDs as well as window classes; unknown apps retain a generic icon.
function resolve(appId) {
    const name = String(appId || "").toLowerCase();
    const mappings = [
        [/firefox|librewolf|floorp/, ""],
        [/zen[-.]?browser|app\.zen_browser/, "󰖟"],
        [/chrom(e|ium)|brave|vivaldi|microsoft.edge/, ""],
        [/ghostty|kitty|alacritty|wezterm|foot|konsole|terminal|xterm/, ""],
        [/telegram/, ""],
        [/discord|vesktop|equibop/, ""],
        [/signal/, "󰭹"],
        [/slack/, ""],
        [/codex/, "󰚩"],
        [/code|cursor|zed|sublime/, "󰨞"],
        [/neovim|nvim|gvim/, ""],
        [/spotify/, ""],
        [/steam/, ""],
        [/dolphin|nautilus|thunar|nemo|pcmanfm|yazi/, "󰉋"],
        [/obsidian/, "󱞁"],
        [/obs(studio)?($|[._-])/, "󰑋"],
        [/mpv|vlc/, "󰕼"],
        [/btop|htop/, "󰍛"]
    ];
    const match = mappings.find(entry => entry[0].test(name));
    return match ? match[1] : "󰏗";
}
