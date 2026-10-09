.pragma library

function defaults() {
    return {lines: "animated", background: "off", duration: 300, strength: 12};
}

function normalize(value) {
    const result = defaults();
    if (!value || typeof value !== "object" || Array.isArray(value)) return result;
    for (const key of ["lines", "background"])
        if (["off", "instant", "animated"].includes(value[key])) result[key] = value[key];
    if (typeof value.duration === "number" && Number.isFinite(value.duration) && value.duration >= 100 && value.duration <= 600)
        result.duration = Math.round(value.duration / 20) * 20;
    if (typeof value.strength === "number" && Number.isFinite(value.strength) && value.strength >= 0 && value.strength <= 30)
        result.strength = Math.round(value.strength);
    return result;
}
