.pragma library

function defaults() {
    return {version: 1, showIcons: true, iconStyle: "app", separator: "·", capsule: false};
}
function cleanSeparator(value) {
    // QML's string iterator can split supplementary Nerd Font glyphs.
    const characters = value.replace(/[\r\n\t]/g, " ").match(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[\s\S]/g) || [];
    return characters.slice(0, 8).join("");
}
function normalize(saved) {
    if (!saved || saved.version !== 1 || typeof saved !== "object" || Array.isArray(saved))
        throw new Error("Invalid workspace appearance settings");
    const result = defaults();
    if (typeof saved.showIcons === "boolean") result.showIcons = saved.showIcons;
    if (["app", "nerd"].includes(saved.iconStyle)) result.iconStyle = saved.iconStyle;
    if (typeof saved.separator === "string") result.separator = cleanSeparator(saved.separator);
    if (typeof saved.capsule === "boolean") result.capsule = saved.capsule;
    return result;
}
