.pragma library

// Keep the existing semantic roles so every widget follows the chosen palette.
var roles = ["bg", "surface", "overlay", "muted", "subtle", "text", "love", "gold", "rose", "pine", "foam", "iris", "highlightLow", "highlightMed", "highlightHigh"];
var presets = [
    { id: "rose-pine", name: "Rosé Pine", dark: ["#191724", "#1f1d2e", "#26233a", "#6e6a86", "#908caa", "#e0def4", "#eb6f92", "#f6c177", "#ebbcba", "#31748f", "#9ccfd8", "#c4a7e7", "#21202e", "#403d52", "#524f67"],
      light: ["#faf4ed", "#fffaf3", "#f2e9e1", "#9893a5", "#797593", "#575279", "#b4637a", "#a96d18", "#b87772", "#286983", "#427b8a", "#907aa9", "#f4ede8", "#dfdad9", "#cecacd"] },
    { id: "catppuccin", name: "Catppuccin", dark: ["#1e1e2e", "#181825", "#313244", "#6c7086", "#a6adc8", "#cdd6f4", "#f38ba8", "#f9e2af", "#f5c2e7", "#89b4fa", "#94e2d5", "#cba6f7", "#313244", "#45475a", "#585b70"],
      light: ["#eff1f5", "#e6e9ef", "#dce0e8", "#8c8fa1", "#6c6f85", "#4c4f69", "#d20f39", "#986800", "#b52ca0", "#1e66f5", "#167d8d", "#8839ef", "#dce0e8", "#ccd0da", "#bcc0cc"] },
    // Catalog sources and role mapping are documented in config/PALETTE_SOURCES.md.
    { id: "gruvbox", name: "Gruvbox", dark: ["#282828", "#3c3836", "#504945", "#665c54", "#bdae93", "#d5c4a1", "#fb4934", "#fabd2f", "#fe8019", "#83a598", "#8ec07c", "#d3869b", "#3c3836", "#504945", "#665c54"],
      light: ["#fbf1c7", "#ebdbb2", "#d5c4a1", "#bdae93", "#665c54", "#504945", "#9d0006", "#b57614", "#af3a03", "#076678", "#427b58", "#8f3f71", "#ebdbb2", "#d5c4a1", "#bdae93"] },
    { id: "solarized", name: "Solarized", dark: ["#002b36", "#073642", "#586e75", "#657b83", "#839496", "#93a1a1", "#dc322f", "#b58900", "#cb4b16", "#268bd2", "#2aa198", "#6c71c4", "#073642", "#586e75", "#657b83"],
      light: ["#fdf6e3", "#eee8d5", "#93a1a1", "#839496", "#657b83", "#586e75", "#dc322f", "#b58900", "#cb4b16", "#268bd2", "#2aa198", "#6c71c4", "#eee8d5", "#93a1a1", "#839496"] },
    { id: "everforest", name: "Everforest", dark: ["#2d353b", "#343f44", "#3d484d", "#7a8478", "#9da9a0", "#d3c6aa", "#e67e80", "#dbbc7f", "#e69875", "#7fbbb3", "#83c092", "#d699b6", "#343f44", "#475258", "#4f585e"],
      light: ["#fdf6e3", "#f4f0d9", "#efebd4", "#a6b0a0", "#829181", "#5c6a72", "#f85552", "#dfa000", "#f57d26", "#3a94c5", "#35a77c", "#df69ba", "#f4f0d9", "#e6e2cc", "#e0dcc7"] },
    { id: "neutral", name: "Neutral", dark: ["#18181b", "#202024", "#2c2c32", "#71717a", "#a1a1aa", "#f4f4f5", "#a5b4fc", "#fcd34d", "#fda4af", "#60a5fa", "#5eead4", "#c4b5fd", "#27272a", "#3f3f46", "#52525b"],
      light: ["#fafafa", "#ffffff", "#f0f0f2", "#71717a", "#52525b", "#27272a", "#4f46e5", "#946200", "#be123c", "#2563eb", "#0f766e", "#7c3aed", "#f4f4f5", "#e4e4e7", "#d4d4d8"] }
];

function hasPreset(id) {
    return presets.some(function(p) { return p.id === id; });
}

function palette(id, mode) {
    var preset = presets.find(function(p) { return p.id === id; }) || presets[0];
    var values = mode === "light" ? preset.light : preset.dark;
    var result = {};
    roles.forEach(function(role, i) { result[role] = values[i]; });
    return result;
}
