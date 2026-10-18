.pragma library

function luminance(color) {
    function linear(v) { return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b);
}
function contrast(a, b) {
    const x = luminance(a), y = luminance(b);
    return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
}
function foreground(base) {
    return luminance(base) > 0.179 ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1);
}
function shade(base, amount) {
    const channel = amount > 0 ? 1 : 0;
    const value = Qt.tint(base, Qt.rgba(channel, channel, channel, Math.abs(amount)));
    return Qt.rgba(value.r, value.g, value.b, base.a);
}
function legible(color, base) {
    const target = foreground(base);
    for (let step = 0; step <= 20; ++step) {
        const value = Qt.tint(color, Qt.rgba(target.r, target.g, target.b, step / 20));
        if (contrast(value, base) >= 4.5)
            return value;
    }
    return target;
}
function safeShade(base, amount, text) {
    // Preserve text contrast across every stop, including arbitrary wallpaper colors.
    const minimum = Math.min(4.5, contrast(base, text));
    for (let attempt = 0; attempt < 10; ++attempt) {
        const value = shade(base, amount);
        if (text.a === 0 || contrast(text, value) >= minimum)
            return value;
        amount *= 0.5;
    }
    return base;
}
