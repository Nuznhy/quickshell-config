pragma Singleton
import QtQuick

QtObject {
    property var windowIcons: ({
            // Browsers
            "firefox": "",
            "org.mozilla.firefox": "",
            "librewolf": "",
            "floorp": "",
            "cachy-browser": "",
            "zen": "󰰷",
            "zen-browser": "󰰷",
            "zen-alpha": "󰰷",
            "microsoft-edge": "",
            "chromium": "",
            "google-chrome": "",
            "brave-browser": "󰖟",
            "vivaldi": "",

            // Terminals
            "kitty": "󰞷",
            "konsole": "󰞷",
            "alacritty": "󰞷",
            "com.mitchellh.ghostty": "󰊠",
            "ghostty": "󰊠",
            "org.wezfurlong.wezterm": "󰞷",
            "foot": "󰞷",
            "xterm": "󰞷",
            "urxvt": "󰞷",

            // Communication
            "telegram-desktop": "",
            "org.telegram.desktop": "",
            "discord": "󰙯",
            "webcord": "󰙯",
            "vesktop": "󰙯",
            "slack": "󰒱",
            "Slack": "󰒱",
            "whatsapp": "󰖣",
            "wasistlos": "󰖣",
            "zapzap": "󰖣",
            "thunderbird": "󰇮",
            "teamspeak": "",

            // Code editors
            "code": "󰨞",
            "code-oss": "󰨞",
            "vscodium": "󰨞",
            "codium": "󰨞",
            "dev.zed.zed": "󰵁",
            "zed": "󰵁",
            "subl": "󰅳",
            "sublime_text": "󰅳",
            "jetbrains-idea": "",
            "neovide": "",

            // Media
            "mpv": "",
            "vlc": "󰕼",
            "spotify": "",
            "cider": "󰎆",
            "celluloid": "",

            // File managers
            "thunar": "󰝰",
            "nemo": "󰝰",
            "nautilus": "󰝰",
            "dolphin": "󰝰",
            "pcmanfm": "󰝰",

            // System
            "pavucontrol": "󱡫",
            "org.pulseaudio.pavucontrol": "󱡫",
            "nwg-look": "",
            "steam": "",
            "obs": "",
            "com.obsproject.studio": "",
            "gimp": "",
            "virt-manager": "",

            // Office
            "libreoffice-writer": "",
            "libreoffice-calc": "",
            "libreoffice-startcenter": "󰏆",

            // Claude Code / AI
            "claude": "󰚩"
        })

    function getIcon(className) {
        return windowIcons[className.toLowerCase()] || "󰣆"; // Fallback to a default icon
    }

    function getWindowIcon(windowClass) {
        if (!windowClass)
            return "";
        if (windowIcons[windowClass])
            return windowIcons[windowClass];
        var lowerClass = windowClass.toLowerCase();
        if (windowIcons[lowerClass])
            return windowIcons[lowerClass];
        for (var key in windowIcons) {
            var lowerKey = key.toLowerCase();
            if (lowerClass.includes(lowerKey) || lowerKey.includes(lowerClass)) {
                return windowIcons[key];
            }
        }
        return "󰏗"; // default window icon
    }
}
